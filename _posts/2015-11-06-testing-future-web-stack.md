---
title:  The Future of Web Development Part 2 - Comprehensive Automated Testing
author: Ray Nicholus
categories: react falcor webpack web server JSON HTTP node.js JavaScript ES6 jasmine selenium webdriver testing
excerpt: "In my last article, I showed you how to develop a full-stack JavaScript web application using some pretty interesting and futuristic libraries and web specifications. In this follow-up, I'm going to demonstrate how you can write JavaScript-based unit and integration/Selenium tests for that same app using nothing but JavaScript."
---

In [my last article][part1], I showed you how to developer a full-stack JavaScript web application using ECMAScript 6, Falcor, React, Babel, Webpack, and NodeJS. Developing a project using this futuristic stack is undoubtedly fun, but this is only a piece of the puzzle. Any code you write that is meant to be used by others should be tested. Manually testing your code is certainly one approach, though you will find this route cumbersome. In order to make more efficient use of your time and provide executable documentation for future maintainers, it is important to develop a suite of automated tests. In this follow-up article, I'll show you how to write automated tests for _all_ of the code we wrote in the first article. We will automate testing of the frontend and server-side code, _plus_ I'll show you how to write automated integration (a.k.a. Selenium) tests that exercise the entire application. Keeping with the spirit of the first article, all tests will be written using JavaScript and made available in [an updated version of the same GitHub repository][repo-v2]. After completing this article and following the coding examples, you'll see how easy and satisfying it is to write automated tests for _your_ web applications.

Generally speaking, automated tests ensure that future changes to our code due to maintenance or evolution do not cause our application to regress. In other words, we want to be sure that our users are _always_ able to add new names. It's also important that the list of names presented to the user is accurate and up-to-date. There are probably some edge cases that should be tested as well. What happens if our server goes down? How does the UI respond? It's also prudent to ensure that our application works in all supported browsers. If you have spent any amount of time developing for the web, you already know that this is a real concern due to potential browser-specific issues and varying web API and JavaScript implementations. And what if an unexpected condition is encountered server-side? How will our Falcor routes deal with this? While our app is indeed trivial, there is quite a bit that can go wrong, and that means we have a lot of tests to write!

While manual tests are still important, I'm going to discuss automated tests in this article. Furthermore, I'll discuss two distinct types of automated tests - unit tests, and integration tests. Unit tests are low-level and very narrowly scoped. They exercise only specific sections of your code. For example, we'll write a different set of unit tests for each frontend React component, along with a set of tests for our backend Falcor routes. It's critical that we focus on testing the specific roles of each of these modules, and that may mean mocking out a module's internal dependencies so that we can better control the environment. When we "mock" something, we're essentially replacing it with a dummy version that we have full control over. This eliminates uncertainty in our testing environment.

In addition to unit tests, we have integration tests, which may also be known as "Selenium" or "Webdriver" tests due to the tool most commonly used to execute them. Integration tests differ from unit tests in their purpose and focus. While unit tests exercise specific code paths inside of a specific isolated module of code, integration tests are aimed at testing user workflows. They are high-level tests and are written with our users in mind. Instead of testing the module that is responsible for adding a new name, we'll instead load the app in a browser, type a new name into the input field, hit enter, and then ensure that name is added to the list on the page. In this respect, _all_ of our code is being tested at once. Our job is to not only ensure user workflows are covered, but also that all of our components play nicely together in a realistic scenario. 

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
