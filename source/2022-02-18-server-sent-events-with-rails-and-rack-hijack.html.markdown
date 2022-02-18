---
title: Server-sent events with Rails and Rack hijack
date: 2022-02-18 12:38 UTC
---

Server-sent events[^1] (SSE) are a simple way to push data to clients over
plain-old HTTP and rails has also provided a tidy DLS for SSE (via
`[ActionController::Live]`) since Rails 4.

Unfortunately long-running HTTP connections in Rails controllers tie-up server
threads, causing incoming requests to queue. Borrowing from Action Cable it's
possible to move these long running connections to their own threads and put
those server threads back to work serving incoming requests.

The secret sauce is Rack "hijack"[^2] which let's us take control of the actual
`[TCPSocket]` backing the incoming request. When combined with the myriad
concurrency primitives in modern Rails apps (via [concurrent-ruby][1]) it's
possible to handle as many open connections as system RAM and `ulimit` will
allow.


```ruby
class ApplicationController < ActionController::API
  def stream
    # Get the `[TCPSocket]` instance backing the request
    io = request.env["rack.hijack"].call

    # Send HTTP response line and relevant headers
    io.write(
      "HTTP/1.1 200\r\n" \
      "Content-Type: text/event-stream\r\n" \
      "Cache-Control: no-cache\r\n" \
      "\r\n"
    )

    # Periodically spawn a thread to send a keepalive
    keepalive = Concurrent::TimerTask.execute(execution_interval: 5) do
      io.write(":keepalive\n\n")
    end

    # Watch for and handle failed keepalives
    keepalive.add_observer do |_time, _result, ex|
      break unless ex.present?

      if ex.is_a?(Errno::EPIPE)
        # We expect "broken pipe" errors if we've written to a closed socket
        logger.debug("Client disconnected")
      end

      # Stop the timer task spawning new threads
      keepalive.shutdown

      # Close the socket
      io.close

      # Dereference everything so it can be garbage collected
      io = keepalive = nil
    end
  end
end
```

Testing our new action with curl we see the following:

```shell
$> curl -v --no-buffer http://localhost:3000/
*   Trying ::1:3000...
* Connected to localhost (::1) port 3000 (#0)
> GET / HTTP/1.1
> Host: localhost:3000
> User-Agent: curl/7.77.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200
< Content-Type: text/event-stream
< Cache-Control: no-cache
* no chunk, no close, no size. Assume close to signal end
<
:keepalive

:keepalive
```

By "hijacking" the socket and passing it to a separate thread of sending data
it's possible to hold open as many connections as `ulimit` or system memory
will allow, event on a single threaded server, while also still serving regular
requests.

Reusing the configured Action Cable pub/sub adapter, available through the
global `ActionCable.server.pubsub`, it's possible to subscribe to and deliver
events to clients in near realtime.

```ruby
class ApplicationController < ActionController::API
  def stream
    # Get the `[TCPSocket]` instance backing the request
    io = request.env["rack.hijack"].call

    # Handler for new broadcasts
    on_message = ->(data) { io.write("data: #{data}\n\n") }

    # Send HTTP response line and relevant headers
    io.write(
      "HTTP/1.1 200\r\n" \
      "Content-Type: text/event-stream\r\n" \
      "Cache-Control: no-cache\r\n" \
      "\r\n"
    )

    # Subscribe to the "/sse/test" channel
    ActionCable.server.pubsub.subscribe("/sse/test", on_message)

    # Periodically spawn a thread to send a keepalive
    keepalive = Concurrent::TimerTask.execute(execution_interval: 5) do
      io.write(":keepalive\n\n")
    end

    # Watch for and handle failed keepalives
    keepalive.add_observer do |_time, _result, ex|
      break unless ex.present?

      if ex.is_a?(Errno::EPIPE)
        # We expect "broken pipe" errors if we've written to a closed socket
        logger.debug("Client disconnected")
      end

      # Unsubscribe from the "/sse/test" channel
      ActionCable.server.pubsub.unsubscribe("/sse/test", on_message)

      # Stop the timer task spawning new threads
      keepalive.shutdown

      # Close the socket
      io.close

      # Dereference everything so it can be garbage collected
      io = keepalive = on_message = nil
    end
  end
end
```

Broadcasting from the Rails console:

```shell
$> bin/rails c
Loading development environment (Rails 7.0.2)
irb(main):001:0> ActionCable.server.pubsub.broadcast("/sse/test", {"foo" => "bar"}.to_json)
=> 1
```

In curl we see the following:

```shell
$> curl -v --no-buffer http://localhost:3000/
*   Trying ::1:3000...
* Connected to localhost (::1) port 3000 (#0)
> GET / HTTP/1.1
> Host: localhost:3000
> User-Agent: curl/7.77.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200
< Content-Type: text/event-stream
< Cache-Control: no-cache
* no chunk, no close, no size. Assume close to signal end
<
:keepalive

:keepalive

data: {"foo":"bar"}

:keepalive
```

<span class="text-7xl cursor-help" title="You've got mail">📬</span>

[1]: https://github.com/ruby-concurrency/concurrent-ruby

[^1]: [Server-sent events living standard](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events)
[^2]: [Rack spec](https://github.com/rack/rack/blob/42aff22f708123839ba706cbe659d108b47c40c7/SPEC.rdoc)
