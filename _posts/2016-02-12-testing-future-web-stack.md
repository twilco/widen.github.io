---
title:  The Future of Web Development Part 2 - Full-Stack Automated JavaScript Testing
author: Ray Nicholus
categories: react falcor webpack web server JSON HTTP node.js JavaScript ES6 jasmine selenium webdriver testing
excerpt: "In my last article, I showed you how to develop a full-stack JavaScript web application using some pretty interesting and futuristic libraries and web specifications. In this follow-up, I'm going to demonstrate how you can write server-side and client-side unit and integration/Selenium tests for that app entirely in JavaScript."
---

In [my last article][part1], I showed you how to developer a full-stack JavaScript web application using ECMAScript 6, Falcor, React, Babel, Webpack, and NodeJS. Developing a project using this futuristic stack is undoubtedly fun, but this is only a piece of the puzzle. Any code you write that is meant to be used by others should be tested. Manually testing your code is certainly one approach, though you will find this route cumbersome. In order to make more efficient use of your time and provide executable documentation for future maintainers, it is important to develop a suite of automated tests. In this follow-up article, I'll show you how to write automated tests for _all_ of the code we wrote in the first article. We will automate testing of the frontend and server-side code, _plus_ I'll show you how to write automated integration (a.k.a. Selenium) tests that exercise the entire application. **Keeping with the spirit of the first article, all tests will be written using JavaScript and made available in [an updated version of the same GitHub repository][repo-v2]**. After completing this article and following the coding examples, you'll see how easy and satisfying it is to write automated tests for _your_ web applications.

Generally speaking, automated tests ensure that future changes to our code due to maintenance or evolution do not cause our application to regress. In other words, we want to be sure that our users are _always_ able to add new names. It's also important that the list of names presented to the user is accurate and up-to-date. There are probably some edge cases that should be tested as well. What happens if our server goes down? How does the UI respond? It's also prudent to ensure that our application works in all supported browsers. If you have spent any amount of time developing for the web, you already know that this is a real concern due to potential browser-specific issues and varying web API and JavaScript implementations. And what if an unexpected condition is encountered server-side? How will our Falcor routes deal with this? While our app is indeed trivial, there is quite a bit that can go wrong, and that means we have a lot of tests to write!

While manual tests are still important, I'm going to discuss automated tests in this article. Furthermore, I'll discuss two distinct types of automated tests - unit tests, and integration tests. Unit tests are low-level and very narrowly scoped. They exercise only specific sections of your code. For example, we'll write a different set of unit tests for each frontend React component, along with a set of tests for our backend Falcor routes. It's critical that we focus on testing the specific roles of each of these modules, and that may mean mocking out a module's internal dependencies so that we can better control the environment. When we "mock" something, we're essentially replacing it with a dummy version that we have full control over. This eliminates uncertainty in our testing environment.

In addition to unit tests, we have integration tests, which may also be known as "Selenium" or "" tests due to the tool most commonly used to execute them. Integration tests differ from unit tests in their purpose and focus. While unit tests exercise specific code paths inside of a specific isolated module of code, integration tests are aimed at testing user workflows. They are high-level tests and are written with our users in mind. Instead of testing the module that is responsible for adding a new name, we'll instead load the app in a browser, type a new name into the input field, hit enter, and then ensure that name is added to the list on the page. In this respect, _all_ of our code is being tested at once. Our job is to not only ensure user workflows are covered, but also that all of our components play nicely together in a realistic scenario. While there are other definitions of "integration" testing as meaning of this term seems to be somewhat subjective, we're going to work with the definition outlined here throughout this article.

## Part 0: Bringing our code and project up-to-date
Since the last article 4 months ago, most of our project's dependencies have changed in some way, some of them drastically. The most visible changes were to Falcor and Babel.

Version 0.1.16 of Falcor brings [a breaking change][falcor-path-change] that affected our response parsing code. In short, an unexpected item is visible among expected properties of "get" resonses: `$__path`. This new property is useful for creating new models based on sections of an existing JSON graph. This is accomplished using [the new `Model.deref` method][falcor-model-deref]. However, we don't have much use for this in our simple app. Since we only want to see the requested values in our "get" responses, we must [make use of a new `Falcor.keys` method][falcor-code-updates], which iterates over all of the keys in the response, ignoring the `$__path` property. In this way, it functions exactly like [`Object.keys`][object-keys-mdn], except for the added convenience of skipping this unwanted property.

Babel 6.x brings a number of substantial changes that have a cascading effect on some of our _other_ dependencies. Essentially, Babel was carved up into many different smaller and more focused libraries in 6.0. This required us to explicitly [pull in separate libraries for ES6, React, and command-line support][package.json-babel-updates] with Babel. The "main" Babel library - babel-core - doesn't perform ES6, ES7, or React compilation tasks anymore. Our [WebPack configuration for the Babel loader also changed][webpack-babel-updates] slightly as a result.


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

Before we go any further, we should make sure our changes haven't broken anything, but before we do that, let's make one additional adjustment. Going forward, it may be beneficial for us to use our package.json file as a place to execute any scripts needed to build, test, and run our application. The usefulness of this approach will become clearer as this exercise progresses. We'll start by defining a second target in the package.json `"scripts"` object, one that will startup our server. After this addition, the bottom of [our original package.json file][package.json-v1] now looks like this:

```javascript
"scripts": {
  "start": "node server",
  "webpack": "webpack --config config/webpack.config.js"
}
```

There are two changes to this section of the file. First, a new `"start"` tasks has been added, which starts up our NodeJS server. You can simple run `npm start` to execute this step. Second, our `"webpack"` target has been adjusted to include a reference to the new location of our webpack configuration file. Previously, this file was located in the root of our project, and, by convention, webpack looks for a file named "webpack.config.js" in the root of the project. Since we've moved this to the config directory, we must now let webpack know where this configuration file exists.

### Getting familiar with our testing tools

Our client-side unit tests will be created with the help of a few important and useful tools:

1. [Jasmine][jasmine]
2. [PhantomJS][phantomjs]
3. [Rewire][rewire]
4. [Karma][karma]

Jasmine is a JavaScript library we will use to write our unit tests. It includes a rich [set of assertions][jasmine-matchers] for comparing actual values under test with expected values, a full-featured [mocking engine][jasmine-spies] that will allow us to more easily focus on the component under test, as well as a number of other helpers that we will use to [group our tests][jasmine-describe] and [test asynchronous behaviors][jasmine-async].

PhantomJS is a headless version of [Webkit][webkit], the rendering engine currently used in Apple's Safari browser and formerly used in Google's Chrome browser (before it was forked as [Blink][blink]). Running our unit tests in a headless browser makes them easy and quick to run, not to mention portable. The entire browser is distributed and contained in a JavaScript package downloaded from npm. Using a conventional browser for unit tests in a development environment can be jarring with browser windows opening and closing, especially if tests are automatically re-run as soon as any code changes are saved.

Rewire is a Node.js tool primarily used (at least in this project) to mock out sub-modules imported by a module under test. For example, when testing our `<NameManager/>` component, we need to be able to control the behavior of its internal dependencies - `<NameList/>` and `<NameAdder/>`. We can use Rewire to gain access to these dependencies inside of `<NameManager/>` and replace them with dummy modules with inputs and outputs that we can monitor and control in order to more reliably test _this_ component. Rewire allows us to access internal dependencies in this way by using its own module loader to insert hooks into modules that allow them to be unnaturally accessed and controlled in a testing environment. For our browser-based unit tests, we'll need to use a Babel plug-in that wraps the Rewire plugin. It is aptly named [babel-plugin-rewire][rewire-babel]. We must use this Babel plug-in instead of the native Rewire library due to [Babel's unique ECMAScript 6 module transpilation logic][rewire-babel-bug].

Karma is a test runner and reporter, initially developed by Google for use with AngularJS unit tests. Fun fact: it was originally known as [Testacular][testacular]. It's hard to imagine why they changed the name, but I digress. Before we can begin writing tests, we must first configure Karma and tie all of our testing and reporting tools together. Remember that karma is our client-side test _runner_. In other words, it will use use Jasmine to execute the tests we are going to write, and it will provision a PhantomJS instance as an environment in which the tests will run. It will report the results using a karma plugin: karma-spec-reporter. A plug-in will allow Karma to use Webpack to generate a temporary source bundle that includes all of the code we intend to test. Our existing webpack.config.js file will be used here to determine how this bundle is generated. But we will contribute an addition Babel plug-in to our Webpack configuration just for these tests - babel-plugin-rewire - which will hook into the bundle generation process and add hooks into our code that we will need to mock out dependencies internal to each of the React components we intend to test.

Our Karma configuration will be named karma.conf.js, and it will be appropriately located inside of our new "config" directory. The completed file will look like this:

```javascript
var webpackConfig = require('./webpack.config')
webpackConfig.module.loaders[0].query = {plugins: ['babel-plugin-rewire']}

module.exports = function (config) {
    config.set({
        basePath: '../',
        browsers: ['PhantomJS'],
        files: ['app/test/tests.bundle.js'],
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

The `<NameManager />` glues the `<NamesList />` and `<NameAdder />` component together. When testing it, we need to be sure that it does its job as a workflow conductor. That is, when a name is added, the `<NameManager />` must notify the `<NamesList />`, so the list can update with the new names according to the server. We don't want to test the implementation of `<NamesList />` or `<NameAdder />`, so we will have to mock both of these out. In fact, as you can see below, most of the code in this test is dedicated to mocking components. Our test, as expected, lives in app/test/name-manager.spec.jsx

```javascript
var React = require('react'),
    TestUtils = require('react/lib/ReactTestUtils'),
    NameManager = require('../name-manager.jsx')

describe('NameManager', () => {
    it('updates NamesList when new name is added', (done) => {
        class NameAdder extends React.Component {
            triggerOnAdded() {
                this.props.onAdded()
            }
            render() {return <div/>}
        }
        NameManager.__Rewire__('NameAdder', NameAdder)

        NameManager.__Rewire__('NamesList', class extends React.Component {
            update() {
                done()
            }
            render() {return <div/>}
        })

        var nameManager = TestUtils.renderIntoDocument(<NameManager/>)
        TestUtils.findRenderedComponentWithType(nameManager, NameAdder).triggerOnAdded()
    })
})
```

In this test, the instance of NameAdder imported internally by NameManager is replaced with a simple class that invokes the `onAdded()` callback passed into the component by NamesManager when the `triggerOnAdded()` class method is called. And NamesList is replaced with a trivial class that completes the test when the `update()` method is called. The workflow is: a name is added using NameAdder, resulting in a call to the `onAdded()` function passed to NameAdder. That function results in an update of NamesList via invocation of the `update()` method. After rendering `<NameManager />` we simply call `triggerOnAdded` on the child `<NameAdder />` component. If everything is working correctly, the last call will be on the `<NamesList />` component's `update()` method, which will complete and pass the test. One new thing about this test is our use of the `findRenderedComponentWithType` method on `TestUtils`. This allows us to located a specific type of composite component inside another composite component. In this case, we are looking for the `<NameAdder />` component. There are no `expect` blocks here, no assertions, but the test will timeout and fail if the `update()` method is not called on NamesList.


And that's it, now we have tests for _all_ of our React components!


### Running our tests
Now that we have all of our React components covered with unit tests, it would be nice to be able to actually _run_ them to verify that everything is working as expected. To make this easy, let's add a `test` entry to the `scripts` property in our package.json file. This will allow us to execute our full suite of tests simply by running `npm test`. This new script looks like this:

```javascript
"scripts": {
  "test": "karma start config/karma.conf.js",
}
```

This will use the `karma` binary installed in node_modules/karma to run our Jasmine tests. It's pretty simple to do this via the command-line, and everything works as expected simply by issuing the `start` command and pointing Karma at the configuration file we created earlier. When you run `npm test`, all test should pass, and you'll see this in your terminal:

```
NameAdder
  ✓ saves new messages

NameManager
  ✓ updates NamesList when new name is added

NamesList
  ✓ renders with some initial data

PhantomJS 2.1.1 (Mac OS X 0.0.0): Executed 3 of 3 SUCCESS (0.007 secs / 0.021 secs)
TOTAL: 3 SUCCESS
```

On to the server!


## Part 2: Server-side unit tests
On the server, most of our code is focused primarily at handling Falcor requests. In order to service these, we have defined three primary routes:

1. A "get" route that returns the number of names.
2. Another "get" route that returns one or more names.
3. A "call" route that adds a new name.

In this section, you'll see unit tests that verify the expected behavior of each Falcor route. In order to more easily verify the logic in these routes, we'll rely on the Rewire library to mock out our "names" data store in order to provide canned values for our tests.


### Neatness counts - file reorganization & refactoring
In order to make our source easier to browse _and_ test, some changes are necessary. First, we'll split the original server.js file/module into three modules: one to hold our names data, another for housing our Falcor routes, and then a third that directly handles requests from our frontend and deals with all of the other generic server tasks.

We'll start by moving the [`data` variable in the original server.js file][data-server-v1] into a new names.js file, which will look like this:

```javascript
module.exports = [
    {name: 'a'},
    {name: 'b'},
    {name: 'c'}
]
```

Separating this into its own module makes it trivial for us to substitute this data store for a mocked version in our server unit tests.

Next, we'll move our [Falcor routes from server.js][routes-server-v1], along with most Falcor-related dependencies, into a router.js file:

```javascript
var Router = require('falcor-router'),
    names = require('./names'),
    NamesRouter = Router.createClass([
        {
            route: 'names[{integers:nameIndexes}]["name"]',
            get: (pathSet) => {
                var results = [];
                pathSet.nameIndexes.forEach(nameIndex => {
                    if (names.length > nameIndex) {
                        results.push({
                            path: ['names', nameIndex, 'name'],
                            value: names[nameIndex].name
                        })
                    }
                })
                return results
            }
        },
        ...
    ])

module.exports = NamesRouter
```

This separation allows us to focus specifically on testing Falcor routes without having to deal with any of the generic server logic that is unimportant to our unit tests.

All of these changes to promote testable code leaves our original server.js file much smaller and only focused on traditional server tasks, such as routing HTTP requests, serving up static resources (such as our WebPack-generated JavaScript bundles), and starting up the server. Here it is, for reference:

```javascript
var FalcorServer = require('falcor-express'),
    bodyParser = require('body-parser'),
    express = require('express'),
    app = express(),
    NamesRouter = require('./router')

app.use(bodyParser.urlencoded({extended: false}));
app.use('/model.json', FalcorServer.dataSourceRoute(() => new NamesRouter()))
app.use(express.static('site'))
app.listen(9090, err => {
    if (err) {
        console.error(err)
        return
    }
    console.log('navigate to http://localhost:9090')
});
```

So now it's easier to test our code since each file/module is focused on a specific task, but we have 2 extra files cluttering up the root of our project. Let's move those into a new subdirectory, appropriately named "server". With this change, our project's structure seems a bit more sane and predictable. Here's the tree at this point:

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
+-- server
|   +-- names.js
|   +-- router.js
|   +-- server.js
+-- site
|   +-- index.html
+-- package.json
```

Don't forget to change the `start` script in package.json! It should reflect the new path of the server entry point:

```javascript
"scripts": {
  "start": "node server/server",
}
```


### Understanding our server-side testing tools
One of the goals of this full-stack JavaScript approach is to blend the frontend and backend together as much as possible. By utilizing the same language across the entire app, we get the benefit of also using the same tools for testing. This is particularly noticeable when we look at the unit testing structure for our server. Our toolset is a subset of the same tools used to write and run unit tests for our frontend. On the backend, we'll write our tests using the familiar Jasmine library. Mocking out internal dependencies, such as our data store, will again be accomplished using Rewire. While we used Karma to run our frontend Jasmine tests, we can simply use Jasmine's Node.JS binary to run our server unit tests.


### Configuring Jasmine to run our tests
The Jasmine test runner, which will be used to execute our Jasmine server-side unit tests, needs a bit of configuration in order to do its job. We'll store this configuration, which is quite minimal, in a JSON file inside of our configuration directory, alongside the existing Karma and WebPack configuration files. This Jasmine config revolves around two properties, `"spec_dir"` and `"spec_files"`:

```javascript
{
  "spec_dir": "server/test",
  "spec_files": ["**/*[sS]pec.js"]
}
```

"spec" is short for specification. Each set of similar tests are grouped into specifications, and this configuration file tells Jasmine a bit about the specification we're about to write. `"spec_dir"` is the directory that holds all of our server-side specifications. Those will eventually live in the "test" subdirectory, inside of the "server" directory. This structure mirrors the setup of our client-side "app" directory. `"spec_files"` is an array that helps Jasmine find the actual specifications to run inside of our `"spec_dir"`. Our configuration contains one entry - a regular expression that will match any file inside this directory (or any of its children) that ends with ".spec.js". So all of our specification files must adhere to this format, and if we do, Jasmine will magically run all defined tests and report the results.


### Unit testing our Falcor routes

All of our server-side unit tests, which will exercise the three primary Falcor routes defined in server/router.js, will live inside of server/test/router.spec.js. Again, these will be Jasmine tests, which I previously demonstrated in the previous section where we wrote unit tests for our 3 primary React components.

Before I discuss the setup for these unit tests, lets take a look at the relevant code first:

```javascript
describe('falcor router tests', () => {
    var rewire = require('rewire'),
        Router = rewire('../router'),
        namesRouter

    beforeEach(() => {
        Router.__set__('names', [
            {name: 'uno'},
            {name: 'dos'},
            {name: 'tres'}
        ])
        namesRouter = new Router()
    })
})
```

The above code doesn't actually _test_ anything, but it is crucial for the tests we are _about_ to write. Each of these three unit tests will require us to work with some predictable set of data. In order to ensure this, we'll need to mock out our data store and explicitly specify the data we want to test against. Using Rewire, we can reach inside of the router.js module and replace the imported `names` data store instance with our own set of data. This modified instance of the Falcor router is then made available to all of our upcoming unit tests.

Our first unit test will examine the route that returns the number of names in the list. Remember our mocked data store contains exactly 3 names, so this is the result we are looking for in our test:

```javascript
it('gets the number of names', (done) => {
    namesRouter.get([['names', 'length']]).
    subscribeOnNext(response => {
        expect(response).toEqual({
            jsonGraph: {
                names: {
                    length: 3
                }
            }
        })
        done()
    })
})
```

Quite simply, we're calling the `names.lenth` route on our Falcor router, and this returns [an RxJS `Observable`][observable-rxjs]. The [`subscribeOnNext` method][observable-subscribeonnext] will execute our passed callback with the "response" generated by our code for this route. We're expecting the result to be described in terms of a [JSON Graph][json-graph] that contains a `names.length` property with the number of names in the server-maintained list. This test (and all other server-side tests we will write) is asynchronous. To prevent Jasmine from completing the test before we've verified the condition in our callback, we ask Jasmine to pass a `done` function into our test which we invoke once our test is [_done_ done][donedone-jar].

Our next test verifies that our names route returns the requested names in the list. We'll ask for the first two names in our mock data store, "uno" and "dos", and then verify that our route actually returns these items:

```javascript
it('gets a list of names by index range', (done) => {
    namesRouter.get([['names', {'from': 0, 'to': 1}, 'name']]).
    subscribeOnNext(response => {
        expect(response).toEqual({
            jsonGraph: {
                names: {
                    0: {name: 'uno'},
                    1: {name: 'dos'}
                }
            }
        })
        done()
    })
})
```

This is very similar to the `names.length` route test, with the exception of the additional parameter specifying the range of names.

This last test will add a new name - "cuatro" - using the `names.add` "call" route. It will verify the response to this "call", and then use the names "get" route to verify that this new name is available at index 3 in our names list:

```javascript
it('adds a new name', (done) => {
    namesRouter.call(['names', 'add'], ['cuatro'], ['name']).
    subscribeOnNext((response) => {
        expect(response).toEqual({
            jsonGraph: {
                names: {
                    3: {name: 'cuatro'},
                    length: 4
                }
            },
            paths: [['names', 'length'], ['names', 3, 'name']]
        })

        namesRouter.get([['names', [3], 'name']]).
        subscribeOnNext(response => {
            expect(response).toEqual({
                jsonGraph: {
                    names: {
                        3: {name: 'cuatro'}
                    }
                }
            })
            done()
        })
    })
})
```

Verifying the response to the "call" involves ensuring the changes to our store are reported. We're also examining the `path` property in the response, which describes what specific elements of the JSON graph have changed as a result of this "call". The last part of this third test is more of a sanity check. By checking the response of a call to our names "get" route with the index of the new name, we're making absolutely sure that this new name has indeed been added. Arguably, checking the response to the "call" is all that is really needed.


### Running our tests
We are now accustomed to using npm to perform various operations on our application, such as running unit tests. Carrying forward this pattern, let's provide a way to run our server-side tests via npm. In fact, let's modify our package.json scripts so that we can execute both our frontend _and_ backend tests with a single command. The relevant portions of our package.json now look like this:

```javascript
"scripts": {
  "test-client": "karma start config/karma.conf.js",
  "test-server": "jasmine JASMINE_CONFIG_PATH=config/jasmine.json",
  "test": "npm run test-client; npm run test-server"
}
```

You can see two _new_ `"scripts"` entries above: `"test-client"` and `"test-server"`. The old `"test"` entry was moved over to a more specific `"test-client"` entry, and a new `"test-server"` entry was created to handle execution of the server tests that we just wrote. The `"test"` entry has been modified to run both the `"test-client"` and `"test-server"` scripts. Now, when we run `npm test`, our terminal contains output that shows three successful frontend unit tests _and_ three successful backend tests:

```
NameAdder
  ✓ saves new messages

NameManager
  ✓ updates NamesList when new name is added

NamesList
  ✓ renders with some initial data

PhantomJS 2.1.1 (Mac OS X 0.0.0): Executed 3 of 3 SUCCESS (0.006 secs / 0.023 secs)

TOTAL: 3 SUCCESS


> fullstack-react@2.0.0 test-server /Users/rnicholus/code/fullstack-react
> jasmine JASMINE_CONFIG_PATH=config/jasmine.json

Started
...
```

The three dots at the end of the test (which are green in a terminal) represent the success of our three new unit tests. There are ways to provide more verbose reports for our server-side tests, but this is sufficient for now. Note that failures _will_ include relevant information in the console regarding the failure.

And that's it! Now we have all frontend and backend code covered by unit tests, along with a simple way to run these tests.


## Part 3: Integration testing

Unit tests have been throughly covered by now, so let's move on to "integration" testing. These tests will examine how our application functions when a realistic user-generated operation is performed. In contrast to unit tests, integration tests exercise the _entire_ application, so we will need to have a running server in order to run these tests. We'll need to write code that will open up a browser, load our application, and then perform one or more common tasks.


### Tools to help us write and run our tests

Just like out client-side and sever-side unit tests, we'll again use Jasmine to write our integration tests. Furthermore, Jasmine will _run_ these tests as well, just as it runs our server tests. But integration tests are a bit more complex than unit tests, so we need some more help writing and running them. We'll enlist [WebdriverIO][webdriverio] to make this as easy as possible. WebdriverIO provides an easy to use JavaScript API on top of Selenium Webdriver's wire protocol, which allows us to control and query any browser programmatically. But [wire protocol is low-level and not particularly pleasant to work with][webdriver-w3c]. WebdriverIO "fixes" this for us, and allows us to complete our mission to write and test a web application using nothing but JavaScript.


### Writing a simple but useful test
To illustrate the role and structure of a typical Webdriver-dependant integration test using WebdriverIO, let's create a single simple but incredibly useful test that will ensure a user is able to successfully add a new name.

Before we get into actually writing any code, let's outline exactly how this test should be structured. Let's also assume that our server is already running:

1. Navigate to our app in a browser.
2. Determine how many names exist in the list initially (by counting list item elements).
3. "Type" a value into the text input at the bottom of the page.
4. Click the "add name" button.
5. Ensure the number of names in our list has increased by  exactly 1 and it contains the value we entered into the text input.
6. End test/close browser.

That's it - six simple steps. And WebdriverIO provides an elegant API that will allow us to follow this formula _and_ write code that is mostly self-documenting. This test will live among the other server-side tests - in server/test - and will be named "integration.spec.js". This will allow it to be automatically executed by Jasmine along with the server unit tests. Let's have a look at the code:

```javascript
var webdriverio = require('webdriverio')

describe('name adder integration tests', () => {
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000

    beforeEach(() => {
        this.browser = webdriverio.remote().init()
    })

    it ('adds a name', done => {
        var date = Date.now(),
            nameCount

        this.browser.url('http://localhost:9090')
            .waitForExist('li', 30000)
            .elements('li').then(elements => nameCount = elements.value.length)
            .setValue('input', date)
            .getValue('input').then(value => expect(parseInt(value)).toBe(date))
            .click('button')
            .waitForExist(`li=${date}`, 5000)
            .elements('li').then(elements => expect(elements.value.length).toBe(nameCount+1))
            .end()
            .call(done)
    })
})
```

The format of this specification is familiar, since we're again using Jasmine. Notice the "webdriverio" import at the top of the file, and initialization code inside of `beforeEach`. This produces a `browser` object which exposes a set of methods to control the browser. We've also set a longer-than-normal timeout for our tests. This isn't really important now, but it may be later when we attempt to run these tests against virtualized browsers in the cloud in the next section.

The test outlined earlier is represented by a series of chained method calls inside of the "adds a name" test. Starting with `this.browser.url(...)`, here is a line-by-line breakdown of our integration test:

1. Open Firefox (by default) and navigate to the index page of our app.
2. Wait for a `<li>` to exist on the page (this will represent the first initial name in our list). If this is not visible within 30 seconds, the test will fail. Again, for testing against a local browser, this long of a timeout is probably unnecessary, but this may be important in the next section.
3. Find all `<li>` elements, count them, and set this number to be the value of the `nameCount` variable. This is the number of names on page load.
4. Set the value of the `<input type="text">` at the bottom of the page to the current time in milliseconds.
5. Make sure this text input reflects the value we just entered.
6. Click the "add name" button next to the input.
7. Wait up to 5 seconds for a `<li>` element to appear on the page with text that equals the value we just submitted. This is the first check to ensure our newly added name exists on the page after a submit.
8. Count the number of `<li>` elements on the page again. Remember that each name is housed in a separate `<li>`, so there should be one more than our last check.
9. Close the browser.
10. Signal to Jasmine that the test is complete.


### Running our test locally
By default, without providing _any_ configuration options to WebdriverIO, our test will run against Firefox. So, before running this locally, be sure you have Firefox installed. We'll also need to run a Selenium server locally. WebdriverIO actually drives the browser _through_ this Selenium server. Downloading, installing, and running this server is _much_ easier than it sounds. In order to run the server, you'll need a Java Runtime Environment (JRE) installed on your machine as well. Most machines already have this installed, so you probably don't have to worry about this.

In order to make it as easy as possible to setup/startup our Selenium server and run our integration tests, we'll need to add two more `"scripts"` to our package.json file:

```javascript
"scripts": {
  "setup-webdriver": "(mkdir server/test/bin; cd server/test/bin; curl -O http://selenium-release.storage.googleapis.com/2.51/selenium-server-standalone-2.51.0.jar server/test)",
  "start-webdriver": "java -jar server/test/bin/selenium-server-standalone-2.51.0.jar",
}
```

The above represents only the _new_ entries in package.json. The first new script - `"setup-webdriver"` - creates and enters a "bin" directory inside of server/test/, and then downloads the Selenium server binary (which is a Java jar) into that directory. This first new script only needs to be run _once_. The second new script - `"start-webdriver"` - will, as you might expect, start this newly installed Selenium server using the JRE I mentioned earlier.

So, now we have a running Selenium server. How can we actually execute this new integration test? Simple! Just run `npm test`. Since our specification file ends with ".spec.js" all we have to do is ensure it is placed inside the server/test directory, and the Jasmine configuration we create in the previous section will ensure it is run as part of our server-side tests. Go ahead and run the test. You'll notice that Firefox opens automatically and the steps outlined above are executed before your eyes (and very quickly). Once the browser closes, results are printed to the console. If all goes well, our three green server-side test dots in the terminal will be joined by a fourth dot representing the successful run of our integration test.


## Part 4: Full Test Automation With Travis CI and BrowserStack
Running the unit and integration tests locally is important and convenient, but we need to be able to verify our code on a location other than our own development machine. It can be surprising just how many new issues surface when you leave the comfort of your own "perfect" environment. Relying on a trusted 3rd party entity to run tests is also a critical part of the continuous integration process. If you have a known third-party service verify your build, like Travis CI, _and_ you are using GitHub to manage your project, you can create "safe" branches using [GitHub's branch protection feature][github-branch-protection]. When enabled, this will prevent any code from a branch with failing tests (or with untested code) from being merged into the protected branch.

In this section, I'll show you how to configure a cloud-based continuous integration service to run your build and all of your tests on each push to GitHub. Furthermore, I'll show how you can also run your integration tests against _any_ browser on _any_ device/OS using a _second_ cloud service. Both of these useful services will work together to provide you with an elegant and efficient continuos integration environment.


### Getting familiar with our CI tools
[Travis CI][travis] is a popular continuous integration service that allows you to perform various project related tasks (such as running your build and tests) on a virtualized Ubuntu machine (or OSX for Objective-C projects). Travis is free for public/OSS projects. For private projects, Travis provides access to additional features, such as resource caching and private builds, for a fee. Since the repository that holds our code is public and open source, we'll make use of Travis' free tier to run our unit and integration tests on every push to GitHub. Travis integrates nicely into GitHub, and even works with the branch protection feature I mentioned earlier.

While Travis can run our unit tests in both PhantomJS and a "headless" Firefox, it cannot run our integration tests. These require a non-headless browser, and potentially access to something other than Linux. Ideally, Travis would still control the build and tests, but delegate to another service to run integration tests on a specific browser/OS combination, reporting back the results along with all unit tests. By integrating BrowserStack into our CI environment, this is entirely achievable. [BrowserStack][browserstack] is a "cloud" service that provides programmatic (and manual) access to any browser on any conceivable operating system. It does this via an API (for programmatic access) and a web interface (for manual access). The most common use for BrowserStack is to facilitate automated cross-browser execution of integration tests. Like Travis, BrowserStack also provides free access to their virtualized machines for open source projects, with various plans offered to private/commercial projects.


### Running our unit tests on every push with Travis CI
The steps required to get our unit tests running on Travis with every push to GitHub are as follows:

1. Setup Travis account.
2. Make Travis aware of our project.
3. Create a configuration file detailing our build requirements.
4. Commit and push the build file up to GitHub.
5. Profit.

#### Setting up a Travis CI account
Signing up is as easy as clicking the "Sign Up" button on https://travis-ci.org. As I mentioned earlier, Travis integrates almost seamlessly with GitHub, so much so that you can sign into to Travis using your GitHub account.

#### Connecting the GitHub repository to Travis
Once logged in, visit your profile page. There, you'll see a list of all public repositories in your account. To connect the Widen/fullstack-react repository to Travis (which holds the code for our names app), I visited _my_ account page in Travis, found the GitHub repo in the list of my projects, and clicked on the slider to "activate" the project. It should look something like this:

<img src="{{base}}/images/travis-activate-repo.png" width="400" />

#### Creating a config file to control the project build & triggering a build
All of the configuration for our Travis build must be located in a file named `.travis.yml` in the root of our project. [YAML][yaml-spec] is a type of "data serialization format", much like JSON and XML. It is unusually human-readable, as you can see by looking at the Travis config file for Widen/fullstack-react:

```yaml
language: node_js
node_js:
- '5.0'
```

As you can see above, the configuration is _very_ minimal. All we really need to do is tell Travis that this is a JavaScript project (via the `language` property) and specify the version of Node.JS to install on the environment. Travis CI allows for a number of language-specific conventions to reduce configuration boilerplate. For example, by default, Travis will run `npm install` and `npm test` on any Node.JS projects. Since we have already defined a `"test"` script in our package.json file, we only need to tell Travis that this is indeed a Node.JS project, and it takes care of pulling down dependencies and running our tests automagically.

So, to start your first build on Travis, simply commit the above `.travis.yml` file and push it up to GitHub. Take a look at [a Travis build log][travis-temp-log] for Widen/fullstack-react hat matches this very configuration. Note that I had to temporarily change the name of the integration.spec.js file to integration.spec.bak.js. This ensures it is _not_ seen by Jasmine and not executed. We're not quite ready to run integration tests _yet_.


### Adding integration tests to the mix with BrowserStack
Now that we have Travis running our frontend and backend unit tests, it's time to add integration tests to the mix. For this, as described earlier, we need to enlist the help of BrowserStack. The steps required to enable Travis to run our integration test with BrowserStack, alongside our unit tests "locally" using PhantomJS, are as follows:

1. Setup a BrowserStack account
2. Update our Travis config file with BrowserStack-related logic and authentication data
3. Provide some configuration data for our integration test that will allow it to execute the test in browsers of our choosing.
4. Push our changes up to GitHub and watch the build log on Travis.

#### Setting up a BrowserStack account
You can start using BrowserStack for free, regardless of the status of your project. For open-source projects, contact BrowserStack for free permanent access to one of the paid plans. This is exactly how I procured a free account for Widen/fullstack-react. After you create an account via their web interface, navigate to your account settings and make a note of your username and access key. You will need both of these when establishing configuration next.

#### Configuring Travis and BrowserStack to run our integration test
There are 5 steps required to create the necessary configuration and start running the integration test on Travis:

1. Update the Travis config to start our app server
2. Download and run the BrowserStack tunnel. This will the machine running on BrowserStack to see our running app instance on Travis.
3. Specify a list of operating systems and browsers to test against.
4. Include encrypted authentication information for our test & tunnel.
5. Update our integration test to run against the browsers we chose in step 4.

Let's look at the updated Travis config file first:

```yaml
language: node_js
node_js:
- '5.0'
before_script:
- npm start &
- wget http://www.browserstack.com/browserstack-local/BrowserStackLocal-linux-x64.zip
- unzip BrowserStackLocal-linux-x64.zip
- ./BrowserStackLocal $BROWSERSTACK_KEY &
- sleep 10
env:
  global:
  - secure: IKsVq7xmRs/1pJZ/pB3tbOITtbtcBFlBh3IIuhGkh72y0v8PTFfP/r/zlT/Gq5seAIaXN+YnbDPA61qroxGAGJdrsAB0xVae+AWRmBbHV64mq4g3kkj4RJPjv/2rAsTHEBpXPpmHdpjEDFIEqwTKWehZpJZAjLFoRS7LV5ucRc2LBNpfP3J83AJWn3KpBVnw5SBcwUbY8O8vKcaaYyfeorjMXqZ84Rw9jlDyhR8HJmRrvA/FVadg2lpzabFmQ5gBkLFzxEKghvIRkAJDQ1LMjYBmA6aogiJZoH90InRb6ub4KUrrmnYdbn0ug8YxDYXDa34fsBBnipUAYwSnwGujJmHHQ3rbcS12/S+cs75uFowBLP2ej6toznyUIwhfMX9rBFY6salo3jW3Qj7Qyy+68C3aqPLkJLCEgFHN2dGLR4BEoguycxSDoeIc5vj6j3c8uH/pP1Vp1jIRuaDglfyraIiwcZL5l4zznlnaqCOvTG6hJKZHgz1MCxaaCQjCdsKtMjFnmz8aocxmJbW+0BazAhEbbPvUsagKrq0K91bmXKWaplvuo1jhqWOIlkW3L6eNX5880or+BergkjXufnZFLm6soaBdP1/aRN1fBgDPRuPcEh+gHbiSa3A1Y3Fsrx+eAz8mnkyqoXlAvQTPq8XBkIoUyoYWtzWpDp3CAVPGJmg=
  - secure: RyXfo5jJrjlcedkk2k5ceT7KeuqdXaqRzREHMFI/FIJy/dkIpFQ2mD/HVF/SO7V/8hcsfA4TBIPb7Qlitl+5NZEgo3TlNpoxML9+jMrzBEnSafiqu1lJrg4z3+D4TtfjTi2ccI9wqhUeYiuPWmdFBgsqgRvFxMgbDLC0KJipsk12PYKCMzV+2+INBxx6SulBlPWS8RMMQeD0kY9JBMyxabZ5E3LtA9ALDedSW/C4qj6H4bchTSU1Vh7UcMOrCypfKGNv4halfoSfgIzZuSpWsnKGMz0RXiPwfUI9UHymA9vwToIzBgk+ZFlRqzIF69ex6llKTMgJARyat5xGmbLFN12u8YhAMde8SxSArNL4s5x1WUFK04OzagYEzPVRniJYK3pEVI0SGQPwWo6l85JUGT0iT4abn4MQRNwVhtHhqv55tMoJ7DlRujoKCa7bqQh/Okqw294Y/mFWMz6pENlT1p4JU5wERdL3Dtf2kHIpBMqRiEP/stHvkKcsRpUugW+4EbZDGyhVEOUnPUM4ZK/SvEqvg3foOSQdnBzrrc46KhBQ2Rh3l0Qyc/sOLXk/LrGmfKINU2wbNZqcpMRY5bjoEpAxRoEWO+mn+Cpfl8JRIfwN6VN88lHVGOvNlOjcdmo0wNhifDFSpTItIvpDZNW93zaIfZacBt0X2R7oqbiApXE=
  matrix:
  - BROWSER: Firefox
    PLATFORM: Win8
    VERSION: 41
  - BROWSER: Chrome
    PLATFORM: Win8
    VERSION: 46
  - BROWSER: Safari
    PLATFORM: Mac
    VERSION: 9
```

We've add a number of new items to the configuration. The `before_script` block will be executed after `npm install` but before `npm test`. Here, is a line-by-line breakdown of that configurarion block:

1. Start our application server in a separate process (to prevent it from blocking the rest of the build).
2. Download the BrowserStack tunnel binary.
3. Unzip the tunnel binary.
4. Start the tunnel in a separate process (to prevent it from blocking the rest of the build)
5. Wait 10 seconds for the tunnel to start.

Notice that we are passing an environment variable - `BROWSERSTACK_KEY` - to the tunnel on startup. This is our secret API key, but where is this variable coming from? If you look further down at the `env` section of the configuration, you'll see a couple `secure` items. These contain our username (`BROWSERSTACK_USERNAME`) and BrowserStack API (`BROWSERSTACK_KEY`) key. They have been encrypted and added to our config file. Travis' documentation site contains [a section that explains how to create and store these encrypted variables][travis-secure-variables].

The final portion of the `env` configuration block contains a series of `matrix` entries. As you can see, these correspond to browser/OS environments that we'd like to test. For each matrix entry, Travis runs a separate virtualized machine, and makes each matrix property (`BROWSER`, `PLATFORM`, and `VERSION`) available to as environment variables.

Our last step, before we are able to run our integration tests alongside the unit tests in Travis, is to make a few changes to server/test/integration.spec.js. All we really need to do is pass some configuration to WebdriverIO that allows it to connect to BrowserStack instead of a locally running Selenium server. This configuration will also pass browser and OS information to BrowserStack so it can provision the appropriate environment. That specific information is already defined in our Travis config file. We only need to change the first portion of our integration test module, which now looks like this:

```javascript
var webdriverio = require('webdriverio'),
    options = {}

if (process.env.CI) {
    options = {
        desiredCapabilities: {
            browserName: process.env.BROWSER,
            version: process.env.VERSION,
            platform: process.env.PLATFORM,
            "browserstack.local": true
        },
        host: 'hub.browserstack.com',
        port: 80,
        user: process.env.BROWSERSTACK_USERNAME,
        key: process.env.BROWSERSTACK_KEY
    }
}

describe('name adder integration tests', () => {
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000

    beforeEach(() => {
        this.browser = webdriverio.remote(options).init()
    })

    /* existing test here... */
})
```

As you can see, the configuration we've added grabs the browser, OS, version and BrowserStack-related auth info provided as environment variables in our Travis config. This data is then passed to WebdriverIO as a JavaScript object. I've added a check to _only_ provide this new configuration data if the code is running on Travis. We can easily detect this by looking for a `CI` environment variable, which Travis sets for us. If our test is _not_ running on Travis, it will attempt to connect to a locally-running Selenium server, as before.

Simply commit these changes, push them up to GitHub, and you will see unit and integration tests run on Travis. Take a look at [a recent build on Travis of Widen/fullstack-react][travis-passing-build] that illustrates the finished product.

## Going further
- handle empty list of names in code and back it with a unit test for names-list
- move integration test config to a file in config dir
- better reporting of failed tests all around


[blink]: http://www.chromium.org/blink
[browserstack]: https://www.browserstack.com/
[data-server-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/server.js#L6
[donedone-jar]: http://images.wisegeek.com/hand-putting-money-in-coin.jpg
[falcor-code-updates]: https://github.com/Widen/fullstack-react/commit/ae683e31daa7993f06d9d452e64cde3b84bf1fde#diff-5545284dc279e8d0cac06a735ecc9f64R1
[falcor-model-deref]: http://netflix.github.io/falcor/doc/Model.html#deref
[falcor-path-change]: https://github.com/Netflix/falcor/issues/708
[github-branch-protection]: https://help.github.com/articles/about-protected-branches/
[jasmine]: http://jasmine.github.io/2.3/introduction.html
[jasmine-async]: http://jasmine.github.io/2.3/introduction.html#section-Asynchronous_Support
[jasmine-describe]: http://jasmine.github.io/2.3/introduction.html#section-Grouping_Related_Specs_with_<code>describe</code>
[jasmine-matchers]: http://jasmine.github.io/2.3/introduction.html#section-Matchers
[jasmine-spies]: http://jasmine.github.io/2.3/introduction.html#section-Spies
[json-graph]: http://netflix.github.io/falcor/documentation/jsongraph.html
[karma]: http://karma-runner.github.io/0.13/index.html
[object-keys-mdn]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/keys
[observable-rxjs]: https://github.com/Reactive-Extensions/RxJS/blob/master/doc/api/core/observable.md
[observable-subscribeonnext]: https://github.com/Reactive-Extensions/RxJS/blob/master/doc/api/core/operators/subscribeonnext.md
[package.json-babel-updates]: https://github.com/Widen/fullstack-react/commit/ae683e31daa7993f06d9d452e64cde3b84bf1fde#diff-b9cfc7f2cdf78a7f4b91a753d10865a2R19
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
[routes-server-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/server.js#L13
[scryRenderedDOMComponentsWithTag]: https://facebook.github.io/react/docs/test-utils.html#scryrendereddomcomponentswithtag
[server.js-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/server.js
[testacular]: http://googletesting.blogspot.com/2012/11/testacular-spectacular-test-runner-for.html
[testing-slides]: http://slides.com/raynicholus/automated-testing
[travis]: https://travis-ci.org/
[travis-passing-build]: https://travis-ci.org/Widen/fullstack-react/builds/108453063
[travis-secure-variables]: https://docs.travis-ci.com/user/environment-variables/#Encrypting-Variables-Using-a-Public-Key
[travis-temp-log]: https://travis-ci.org/Widen/fullstack-react/builds/108709902
[webdriver-w3c]: https://www.w3.org/TR/webdriver/
[webdriverio]: http://webdriver.io/
[webkit]: https://webkit.org/
[webpack-babel-updates]: https://github.com/Widen/fullstack-react/commit/ae683e31daa7993f06d9d452e64cde3b84bf1fde#diff-a58d55bdb5770c78ad512f8e91f8d051R6
[webpack.config.js-v1]: https://github.com/Widen/fullstack-react/blob/1.2.1/webpack.config.js
[whyscry-twitter]: https://twitter.com/angustweets/status/590659867926462465
[yaml-spec]: http://yaml.org/spec/
