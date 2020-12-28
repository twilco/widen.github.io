---
title: "Sometimes, a billion laughs isn't so funny — improving CSS variables in WebKit"
author: Tyler Wilcock
categories: css open-source browsers
excerpt: "As part of Widen's commitment to contributing back to the open-source community, we have sponsored work to improve
the CSS variables implementation in WebKit.  Read on to learn more about CSS variables and how they're implemented in WebKit."
---

<style>
.widen-sub-header {
  font-size: 1.4rem;
}
/* The default style given by the footnotes plugin pushes it too far to the left. */
.footnotelist {
  margin-left: 0px;
}
</style>

Widen, like many companies, makes heavy use of open-source technology, and we have made it a part of our
mission to give back to this community that we benefit so much from.  In light of this, today I'll be talking about some improvements I
made to the CSS variables implementation in WebKit.

### What is WebKit?

[WebKit](https://webkit.org/) is an open-source browser engine that is most famous for powering Safari.  Safari is far from the only place
 you'll find WebKit, however — it is behind every browser on iOS, all web content displayed on PlayStation systems, and in various GTK-based browsers
such as [Gnome Web](https://github.com/GNOME/epiphany).  WebKit is also deployed to millions of embedded
devices via the [WPE](https://webkit.org/wpe/) port (**W**ebKit **P**ort for **E**mbedded).

### CSS has variables?

Yes!  You don't need a CSS preprocessor to use variables in your CSS.  Here's what the syntax looks like{% fn %}:

```css
:root {
  --gutter: 4px;
}

section {
  margin: var(--gutter);
}

@media (min-width: 600px) {
  :root {
    --gutter: 16px;
  }
}
```

Because CSS variables are native to the web platform, they can do things CSS preprocessor variables can't.  For example,
they can be used in media queries, or manipulated with JavaScript:

```javascript
// 4px or 16px depending on current screen-width
const gutterSize = getComputedStyle(document.documentElement)
                    .getPropertyValue('--gutter')
                    .trim()

maximizeGutterButton.onclick = () => {
  document.documentElement.style.setProperty('--gutter', '32px');
})
```

CSS variables are also known as custom properties.

### Improvements to WebKit's CSS variables implementation

You can find the diff for each fixed bug by following the <a href="https://bugs.webkit.org">bugs.webkit.org</a> sub-header link and clicking "Formatted Diff" on the
patch.

#### Safer handling of overly long CSS variables
<div class="widen-sub-header"><a href="https://bugs.webkit.org/show_bug.cgi?id=216407">https://bugs.webkit.org/show_bug.cgi?id=216407</a></div>

One useful thing about CSS variables is that the value of one variable can be the expansion of another.  However, this
can get out of hand when used maliciously:

```css
:root {
  --prop1: lol;
  --prop2: var(--prop1) var(--prop1);
  --prop3: var(--prop2) var(--prop2);
  --prop4: var(--prop3) var(--prop3);
  /* expand to --prop30 */
}
```

If allowed to run unchecked, the above snippet will result in the browser attempting to create approximately one billion instances of `--prop1`'s value ("lol"),
which is more than enough to run most systems out of memory.  Testing this in Safari on my 2019 MackBook Pro, 32gb of RAM was consumed within 30 seconds, and Safari eventually refused to load the page.

This is an example of the [billion laughs attack](https://en.wikipedia.org/wiki/Billion_laughs_attack), and prior to this patch all WebKit-based browsers were susceptible to it via CSS variables.  Now, any CSS variable value that requires more than 65536 expansions is treated as invalid, and the variable expansion process is preempted early.

#### Enable CSS-wide keywords to be used as variable fallbacks
<div class="widen-sub-header"><a href="https://bugs.webkit.org/show_bug.cgi?id=197158">https://bugs.webkit.org/show_bug.cgi?id=197158</a></div>

CSS variable expansions can specify fallback values in case the given variable is not available.  For example, see this
example where the `background-color` for `.foo` is either `--optional-theme-color` or [`revert`](https://developer.mozilla.org/en-US/docs/Web/CSS/revert).

```css
/* Any other CSS value may also be used as a fallback */
background-color: var(--optional-theme-color, revert);
```

Prior to this patch, CSS-wide keywords were not parsed in the context of variable fallbacks, and therefore were always considered invalid values.  This
includes `inherit`, `initial`, `revert`, and `unset`.

#### Resolve relative-path URLs in `url()` against the correct base URL when CSS variables are involved
<div class="widen-sub-header"><a href="https://bugs.webkit.org/show_bug.cgi?id=198512">https://bugs.webkit.org/show_bug.cgi?id=198512</a></div>

Given this folder-structure:

```
project/
├── index.html
└── assets/
|   └── ducky.png
└── styles/
    └── stylesheet.css
```

And these styles in `stylesheet.css`:

```css
:root {
  --background-url: url('../assets/ducky.png');
  --repeat-style: no-repeat;
}

/* Both of these backgrounds would fail to resolve ducky.png. */
body {
  background: var(--background-url);
}

div {
  background: url('../assets/ducky.png') var(--repeat-style);
}
```

Then the URL should be resolved relative to the directory the `url()` originates in, which is the `styles` directory in this case.  However, prior to this patch, whenever a variable was present in a rule, `url()`s in that rule would unconditionally resolve relative to the base document URL (that of `index.html` here).
This means that neither `background` rule above would've been able to correctly resolve the path of our precious `ducky.png`.

To fix this, WebKit's representation of [pending-substitution values](https://drafts.csswg.org/css-variables/#pending-substitution-value) now
tracks the base URL that should be used to resolve any `url()` in the value, rather than unconditionally resolving them against the
base document URL.

#### Prevent :visited styles from erroneously being applied to non-visited links when CSS variables are present in the rule
<div class="widen-sub-header"><a href="https://bugs.webkit.org/show_bug.cgi?id=210525">https://bugs.webkit.org/show_bug.cgi?id=210525</a></div>

Given:

```css
:root {
  --link-color: green;
  --link-color-visited: red;
}

.link {
  color: var(--link-color);
}
.link:visited {
  color: var(--link-color-visited);
}

<a class="link" href="https://widen.com"></a>
```

WebKit used to erroneously apply the `:visited` styles for non-visited links when variables were part of the rule, meaning
the color of this link would always be red.

In WebKit's style-building code, there is a piece of state that manages whether the styles it is evaluating should be applied
to the set of normal, non-visited styles, to the set of `:visited` styles, or to both sets of styles.

The manifestation of the bug looked like this:

1. The parsing of the `.link:visited` style begins, and style-state is updated to register `:visited` styles
2. A CSS variable is encountered, so work begins to expand it
3. As part of this expansion, the aforementioned style-state is manipulated to various values, and unconditionally reset
to point at the non-visited style set
4. Variable expansion completes, but because of the unconditional reset to non-visited style-state in the previous step,
it is erroneously applied to the non-visited style set

One solution would be to keep track of the value of this style-state before variable expansion begins, and reset it back to this
value in step 3.  I did try this, but it isn't the cleanest solution, as one would have to remember to reset this state
any time the function returns.

Instead, any time this state is mutated during variable expansion, it is now done so with a utility within WebKit called
`SetForScope`, which automatically rolls the changed state back to its original value when the `SetForScope` is destroyed.

### Future work

Currently, CSS variables used in `@keyframes` animations in WebKit [are broken](https://bugs.webkit.org/show_bug.cgi?id=201736).
I haven't got around to fixing this one yet, but hope to do so soon.

I'd like to thank Widen again for their full support in my work on this, and in general for enabling all of our development team
to give back to the open-source community.  If you are interested in joining us, check out our openings [here](https://www.widen.com/careers)!


{% footnotes %}
   {% fnbody %}
      This example was taken from <a href="https://developers.google.com/web/updates/2016/02/css-variables-why-should-you-care">https://developers.google.com/web/updates/2016/02/css-variables-why-should-you-care</a>.
   {% endfnbody %}
{% endfootnotes %}
