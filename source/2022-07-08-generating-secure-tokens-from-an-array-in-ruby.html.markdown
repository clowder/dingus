---
title: "Generating secure tokens from an array in Ruby"
date: 2022-07-08 08:46 UTC
description: "Learn how to generate secure tokens from an array of characters or a wordlist in Ruby"
---

Ruby's `SecureRandom` provides a random number generator suitable for
generating secure tokens. But it doesn't allow the user to specify a source
array, for example an array of characters or a [wordlist][1].

By contrast Ruby's `[Array#sample]` allows us to build a random sequence from
any array. But it uses a psudo-random number generator and the sequences it
generates are deterministic (guessable) and not suitable for generating secure
tokens.

Luckily these two can work together. By specifiying `SecureRandom` as the
source of randomness for `[Array#sample]` we can generate a secure token from
any array.

```ruby
Array("a".."z").sample(20, random: SecureRandom).each_slice(4).map(&:join).join("-")
# => "hcqo-dtnf-gsim-bawu-kvjy"
```

```ruby
wordlist = %w[abandon ability ... zone zoo]
wordlist.sample(6, random: SecureRandom).join("-")
# # => "item recycle habit almost few beach"
```

`[Array#shuffle]` and `[Array#shuffle!]` also accept the `random` argument.

[1]: https://github.com/bitcoin/bips/blob/df443f8db30862b4776b4c06c47b62ded0790dc5/bip-0039/bip-0039-wordlists.md
