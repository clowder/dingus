---
title: Cheap context switching with git-worktree
date: 2022-04-01 10:55 UTC
---

Git supports multiple checkouts from a single repository, allowing for multiple
working directories linked to a single repository.

For arguments sake let's say you're working in a feature branch and spot a
typo. Damn! Instead of committing work-in-progress to switch branches
[git-worktree][1] can checkout another branch to a temporary working directory.

```
$ git worktree add ../copy-changes main
$ cd ../copy-changes
```

Once complete you return to you're main working directory and clean-up.

```
$ cd ../web-app
$ git worktree remove ../copy-changes
```

<span class="text-7xl cursor-wand" title="Git is magic">🧙🏻‍♂️</span>

[1]: https://git-scm.com/docs/git-worktree
