---
title: "Highlighting search results with Textacular"
date: 2022-05-30 17:30 UTC
description: "Add highlighting to your Textacular seach results using Postgres's ts_headline."
---

It's possible to leverage Postgres's `ts_headline`[^1] to add highlighting of
matched fragments in search results. With a caveat, the search fields need to
be declared ahead of time.

To highlight a `basic_search` each column to be highlighted needs to be
`SELECT`-ed using `ts_headline` with the query string parsed with
`plainto_tsquery`.

```ruby
class Post < ApplicationRecord
  def self.search(query)
    basic_search(title: query)
      .select("#{sanitize_sql_array(["ts_headline(title, plainto_tsquery(?))", query])} as title_highlighted")
  end
end
```

Using this blog's post titles for testing we see:

```
[0] pry(main)> Post.search("server Rack").map(&:attributes)
  Post Load (3.1ms)  SELECT "posts".*, COALESCE(ts_rank(to_tsvector('english', "posts"."title"::text), plainto_tsquery('english', 'server\ Rack'::text)), 0) AS "rank35483819984107261", ts_headline(title, plainto_tsquery('server Rack')) as title_highlighted FROM "posts" WHERE (to_tsvector('english', "posts"."title"::text) @@ plainto_tsquery('english', 'server\ Rack'::text)) ORDER BY "rank35483819984107261" DESC
=> [{"id"=>4,
  "title"=>"Server-sent events with Rails and Rack hijack",
  "created_at"=>Mon, 30 May 2022 17:30:29.806047000 UTC +00:00,
  "updated_at"=>Mon, 30 May 2022 17:30:29.806047000 UTC +00:00,
  "rank35483819984107261"=>0.085297264,
  "title_highlighted"=>"<b>Server</b>-sent events with Rails and <b>Rack</b> hijack"}]
```

To work for an `advanced_search` the query string should be passed to
`to_tsquery` and `web_search` to `websearch_to_tsquery`.

[^1]: https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-HEADLINE
