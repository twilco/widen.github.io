---
title:  The Future of Web Development Part 2 - Comprehensive Automated Testing
author: Ray Nicholus
categories: react falcor webpack web server JSON HTTP node.js JavaScript ES6 jasmine selenium webdriver testing
excerpt: "In my last article, I showed you how to develop a full-stack JavaScript web application using some pretty interesting and futuristic libraries and web specifications. In this follow-up, I'm going to demonstrate how you can write JavaScript-based unit and integration/Selenium tests for that same app using nothing but JavaScript."
---

In [my last article][part1], I showed you how to developer a full-stack JavaScript web application using ECMAScript 6, Falcor, React, Babel, Webpack, and NodeJS. Developing a project using this futuristic stack is undoubtedly fun, but this is only a piece of the puzzle. Any code you write that is meant to be used by others should be tested. Manually testing your code is certainly one approach, though you will find this route cumbersome. In order to make more efficient use of your time and provide executable documentation for future maintainers, it is important to develop a suite of automated tests. In this follow-up article, I'll show you how to write automated tests for _all_ of the code we wrote in the first article. We will automate testing of the frontend and server-side code, _plus_ I'll show you how to write automated integration (a.k.a. Selenium) tests that exercise the entire application. Keeping with the spirit of the first article, all tests will be written using JavaScript and made available in [an updated version of the same GitHub repository][repo-v2]. After completing this article and following the coding examples, you'll see how easy and satisfying it is to write automated tests for _your_ web applications.


{% what do we need to test? why? %}

{% explain unit and integration tests %}

{% client-side unit tests %}
  {% Restructure our files - client-side stuff into app dir & config into config dir %}
    {% Fixing our webpack npm script based on moved files %}
  {% Explanation of testing tools %}
  {% Configuring karma %}
  {% Testing name-adder %}
  {% Testing name-list %}
  {% Testing name-manager %}
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

[repo-v2]: https://github.com/Widen/fullstack-react/tree/2.0.0
[part1]: {{base}}/blog/future-of-the-web-react-falcor/
[testing-slides]: http://slides.com/raynicholus/automated-testing
