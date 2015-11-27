---
title:  The Future of Web Development Part 2 - Comprehensive Automated Testing
author: Ray Nicholus
categories: react falcor webpack web server JSON HTTP node.js JavaScript ES6 jasmine selenium webdriver testing
excerpt: "In my last article, I showed you how to develop a full-stack JavaScript web application using some pretty interesting and futuristic libraries and web specifications. In this follow-up, I'm going to demonstrate how you can write JavaScript-based unit and integration/Selenium tests for that same app using nothing but JavaScript."
---

In [my last article][part1], I showed you how to developer a full-stack JavaScript web application using ECMAScript 6, Falcor, React, Babel, Webpack, and NodeJS. Developing a project using this futuristic stack is undoubtedly fun, but this is only a piece of the puzzle. Any code you write that is meant to be used by others should be tested. Manually testing your code is certainly one approach, though you will find this route cumbersome. In order to make more efficient use of your time and provide executable documentation for future maintainers, it is important to develop a suite of automated tests. In this follow-up article, I'll show you how to write automated tests for _all_ of the code we wrote in the first article. We will automate testing of the frontend and server-side code, _plus_ I'll show you how to write automated integration (a.k.a. Selenium) tests that exercise the entire application. Keeping with the spirit of the first article, all tests will be written using JavaScript and made available in [an updated version of the same GitHub repository][repo-v2]. After completing this article and following the coding examples, you'll see how easy and satisfying it is to write automated tests for _your_ web applications.

Generally speaking, automated tests ensure that future changes to our code due to maintenance or evolution do not cause our application to regress. In other words, we want to be sure that our users are _always_ able to add new names. It's also important that the list of names presented to the user is accurate and up-to-date. There are probably some edge cases that should be tested as well. What happens if our server goes down? How does the UI respond? It's also prudent to ensure that our application works in all supported browsers. If you have spent any amount of time developing for the web, you already know that this is a real concern due to potential browser-specific issues and varying web API and JavaScript implementations. And what if an unexpected condition is encountered server-side? How will our Falcor routes deal with this? While our app is indeed trivial, there is quite a bit that can go wrong, and that means we have a lot of tests to write!

While manual tests are still important, I'm going to discuss automated tests in this article. Furthermore, I'll discuss two distinct types of automated tests - unit tests, and integration tests. Unit tests are low-level and very narrowly scoped. They exercise only specific sections of your code. For example, we'll write a different set of unit tests for each frontend React component, along with a set of tests for our backend Falcor routes. It's critical that we focus on testing the specific roles of each of these modules, and that may mean mocking out a module's internal dependencies so that we can better control the environment. When we "mock" something, we're essentially replacing it with a dummy version that we have full control over. This eliminates uncertainty in our testing environment.

In addition to unit tests, we have integration tests, which may also be known as "Selenium" or "WebDriver" tests due to the tool most commonly used to execute them. Integration tests differ from unit tests in their purpose and focus. While unit tests exercise specific code paths inside of a specific isolated module of code, integration tests are aimed at testing user workflows. They are high-level tests and are written with our users in mind. Instead of testing the module that is responsible for adding a new name, we'll instead load the app in a browser, type a new name into the input field, hit enter, and then ensure that name is added to the list on the page. In this respect, _all_ of our code is being tested at once. Our job is to not only ensure user workflows are covered, but also that all of our components play nicely together in a realistic scenario.

## Browser-side unit tests
We'll first focus on writing automated tests for our code that runs in the browser. This accounts for portions of our simple application that our users directly interact with. We'll primarily write tests for our React components, but first it may make sense to refactor our code a bit to make it more conducive to testing.

### Refactoring for ease of testing
The [most recent version of our names application][repo-v1] contains all of our source files organized into a flat structure. While this is a reasonable hierarchy for such a small number of files, it doesn't scale very well. As we add more files to handle configuration, testing, and to support better modularization of our application, we'll need a better-defined structure for our project. To start, let's move our 3 React components and the Falcor model file into a new directory named "app". Let's also move our webpack configuration file into a root-level "config" directory, and finally our index.html file into a "site" directory. This new "site" directory will contain all publicly accessible resources, so the webpack-generated bundle JavaScript should also live here. After this initial reorganization, our project looks like this:

```
.
+-- app
|   +-- model.js
|   +-- name-adder.jsx
|   +-- name-manager.jsx
|   +-- names-list.jsx
+-- config
|   +-- webpack.config.js
+-- site
|   +-- index.html
+-- server.js
+-- package.json
```

In order to support this new structure, a few changes must be made to some of our existing code. First, webpack.config.js has to be updated to be aware of the new location of our source files. This is a simple as change the value of the `entry` property from `./name-manager.jsx` to `./app/name-manager.jsx`. So [our original app/webpack.config.js][webpack.config.js-v1] file now looks like this:

```javascript
module.exports = {
    entry: './app/name-manager.jsx',
    output: {
        filename: './site/bundle.js'
    },
    module: {
        loaders: [
            {
                test: /\.js/,
                loader: 'babel',
                exclude: /node_modules/
            }
        ]
    },
    devtool: 'source-map'
}
```

Furthermore, our NodeJS server must be adjusted to serve the HTML and JS bundle files out of the site directory. This requires a simple change to our Express server. This means `app.use(express.static('.'))`, changes to `app.use(express.static('site'))` in our server.js file. So, the last few lines of [our original server.js][server.js-v1] now look like this:

```javascript
app.use(express.static('site'))
app.listen(9090, err => {
    if (err) {
        console.error(err)
        return
    }
    console.log('navigate to http://localhost:9090')
});
```

Before we go any further, we should make sure our changes haven't broken anything, but before we do that, let's make one additional adjustment. Going forward, it may be beneficial for us to use our package.json file as a place to execute any scripts needed to build, test, and run our application. The usefulness of this approach will become clearer as this exercise progresses. We'll start by defining a second target in the package.json `"scripts"` object, one that will startup our server. After this addition, the bottom of [our original package.json file][package.json-v1] looks like this:

```json
"scripts": {
  "server": "node --harmony server",
  "webpack": "webpack --config config/webpack.config.js"
}
```

There are two changes to this section of the file. First, a new `"server"` tasks has been added, which starts up our NodeJS server. Second, our `"webpack"` target has been adjusted to include a reference to the new location of our webpack configuration file. Previously, this file was located in the root of our project, and, by convention, webpack looks for a file named "webpack.config.js" in the root of the project. Since we've moved this to the config directory, we must now let webpack know where this configuration file exists.

### Getting familiar with our testing tools

  {% Explanation of testing tools %}
  {% Configuring karma %}


### Writing our tests

  {% Testing name-adder %}
  {% Testing name-list %}
  {% Testing name-manager %}

### Running our tests

  {% Easily running our tests w/ npm test %}


{% server-side unit tests %}
  {% Restructure our files - server-side stuff into server dir %}
    {% Adjusting our server startup script based on new location of server. Move to npm script for consistency %}
  {% Explanation of testing tools %}
  {% Configuring Jasmine %}
  {% Refactoring our server to make it more testable %}
  {% Testing all of our Falcor routes %}
  {% Updating the npm test script to run server tests too %}

{% integration tests %}
  {% Explanation of testing tools %}
  {% Test adding a name %}
  {% Run locally against FF %}
  {% Updating our npm scripts to simplify setup of test, startup of selenium server, running of tests}

{% CI w/ Travis + Sauce Labs %}
  {% What is Travis? %}
  {% What is SauceLabs? %}
  {% Setting up an account %}
  {% Making Travis aware of your project %}
  {% Setting up SauceLabs account %}
  {% Configuring your base build %}
  {% Updating integration tests & config to run against various browsers using SauceLabs %}
  {% Updating npm test script to run all tests %}

{% Going further %}
    {% handle empty list of names in code and back it with a unit test for names-list %}
    {% move integration test config to a file in config dir %}
    {% better reporting of failed tests all around %}

[repo-v1]: https://github.com/Widen/fullstack-react/tree/1.2.1
[repo-v2]: https://github.com/Widen/fullstack-react/tree/2.0.0
[package.json-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/package.json
[part1]: {{base}}/blog/future-of-the-web-react-falcor/
[server.js-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/server.js
[testing-slides]: http://slides.com/raynicholus/automated-testing
[webpack.config.js-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/webpack.config.js
