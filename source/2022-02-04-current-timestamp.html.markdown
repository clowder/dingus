---
title: "`CURRENT_TIMESTAMP`"
date: 2022-02-04 11:25 UTC
description: "Better understand the semantics of `CURRENT_TIMESTAMP` within database transactions."
---

Turns out calling `CURRENT_TIMESTAMP` within a transaction will always return
the time the transaction began[^1]. In my mental model I'd always thought of it
being the clock time for the statement.

Postgres aliases `CURRENT_TIMESTAMP` to `transaction_timestamp()` which is a
more intention revealing name. There's also the well named `clock_timestamp()`
and `statement_timestamp()`, both of which simply do what-it-says-on-the-tin.

[^1]: https://postgresql.org/docs/14/interactive/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT
