# Website Development

The *PL/JSON* website is a static site built with [Metalsmith][metalsmith].
To develop the website, do the following from the root project directory:

1. `npm install`
2. `npm run sitedev`
3. Open http://localhost:4000/ in your web browser

As you make changes within the `site_src` directory, e.g. adding a new page
or altering a current one, the website will be automatically rebuilt and
your web browser will refresh.

[metalsmith]: http://metalsmith.io

## Structure

The `site_src` directory has the following structure:

1. `assets`: a directory of static assets that will be used in the website,
   e.g. images or local CSS files
2. `layouts`: layout templates usable by individual pages
3. `pages`: a directory of HTML files that comprise the webite. Each file in
   this directory should contain only the contents of the `<body>` element
   for the page

## Page Notes

A page is merely the HTML that comprises what would be the contents of the
`<body>` element in a full HTML document. However, it is possible for a page
to contain YAML "frontmatter". This frontmatter is used to specify page
specific settings/variables. For example, the default layout is
`layouts/main.html` and the default page title is `PL/JSON`. Let's assume we
want to create a new page `foo` that uses a new layout `layouts/bar.html`
and has a title `Foobar`. After creating the appropriate layout (look at
the `layouts/main.html` for the requirements) we would create a new page
names `foo.html` in the `pages` directory with the following contnet:

```html
---
layout: bar.html
title: Foobar
---

<h1>The Foobar page!</h1>
```

Note that everything between the starting `---` and closing `---` is regular
YAML that will *not* be included in the rendered page.
