# Widen Developer Relations

[![Build Status](https://travis-ci.org/Widen/widen.github.io.svg?branch=develop)](https://travis-ci.org/Widen/widen.github.io)


Spread the love.

## Requirements

Ruby, RubyGems, and Bundler.

## Getting Started

```sh
git clone git@github.com:Widen/widen.github.io.git
cd widen.github.io
bundle install
jekyll serve --drafts
```

## Add a post

Start posting easily with the following `make` commands:

* To create a new post: `make createPost title="this is my new post"`
* To create a new draft: `make createDraft title="this is my new draft post"`

If you wish to post using a more manual approach, all posts are located in `./_posts`. You can manually create a file within that dir:

* Blog posts must start with their publish date (this can be changed) (i.e., `yyyy-mm-dd-{title}.md`) (e.g., `2013-12-30-Hello-World!.md`)).
* Blog posts must have [YAML front matter](http://jekyllrb.com/docs/frontmatter/).

### Example post:

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


## Publish to engineering.widen.com

Simply push to the develop branch, and travis-ci will re-deploy the site, making your changes live within minutes. If you do _not_ want your changes to go live yet, create a branch off of develop and push to this new branch. Once you are ready to make your changes live, merge back into develop and push up to GitHub.
