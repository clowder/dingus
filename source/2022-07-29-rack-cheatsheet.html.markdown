---
title: Rack Cheatsheet
date: 2022-07-29 12:00 UTC
description: "A one-page guide to getting start with Rack."
---

## Rack interface

### Middleware

Middleware is the atom of Rack Land. It' has a very simple interface! It's
`#initialize` _must_ accept a single argument, this is the _next_ middleware in
the stack. The current middleware _should_ send `#call` to this middleware in
it's own `#call` method.

Middleware _must_ also respond to `#call`, which _must_ accept a single
argument and _must_ return the "magic triple". The argument passed is the Rack
"environment hash", it contains information about the HTTP request and
Rack-specific variables[^1]. The magic triple is broken down below.

```ruby
[
  200,                              # HTTP Status Code, must be an `Integer`
  {"Content-Type" => "text/plain"}, # Headers, must be a `Hash`, but can be empty
  ["Hello world."]                  # Body, must respond to `#each`
]
```

### Applications

Applications are just a special case middleware. Because they're at the bottom
of the stack they _do not_ need to implement `#initalize`, they _must_ respond
to `#call`.

## Rack-up DSL

The entry point to Rack! Normally added to a `config.ru` file and booted
with a sever with a Rack handler build in (like [Puma][2]).

### Running an application

_Using a proc:_

```ruby
run proc {
  [200, {"Content-Type" => "text/plain"}, ["Hello world."]]
}
```

_Using a class:_

```ruby
class HelloWorld
  def call(_env)
    [200, {"Content-Type" => "text/plain"}, ["Hello world."]]
  end
end

run HelloWorld.new
```

### Adding middleware

_Without configuration_

```ruby
use Rack::ShowExceptions
```

_With configuration_

```ruby
use Rack::Auth::Basic, "Rack Cheatsheet" do |username, password|
  OpenSSL.secure_compare('secret', password)
end
```

### Two applications, one `config.ru`

```ruby
APP_1 = proc {
  [301, {"Location" => "/hello-world"}, []]
}

APP_2 = proc {
  [200, {"Content-Type" => "text/plain"}, ["Hello world."]]
}

map "/hello-world" do
  run APP_2
end

run APP_1
```

### Warming up applications on boot

```ruby
warmup do |app|
  client = Rack::MockRequest.new(app)
  client.get('/warm-cache')
end
```

## Request handing

Using the environment hash directly can be a little unwieldy, `Rack::Request`
is a helpful wrapper to make it more ergonomic.

```ruby
run lambda { |env|
  request = Rack::Request.new(env)

  unless request.scheme == 'https'
    return [301, {"Location" => "https://#{request.host}#{request.fullpath}"}, []]
  end

  if request.get?
    [200, {"Content-Type" => "text/plain"}, ["Secure hello world."]]
  else
    [405, {}, []]
  end
}
```

## The response object

A convenience class for generating responses, calling `#to_a` or `#finish` will
return a magic triple.

```ruby
run lambda { |_env|
  response = Rack::Response.new

  response.write "<p>"

  case Time.now.hour
  when 0..11
    response.write "Good morning!"
  when 12..17
    response.write "Good afternoon!"
  when 18..23
    response.write "Good evening!"
  end

  response.write " <time>It's #{Time.now.strftime("%l:%M %P")}</time>.</p>"

  response.finish
}
```

[^1]: https://github.com/rack/rack/blob/0ba88559cd15ffc2b7a0fed7a05d62622349ea6f/SPEC.rdoc#label-The+Environment

[1]: https://github.com/rack/rack
[2]: https://puma.io
