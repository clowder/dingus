---
title: Recursive SQL
date: 2022-03-04 12:25 UTC
---

This week I encountered SQL's recursive query syntax[^1] for the first time,
using the `WITH RECURSIVE` common table expression syntax.

Given an sample hierarchy of book genres we can build up a table of breadcumbs:

| id | name            | parent_id |
|----|-----------------|-----------|
| 1  | Science Fiction | NULL      |
| 2  | Dystopian       | 1         |
| 3  | Cyberpunk       | 2         |
| 4  | Space opera     | 1         |

```sql
WITH RECURSIVE linages AS (
  -- The non-recursive base case, top-level parents only
  SELECT
    ARRAY[genres.name] AS genre_names,
    genres.id AS tail_id
  FROM genres
  WHERE genres.parent_id IS NULL

  UNION ALL

  -- Recursively join sub-genres to their parent
  SELECT
    linages.genre_names || genres.name AS genre_names,
    genres.id AS tail_id
  FROM genres
  INNER JOIN linages ON genres.parent_id = linages.tail_id
)

SELECT ARRAY_TO_STRING(linages.genre_names, ' → ') AS breadcumb
FROM linages;
```

The result contains every generation of the recursion.

| breadcumb                               |
|-----------------------------------------|
| Science Fiction                         |
| Science Fiction → Space opera           |
| Science Fiction → Dystopian             |
| Science Fiction → Dystopian → Cyberpunk |


Early in my career I saw SQL as something to avoid or abstract away, but with
time I've come to love munging data using SQL.

[^1]: https://modern-sql.com/caniuse/T131
