---
title: "Active Record `find_each` using Postges cursors"
date: 2022-03-18 13:26 UTC
description: "Implement a cursor based version of Rails's `find_each` for Postgres"
---

Active Record's [`find_each`][1] is the go-to method for loading a large number
of records in an efficient way. Under the hood it uses `OFFSET` and `LIMIT` to
load records in batches and `yield` them to our block. One drawback to this
approach is Rails requires records to be ordered by their primary key, despite
Postges only requiring the `ORDER` to be unique[^1].

Not ideal!

With Postgres it's possible to solve this problem using another tool called a
cursor. These can wrap _any_ query, ordered any way,  and make it possible to
fetch it's results incrementally[^2]. But unfortuantly Rails doesn't have
native support for Postgres cursors.

Spelunking Rails's issues on Github your author stumbled across
[rails/rails#28085][2], which contains a monkey patch impementing a variant of
`find_each` using cursors.

```ruby
module ActiveRecord
  module Batches
    # Implements `find_each` variant using cursors. Source:
    # https://github.com/rails/rails/issues/28085#issuecomment-457909168
    #
    # Our changes:
    # * `break` condition avoids extra iteration on small sets
    # * use Active Records safe string replacement in `find_by_sql`
    # * simplify cursor definition based on Postgres defaults (more inline)
    # * remove redundant references `self`
    def batched_each(count: 1000, &block)
      transaction do
        # Cursors are created `WITHOUT HOLD` by default and cannot be used
        # outside of the transaction that created them. `NO SCROLL` specifies
        # the cursor cannot be used to retrieve rows in a non-sequential
        # fashion.
        connection.execute("DECLARE pc NO SCROLL CURSOR FOR #{to_sql}")

        loop do
          result = find_by_sql(["FETCH FORWARD ? FROM pc", count], &block)
          break if result.count < count
        end
      end
    end
  end
end
```

[1]: https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_each
[2]: https://github.com/rails/rails/issues/28085#issuecomment-457909168

[^1]: https://www.postgresql.org/docs/current/queries-limit.html
[^2]: https://www.postgresql.org/docs/current/sql-declare.html
