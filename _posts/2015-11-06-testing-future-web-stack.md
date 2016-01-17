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

## Part 1: Browser-side unit tests
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

Our client-side unit tests will be created with the help of a few important and useful tools:

1. [Jasmine][jasmine]
2. [PhantomJS][phantomjs]
3. [Rewire][rewire]
4. [Karma][karma]

Jasmine is a JavaScript library we will use to write our unit tests. It includes a rich [set of assertions][jasmine-matchers] for comparing actual values under test with expected values, a full-featured [mocking engine][jasmine-spies] that will allow us to more easily focus on the component under test, as well as a number of other helpers that we will use to [group our tests][jasmine-describe] and [test asynchronous behaviors][jasmine-async].

PhantomJS is a headless version of [Webkit][webkit], the rendering engine currently used in Apple's Safari browser and formerly used in Google's Chrome browser (before it was forked as [Blink][blink]). Running our unit tests in a headless browser makes them easy and quick to run, not to mention portable. The entire browser is distributed and contained in a JavaScript package downloaded from npm. Using a conventional browser for unit tests in a development environment can be jarring with browser windows opening and closing, especially if tests are automatically re-run as soon as any code changes are saved. While a 2.0 version of PhantomJS is available, we will stick with 1.9, since the 2.0 version has some long-standing issues with no solutions in sight. For example, there are no official, stable Linux binaries at the moment.

Rewire is a Node.js tool primarily used (at least in this project) to mock out sub-modules imported by a module under test. For example, when testing our `<NameManager/>` component, we need to be able to control the behavior of its internal dependencies - `<NameList/>` and `<NameAdder/>`. We can use Rewire to gain access to these dependencies inside of `<NameManager/>` and replace them with dummy modules with inputs and outputs that we can monitor and control in order to more reliably test _this_ component. Rewire allows us to access internal dependencies in this way by using its own module loader to insert hooks into modules that allow them to be unnaturally accessed and controlled in a testing environment. For our browser-based unit tests, we'll need to use a Babel plug-in that wraps the Rewire plugin. It is aptly named [babel-plugin-rewire][rewire-babel]. We must use this Babel plug-in instead of the native Rewire library due to [Babel's unique ECMAScript 6 module transpilation logic][rewire-babel-bug].

Karma is a test runner and reporter, initially developed by Google for use with AngularJS unit tests. Fun fact: it was originally known as [Testacular][testacular]. It's hard to imagine why they changed the name, but I digress. Before we can begin writing tests, we must first configure Karma and tie all of our testing and reporting tools together. Remember that karma is our client-side test _runner_. In other words, it will use use Jasmine to execute the tests we are going to write, and it will provision a PhantomJS instance as an environment in which the tests will run. It will report the results using a karma plugin: karma-spec-reporter. A plug-in will allow Karma to use Webpack to generate a temporary source bundle that includes all of the code we intend to test. Our existing webpack.config.js file will be used here to determine how this bundle is generated. But we will contribute an addition Babel plug-in to our Webpack configuration just for these tests - babel-plugin-rewire - which will hook into the bundle generation process and add hooks into our code that we will need to mock out dependencies internal to each of the React components we intend to test. Finally, we'll ask Karma to include an ECMAScript 5 "shim", which is needed to ensure our modern code runs properly in PhantomJS 1.9, which is essentially a relatively old version of Safari.

Our Karma configuration will be named karma.conf.js, and it will be appropriately located inside of our new "config" directory. The completed file will look like this:

```javascript
var webpackConfig = require('./webpack.config')
webpackConfig.module.loaders[0].query = {plugins: ['babel-plugin-rewire']}

module.exports = function (config) {
    config.set({
        basePath: '../',
        browsers: ['PhantomJS'],
        files: [
            'node_modules/es5-shim/es5-shim.js', // only used by PhantomJS 1.x
            'app/test/tests.bundle.js'
        ],
        frameworks: ['jasmine'],
        plugins: [
            require('karma-webpack'),
            'karma-spec-reporter',
            'karma-jasmine',
            'karma-phantomjs-launcher'
        ],
        preprocessors: {
            'app/test/tests.bundle.js': 'webpack'
        },
        reporters: ['spec'],
        singleRun: true,
        webpack: webpackConfig,
        webpackMiddleware: {noInfo: true}
    });
};
```

Before we start configuring Karma, you'll notice that we are referencing our existing Webpack configuration file and adding a plug-in - babel-plugin-rewire. As mentioned previously, this will allow us to more easily mock internal component dependencies. Moving on, our first configuration point is the `basePath`. The location here establishes a relative path for all other paths specified in our configuration file. Since our configuration file is located inside of the "config" subdirectory, our base path is set to the root of the project. Next, we must declare any browsers to run our tests against. We're just using PhantomJS at the moment. Note that a Karma plug-in for PhantomJS is specified in the `plugins` section near the middle of the file as well. This plug-in will be used by Karma to start and control PhantomJS.

The `files` configuration point is an array containing a path to the ECMAScript 5 shim used to fill-in missing ES5 support for PhantomJS, followed by a file that will be later coded to include all of our test files. Followed by `files` is `frameworks`. This array will only contain one value - "jasmine" - which is our unit test framework. Later, we'll write all of our unit tests using Jasmine. Notice that there is a corresponding plug-in - karma-jasmine - in the following `plugins` section. This plug-in provides Karma programmatic access to the Jasmine binaries.

Skipping down just a tad to the `preprocessors` section, we are instructing Karma to run our unit test files through Webpack. The last two items in our config file - `webpack` and `webpackMiddleware` - are used to point Karma at our Webpack configuration file (which we pulled in at the top of this file) and ensure info messages are printed to the console, respectively. There is a Webpack plug-in for Karma as well referenced as the first item in our `plugins` array.
Karma will only run our tests once and then exit, thanks to the `singleRun` option set to a value of `true`. And finally, our test results will be printed in a useful format to the console using a reporter plug-in - karma-spec-reporter. The alias for this reporter - "spec" - is include in the `reporters` array, and the plug-in is mentioned in our `plugins` array as well. Karma is ready to go, and next we will begin writing client-side unit tests.


### Writing our tests

I've explained why it is important to write automated unit tests, covered the tools we will be using to write and run these tests, _and_ I've showed you how to configure karma to actually run the tests. Just one problem - we don't have any tests to run. Let's take care of that now by writing comprehensive unit tests that cover each of [our three React components from the previous article][part1-components]: `<NameAdder />`, `<NamesList />`, and our "glue" component - `<NameManager />`.

Each component's tests will be located in a dedicated file inside of a new subdirectory under our app directory. After writing all of our tests, our file tree will look something like this:

```
.
+-- app
|   +-- model.js
|   +-- name-adder.jsx
|   +-- name-manager.jsx
|   +-- names-list.jsx
|   +-- test
|      +-- name-adder.spec.jsx
|      +-- name-manager.spec.jsx
|      +-- names-list.spec.jsx
|      +-- tests.bundle.js
+-- config
|   +-- karma.conf.js
|   +-- webpack.config.js
+-- site
|   +-- index.html
+-- server.js
+-- package.json
```

Notice a fourth file in the new tests directory - tests.bundle.js. This was first mentioned in the previous section, as it is referenced as the entry point in our Karma configuration file. Essentially, this file identifies all test files to execute. In fact, it looks for any files ending in .spec.js or .spec.jsx in the current directory and makes them available for execution by, in this case, Karma, and it looks like this:

```javascript
var context = require.context('.', true, /.+\.spec\.js(x?)?$/)
context.keys().forEach(context)
module.exports = context
```

#### Testing NameAdder

In [the previous article][part1], we created a React component with a very specific job - allow a new name to be added to our list of names. A simple unit test would ensure that this component is at least able to perform this task. In short, we are going to write a relatively simple test that attempts to enter a new name into the `<input type="text">` rendered by this component, click the add button, and then ensure our component calls our Falcor model with the correct data. I'll start by posting the entire test specification. Don't worry, I'll cover this first example in quite a bit of detail, which will be helpful to you when viewing tests for our other React components.

So, this is app/test/name-adder.spec.jsx:

```javascript
var React = require('react'),
    ReactDom = require('react-dom'),
    NameAdder = require('../name-adder.jsx'),
    Falcor = require('falcor'),
    TestUtils = require('react/lib/ReactTestUtils')

describe('NameAdder', () => {
    it('saves new messages', () => {
        var model = jasmine.createSpyObj('model', ['call']),
            onNameAdded = () => {},
            nameAdder = TestUtils.renderIntoDocument(<NameAdder onAdded={onNameAdded}/>),
            form = TestUtils.findRenderedDOMComponentWithTag(nameAdder, 'form'),
            input = nameAdder.refs.input

        NameAdder.__Rewire__('model', model)
        model.call.and.returnValue({then: (success) => success()})

        input.value = 'new name'
        TestUtils.Simulate.submit(form)

        expect(model.call).toHaveBeenCalledWith(['names', 'add'], ['new name'], ['name'])
    })
})
```

First, you'll notice that I've imported several dependencies that will be needed to complete this test. `React`, `ReactDom`, `NameAdder`, and `Falcor` are probably not surprising, but `TestUtils` is a new one. React provides a set of utilities that help writing unit tests against React component. We'll use various methods in `TestUtils` to easily add our component under test to the DOM, locate children of this component, and simulate DOM events that trigger our component to take specific actions.

Our test is wrapped in an `it` block, which itself is wrapped in a `describe` block. These are Jasmine conventions. The `describe` block is meant to contain a set of tests, and each `it` block contains a single test. Each of them should read like a sentence or phrase. Here, we will `describe` a `NameAdder` component. What does it do? `it` saves new messages. We will test this assertion inside of the `it` block.

Inside of our `it` block, we're first using Jasmine to created a mocked version of our Falcor model, which we will "inject" into our `NameAdder` component shortly. By mocking the model, we can easily control and examine inputs and outputs to verify the behavior of the component under test. Next, we're defining an empty function, which will serve as the value of the `onAdded` property passed to our `NameAdder` component, which is created and added to our document after that. We don't much care about the `onAdded` property for the purposes of this test - but it must be supplied as it is current a required property. The last two variable declarations at the top of the `it` block locate the `<form>` and `<input>` elements inside of our rendered `NameAdder` component. We'll need access to these soon when we test our component.

Remember when I said we would need to inject the mocked Falcor model into our `NameAdder` component instance? That happens immediately after the block of variable declarations. This is where babel-plugin-rewire enters into our testing stack. This babel plug-in added a bunch of methods to the compiled JavaScript code that makes it easy to access internal dependencies. This is especially useful for replacing real dependencies with mocked ones. The `__Rewire__` function, added to our `NameAdder` component during babel compilation, allows us to replace our Falcor model simply by specifying the name of the internal variable that is assigned the import - `model` - followed by the new value - our Jasmine-created mock object. immediately after injecting our mocked model into `NameAdder` we're defining a behavior, again using Jasmine. When the `call` method is invoked by `NameAdder` on this mock object, invoke the promissory success function, indicating that the model update was a success. Remember that the `call` function on our Falcor model is used internally by `NameAdder` to send a newly added name to the model.

The `<input>` we referenced in the variable block is used next. We're essentially "typing" in a new name by setting the `value` property of this element. Text inputs, among several other input types, will reflect entered data on the `value` property on the JavaScript object that represents the element tag in our markup. We can read _or_ write to this property. Internally, `NameAdder` reads this property when handing a form submission, and sends the value of this `value` property to the Falcor model. And so, now that we've entered a new name, we need to submit the form. `TestUtils` provides a method that will "simulate" a form submit. Without this shortcut, triggering a DOM event can be a bit tricky in some instances. Just think of this as an easy way to invoke the internal `onSubmit` function set on the `<form>` component inside of `NameAdder`. This function starts the chain of actions that ends in a new name being sent to our server.

Finally, we have to actually _test_ something, don't we? Perhaps the most prudent course at this juncture is to hook into our mocked Falcor model, ensure proper route has been `call`ed with the text of our new name. The `expect` function - a utility provided by Jasmine - gives us an easy and intuitive way to describe the expected value of a mocked object.


#### Testing NamesList

In case the previous article is a bit fuzzy at this point, remember that we created a `<NamesList>` React component with one specific goal - list all names and auto-update when a new name is added. Now it's time to write tests for this component. Before we write any code, let's figure out exactly _what_ we need to test. The simplest test perhaps mocks out our data store and ensures the `<NamesList>` component renders all of the names in our mocked store. The critical piece of this test involves inserting a mocked version of our server's data store. Luckily this is very easy to accomplish with babel-plugin-rewire and Falcor. Let's take a look at the code for this test first, housed in app/test/names-list.spec.jsx:

```javascript
var React = require('react'),
    TestUtils = require('react/lib/ReactTestUtils'),
    NamesList = require('../names-list.jsx'),
    Falcor = require('falcor')

describe('names-list tests', () => {
    afterEach(() => NamesList.__ResetDependency__('model'))

    it('renders with some initial data', (done) => {
        NamesList.__Rewire__('model', new Falcor.Model({
            cache: {
                names: {
                    0: {name: 'joe'},
                    1: {name: 'jane'},
                    length: 2
                }
            }
        }))

        var namesList = TestUtils.renderIntoDocument(<NamesList/>)

        namesList.componentDidUpdate = () => {
            var nameEls = TestUtils.scryRenderedDOMComponentsWithTag(namesList, 'li')

            expect(nameEls.length).toBe(2)
            expect(nameEls[0].textContent).toBe('joe')
            expect(nameEls[1].textContent).toBe('jane')

            done()
        }
    })
})
```

Nothing new in the variable declaration section at the top of the file, other than the import of Falcor. We'll need to make brief use of Falcor's client-side API as we work with our mocked model. At the top of the `describe` block, there's an `afterEach` function, which may be new to some who are not already familiar with Jasmine. The body of this function will run after each test has completed. Since we only have one test (so far), this will run after the single `it` block has completed. While not entirely necessary in our case it is good practice to reset any internal dependencies that have been tampered with at the end of each test. As you will see soon in our test, we are replacing the imported Falcor model with a mocked version, and the logic in our `afterEach` block acts as an "undo" for this action, so as not to pollute other tests.

We've only written one test for `<NamesList>`, which is a sufficient start. As the title of the `it` block states, we're going to ensure that the initial render of this component renders all available names according to the model/store. In the first line of our `it` block, babel-plugin-rewire is being used to replace the imported Falcor model with a mocked version. Our mocked model includes two names: "joe" and "jane". It is perfectly valid to initialize a Falcor model in this way, and this allows us to assert full control over the component's access to data, which makes writing unit tests much easier.

After rendering the component into a detached DOM node with the help of React's `TestUtils`, are waiting until the first time our component's state changes. The initial render will _not_ include the values from our mocked model, since accessing the model data is an asynchronous operation. Remember: after the model values are retrieved by `<NamesList>`, the component's internal state will be updated with the new names. And if there _are_ new names, the `componentDidUpdate` method will be called by React. `componentDidUpdate` is a [React component lifecycle method][react-lifecycle] that is called after each state change (but not on the initial component render). Our test hooks into this lifecycle method and checks to ensure that the component's DOM contains the names represented by our mocked model using Jasmine's built-in assertion library. Inside of this method, first are handle on the list item elements containing the names is created, and then each list item is checked to ensure it matches the expected name from the model. The method name used to lookup these elements inside of the component, [`scryRenderedDOMComponentsWithTag`][scryRenderedDOMComponentsWithTag], looks a little strange, and it is (to me at least). For an explanation of the `scry` prefix, have a look at [this twitter conversation][whyscry-twitter].


#### Testing NameManager



### Running our tests

  {% Easily running our tests w/ npm test %}


## Part 2: Server-side unit tests


### Neatness counts - file reorganization
{% Restructure our files - server-side stuff into server dir %}
    {% Adjusting our server startup script based on new location of server. Move to npm script for consistency %}


### Refactoring our code to make it more testable


### Understanding our server-side testing tools


### Configuring Jasmine to run our tests


### Unit testing our Falcor routes


### Running our tests
{% Updating the npm test script to run server tests too %}


## Part 3: Integration testing


### Tools to help us write and run our tests


### Writing a simple but useful test
{% Test adding a name %}


### Running our test locally
{% Run locally against FF %}
{% Updating our npm scripts to simplify setup of test, startup of selenium server, running of tests}


## Part 4: Full Test Automation With Travis CI and BrowserStack
{% why is this good? %}


### What is Travis CI? What is BrowserStack?


### Setting up Travis
  {% Setting up an account %}
  {% Making Travis aware of your project %}

### Setting up BrowserStack
  {% Setting up account %}
  {% Configuring your base build %}


### Running our unit tests using Travis

### Running our integration tests using Travis and BrowserStack
  {% Updating integration tests & config to run against various browsers using BrowserStack %}
  {% Updating npm test script to run all tests %}


## Going further
    {% handle empty list of names in code and back it with a unit test for names-list %}
    {% move integration test config to a file in config dir %}
    {% better reporting of failed tests all around %}


[blink]: http://www.chromium.org/blink
[jasmine]: http://jasmine.github.io/2.3/introduction.html
[jasmine-async]: http://jasmine.github.io/2.3/introduction.html#section-Asynchronous_Support
[jasmine-describe]: http://jasmine.github.io/2.3/introduction.html#section-Grouping_Related_Specs_with_<code>describe</code>
[jasmine-matchers]: http://jasmine.github.io/2.3/introduction.html#section-Matchers
[jasmine-spies]: http://jasmine.github.io/2.3/introduction.html#section-Spies
[karma]: http://karma-runner.github.io/0.13/index.html
[package.json-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/package.json
[part1]: {{base}}/blog/future-of-the-web-react-falcor/
[part1-components]: {{base}}/blog/future-of-the-web-react-falcor#dividing-ui-roles-into-components-with-react
[phantomjs]: http://phantomjs.org/
[react-lifecycle]: https://facebook.github.io/react/docs/component-specs.html
[repo-v1]: https://github.com/Widen/fullstack-react/tree/1.2.1
[repo-v2]: https://github.com/Widen/fullstack-react/tree/2.0.0
[rewire]: https://github.com/jhnns/rewire
[rewire-babel]: https://github.com/speedskater/babel-plugin-rewire
[rewire-babel-bug]: https://github.com/jhnns/rewire/issues/55
[scryRenderedDOMComponentsWithTag]: https://facebook.github.io/react/docs/test-utils.html#scryrendereddomcomponentswithtag
[server.js-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/server.js
[testacular]: http://googletesting.blogspot.com/2012/11/testacular-spectacular-test-runner-for.html
[testing-slides]: http://slides.com/raynicholus/automated-testing
[webkit]: https://webkit.org/
[webpack.config.js-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/webpack.config.js
[whyscry-twitter]: https://twitter.com/angustweets/status/590659867926462465
