# Widen Developer Relations

Spread the love.

## Requirments

Ruby and rubygems.

## Getting Started

```sh
gem install jekyll
git clone -b spike/jekyll git@github.com:Widen/widen.github.io.git && cd widen.github.io
jekyll serve
```

## Add a post

Blog posts are located in `./_posts`.

Blog posts must start with their publish date (this can be changed) (i.e., `yyyy-mm-dd-{title}.md`) (e.g., `2013-12-30-Hello-World!.md`)).

Blog posts must have YAML front matter.

```
---
title: This is my post title!!
layout: special-post
---

And now we start writing..

Woohoo!

**All markdown is supported here**, __and will be rendered to proper HTML__.

{{ assign template=liquid }}
```

## Add a page

Pages are located in the project root.

Same rules apply for YAML front matter and markdown support.
