---
title: Compiling the Raspberry Pi Pico SDK on Apple Silicon
date: 2022-06-10 15:46 UTC
description: "Get up-and-running building apps for the Raspberry&nbsp;Pi&nbsp;Pico on MacOS running on Apple Silicon."
---

Getting up-and-running building apps with the Raspberry&nbsp;Pi&nbsp;Pico SDK
on MacOS isn't straight forward if your machine runs on Apple silicon.Homebrew
installs a broken version ARM GCC tool-chain (v11.2). This version throws
seemingly arbitrary `internal compiler error: Illegal instruction` errors in
builds.

Fortunately the previous version (v10.3) doesn't suffer from the same issue.
But Homebrew makes it tricky to past previous versions of cask formula,
requiring users to dig out the revision and host a "tap" to install from. To
make it easier to get up-and-running quickly I've pulled together the Homebrew
tap, SDK, a "hello world" application and a README into a repo:

https://github.com/clowder/rpi-pico-macos-starter
