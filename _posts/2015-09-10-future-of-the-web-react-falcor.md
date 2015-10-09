---
title:  The Future of Web Development - React, Falcor, and ES6
author: Ray Nicholus
categories: react falcor webpack web server JSON HTTP node.js JavaScript ES6
excerpt: "The future of web application development looks a bit different than what we are all used to. I'll show you how to build a simple full-stack JavaScript app using Node.js on the backend, React on the frontend, Webpack for client-side modules support, and Netflix's Falcor as an efficient and intuitive alternative to the traditional REST API."
---

In this article, I'm going provide a glimpse into the future of web development. You will gain a new perspective on structuring a user interface, server, and data endpoints. In other words, I will cover the full "stack" - both the browser and server code - and you will be able to examine and execute all of the referenced code in [a fully-functional GitHub repository][repo]. I must assume that you, as a developer, posses the following qualities:

1. Intermediate understanding of JavaScript.
2. Intermediate understanding of HTML.
3. Basic knowledge of client-server communication.
4. Basic knowledge of JSON.
5. Basic knowledge of node.js.

If you lack any of these qualities, you _may_ still be able to navigate this article and the related code, but these gaps in your knowledge will likely prevent you from extending my code to support a more realistic or non-trivial scenario. The internet is full of great resources that will provide you will the concepts necessary to master each of these items, and I encourage you to seek out resources as needed - they are only a quick Google search away.

The current stack at Widen often consists of Java on the server, AngularJS for all of our browser-related code, Jersey for REST API support, along with a whole host of various libraries such as jQuery, underscore, lodash, jQuery UI, and Bootstrap. When designing the underlying sample web application, which I will be discussing shortly, I had four specific goals in mind:

1. **A new and shiny approach**. Instead of developing yet another AngularJS-based UI, or deferring to jQuery, or creating a Java-based endpoint server using Jersey, or doing all three, I really wanted to make use of an entirely new set of tools. I hoped that this would allow me to gain a new perspective and help me to evolve a bit more as a developer.

2. **Simplicity** is another desire of mine. I very much have grown to dislike the substantial learning curve associated with AngularJS 1.x, and am disappointed to discover that the learning curve for v2 is even more steep. The same is true of Java, which I have traditionally used server-side. I'd like to avoid as much boilerplate code as possible and get my application up and running as quickly as possible without sacrificing scalability. Being able to easily describe my frontend as a collection of standalone focused components is also part of this goal. And traditional REST APIs are awkward to maintain and evolve. The frontend developers must coordinate with the backend developers to expose a set of API endpoints that properly support the browser-side representation of the model. As the needs of the UI change, this often requires the API to change as well. Surely there must be a better approach!

3. Some of the issues associated with a traditional REST API in terms of unnecessary request overhead and number of requests and response payloads, were a concern. I was less concerned about client-side rendering performance, which React and AngularJS both handle fairly well, though React is much more monolithic and complex, making it easier to unknowingly introduce serious performance issues into an app. So, **efficiency** is my fourth goal.

4. Finally, I was looking for some approaches or tools that allow me to write uncharacteristically **elegant** code. The code itself should be easy to follow. Looking up and changing data from the UI should be intuitive. Ideally I would like to think about my model, and only my model - not in terms of available API endpoints. I'd also like to avoid much of the noisy boilerplate that is required of my current stack.

In order to address each of these goals, I decided to replace my current lineup of tools with an _entirely_ new set, some of which I initially had never used before. This was very much a learning experience, one which I would like to share with you. Next, I'll document each notable new tool. After the stack is clear, I'll walk you though, from start to finish, creation of a simple web application that is both functional and idiomatic of all items involved in this new stack.


## A futuristic stack

A more traditional stack, at least in my experience, my consist of Angular and/or jQuery and/or backbone on the frontend, with Java handling requests on the backend via some form of a REST API, perhaps using Jersey. In this article, we're going to explore an entirely new stack, one that can be considered "futuristic", at least as of September 2015. In fact, some of Widen's new emerging software products will make use of all of the new technologies discussed here.

Adopting a completely new set of tools and architecture often means changing your perspective as a developer. Over time, we've all become comfortable with one or more tools. Whether that be jQuery or Angular, or Ember, or even the concept of REST, we have learned to trust and depend on our stack. We've been trained to think of web applications in a specific context though inculcation. Abadonding our stack and moving out of this comfort zone can be frustrating. Some of us may fight this urge, dismissing new choices as unnecessary or overly complex. Admittedly, I had the same thoughts about React, webpack, and Falcor before I had a strong understanding of these tools. In this section, I will briefly discuss each of the more notable tools in this futuristic stack. I'll be sure to provide resources for further investigation as well.

### React

React differs from Angular and Ember due to its limited scope and footprint. While Angular & Ember are positioned as frameworks, React mostly concerns itself with your "view". React contains no dependency injection or support for "services". There is no "jq-lite" (Angular) nor is their a required jQuery dependency (Ember). Instead of handlebars (Ember) you write your markup alongside your JavaScript using JSX, which compiles down into a series of JavaScript calls that build your document through React's element API as part of a "virtual DOM" that React maintains. It updates the "real" DOM from this virtual model in the most efficient way possible, avoiding unnecessary reflows/repaints, as well as delegating event handlers for you (among other things). If you embrace JSX (and from my experience, you should) you are adding a compilation phase to your project. For me, this was something I have tried to avoid for a while, but made my peace with this workflow after realizing how elegant and useful React through the lens of JSX really is. At this point, the floodgates opened up, and other useful JavaScript preprocessors, such as webpack and babel, were easy to embrace. More on those later.

In short, I really appreciate the relatively narrow focus of React. Dividing up a complex component into smaller widgets is something I came to love with Angular. I was excited at the possibility of native support in the form of the Web Components spec, but ultimately chose React for its elegance, ease-of-use, small footprint, and relative maturity.


### Falcor

Falcor, a _very_ new library created and open-sourced by Netflix, is a complete departure from the traditional REST API. Instead of focusing on specific endpoints that return a rigid and predetermined set of data, there is only _one_ endpoint. This is how Falcor is commonly described, and it is maybe a bit misleading, though technically correct. Instead of focusing on various server endpoints to retrieve and update your model data, you instead "ask" your API server for specific model data. Do you need the first 3 user names in your customer list along with their ages? Simply "ask" your API server, in a single request, for this specific data. What if you want only the first 2 user names and no ages? Again, a single request to the same endopint. The differences in these two GET requests can be seen by examining their query parameters, which contain specifics regarding the model properties of interest. Server-side, a handler for a particular combination or pattern of model properties is codified as part of a "route". When handling the API request, the falcor router (server-side) contacts the proper router function based on the items present in the query string.

Falcor promotes a more intuitive API that _is_ your model. It also ensures that extra, unnecessary model data is never returned, saving bandwidth. Furthermore, requests from multiple disparate browser-side components are combined into a single request to limit HTTP overhead. Data is cached by Falcor client-side, and subsequent requests for cached data avoid a round-trip to the server. This decoupling of the model from the data source, along with all of the efficiency considerations, is exceptionally appealing. But the underlying concepts can be a bit mind-bending. I was a little confused by Falcor until I watched [this video by Jafar Husain][why-falcor-video].


### Webpack

Webpack, a build-time node.js library, further supports modularization of small focused React components. It also allows you to easily minify and concatenate your CSS and JavaScript, along with generation of source maps that make debugging much easier. After installing webpack and setting a few configuration options, it will monitor your code and generate new "bundles" whenever you make changes. Instead of importing a bunch of CSS or JS files client-side, you can simply import the bundle or bundles (depending on your configuration) generated by webpack, saving unnecessary HTTP requests on page load. Webpack also has a large number of plugins that can be used to "influence" the bundles it generates. For example, JSX is turned into JavaScript using the "jsx-loader" plugin. If you wish to write ECMAScript 6 code, but don't plan to limit support to browsers that fully implement the spec, you can use the "babel-loader" plug-in to ensure your ES6 code is turned into ES5-compliant code as part of webpack's bundle generation process.


### ES6

ECMAScript 6, also known as ECMAScript 2015, is currently the latest specification for the JavaScript language. It defines some big new features, such as fat arrow functions, classes, string interpolation, and the ability to create block scope. While ES6 support is limited to the newest browsers, it presents a host of elegant solutions and syntax that many developers find appealing and useful, myself included. Before ES6, developers that wanted to make use of some of these features had to settle for CoffeeScript or TypeScript. But now, all of the niceties in these higher-level abstractions are available in the underlying language itself. Horray! And if we want to ensure our ES6 code is executable in older browsers, a compiler named [babel][babel] can be used to transform your ES6 code into ES5 code as part of a build step. Once all of your supported browsers fully implement the specification, you can simply remove this build step.


## Building a simple app

To demonstrate all of the new items outlined above, I've created a trivial single-page application. While this is a contrived example, it exists to help you better understand how all of these technologies work together on a basic level. From this knowledge, you should be able to expand upon my code and build something a bit more realistic. Our sample app will allow us to read and modify a list of names. The list is maintained on the server, which will contain an initial list of names to be displayed to the user on page load. Changes to the list are initiated in the browser and persisted back to the server.

### Setup

Let's start by dividing up this application into logical pieces. At the most basic level, we have 2 parts - a client and a server. Our client exists entirely in the browser, and our server is a simple API endpoint. On the client, we must expose an interface that will allow our users to see and manipulate the names list. This list will be represented by a model that is understood by both the client and server. Essentially, our model will be expressed in JSON format in our "database", and will consist of an array of objects, with each object having a `name` property. While it is certainly _not_ a requirement for our model to be expressed in JSON format in our backing storage system, this will make our example app a bit easier to setup and understand.

Another important step, before diving into the code, is to think of our application in terms of reusable components that are not dependent on each other wherever possible. Client-side, I can see three components - one that lists the names, another that allows names to be added, and a third that ties these two components together. This third component is important, as it allows us to forgo coding an explicit dependency between the list and "add name" components. Of these three components, two are reusable outside of our application.

The server itself can be divided up into multiple pieces. At the highest level, we have an HTTP server that exposes static resources and routes API requests. We will also need a series of code blocks that service the various API requests from our client. We can perhaps think of each such request handler, or route, as a separate piece. Finally, we have our backing store of data which also provides initial values. Our API endpoint handlers will delegate to this backing store for lookup and persistence of data.

I'll go over all of the dependencies in the following sections, but our most basic libraries and frameworks consist of:

- React
- Falcor
- Express
- Babel
- Webpack
- Node.js

You can see all dependencies for this sample application in the project's [package.json file][package.json].


### Creating a server

Please use the [server.js file][server.js] in the project's GitHub repository for reference as I discuss the server-side portion of our example app. Our server will handle API requests and serve up static resources (such as our JavaScript and HTML files). It will be written in JavaScript using Node.js, and will rely on the following technologies:

- Falcor
- Express


#### Getting started

We will represent our server using a single JavaScript file for simplicity. The first logic step may be to pull in all of our dependencies:

```javascript
var FalcorServer = require('falcor-express'),
    bodyParser = require('body-parser'),
    express = require('express'),
    Router = require('falcor-router'),
    app = express()
```

There are two Falcor-related dependencies. The first, `FalcorServer`, will be used to forward API requests to the most appropriate handler. The `Router` is what we will use to _define_ all these handlers. Each handler will be tied to a route string, which defines the type of model data associated with the request. While this may all seem a bit mysterious now, it will become clearer before the server-side section is complete.

The other three dependencies help us to server static resources and parse HTTP requests into a more manageable form. For example, `express` listens to all HTTP requests on a specific port and either serves up static resources (such as our JS and HTML files) or routes the request to a more specific handler, such as our Falcor `Router`.

Let's also define our data store. Again, for simplicity, let's just maintain our data directly in our node server via a simple JavaScript object:

```javascript
var data = {
  names: [
    {name: 'a'},
    {name: 'b'},
    {name: 'c'}
  ]
}
```

The above store also contains an initial list of names to be displayed to the user.


#### Request handlers

Let's continue by configuring our request handlers:

```javascript
app.use(bodyParser.urlencoded({extended: false}));
app.use('/model.json', FalcorServer.dataSourceRoute(() => new NamesRouter()))
app.use(express.static('.'))
app.listen(9090, (err) => {
    if (err) {
        console.error(err)
        return
    }
    console.log('navigate to http://localhost:9090')
});
```

In the first line, we're asking the `bodyParser` library to take any requests that contain application/x-www-form-urlencoded message bodies and parse the contents into a JavaScript object. This object is passed along as [a `body` property on the `Request` object][request.body] maintained by express. In our application, POST requests, which add new names to the list will contain URL-encoded name data, will be parsed by this handler before being forwarded on to a more specific handler by express.

The second line instructs express to delegate _any_ request to the "model.json" endpoint to our Falcor router, which we have not yet defined (we will soon). So, a GET request to "http://localhost:9090/model.json" will be handled here, as will POST requests to the same endpoint. For POST requests to this endpoint with a URL-encoded body, the body will first be parsed by `bodyParser` before being forwarded on to our router.

The third line serves up any static resources in the root of our project. While this wildcard is probably not appropriate for production, it is sufficient for this type of simple demo. Ideally, you should restrict access to static resources instead of allowing all source files to be served up.

Finally, the above code instructs express to listen to all HTTP requests on port 9090. This is the port that you must use client-side for access to static resources, as well as the API. Notice that we are making use of some ECMAScript 6 syntax here, specifically an [arrow function][es6-arrow]. In this case, an arrow function is simply a more elegant way of expressing a function argument. In ES5 syntax, our listener function is equivalent to:

```javascript
app.listen(9090, function(err) {
    if (err) {
        console.error(err)
        return
    }
    console.log('navigate to http://localhost:9090')
});
```

#### API route handlers

Here we will create routes for three different API requests.


##### Number of names

First, we can expect our client to ask for the number of names in the list. The necessity of this information will become clear when we define our next route. The names list length route looks like this:

```javascript
var NamesRouter = Router.createClass([
  route: 'names.length',
  get () => {
    {path: ['names', 'length'], value: data.names.length}
  }
]);
```

Remember the `NamesRouter` we referenced in the previous section? This is our Falcor request router, and express will forward all appropriate API requests here. Our length route is simple, but exposes some Falcor-specific syntax that I have not yet explained. The `route` property identifies the "signature" of the request. If our Falcor client asks for the length of all names, the server-side Falcor router will match on this route string and execute the `get` function, which will describe the data to be returned to our Falcor client.

The response consists of two properties. The first such property, `path`, in our case, simply mirrors the route signature. The second property in our route's `get` handler is `value`. As you might expect, this holds the actual number of names in our list. We're simply pulling this value by checking the `length` property on the array that makes up our backing data store.


##### Display names for `n` name records

When our page loads, we will want to display at least some of the names in our database to the user. At this point, we don't have a concept of name records, name record IDs, or any other metadata associated with these names. Our goal is simple: display names to the user. So, how do we do this? First, we ask our server for the total number of names in our database. Then, we can construct a query that returns names, given a range. Say we want _all_ of the names in the DB, we can ask the server for name values starting with index 0 and ending with number of names - 1. I've already showed you what the "number of names" route looks like. Below is the route that returns the actual names, given a range parameter.

```javascript
{
    route: 'names[{integers:nameIndexes}]["name"]',
    get: (pathSet) => {
        var results = [];
        pathSet.nameIndexes.forEach(function(nameIndex) {
            if (data.names.length > nameIndex) {
                results.push({
                    path: ['names', nameIndex, 'name'],
                    value: data.names[nameIndex].name
                })
            }
        })
        return results
    }
}
```

Above, the `route` property identifies this route as one that will be invoked if the client requests a range of names. More specifically, a client request that is interested in only the `name` property of one or more name records. Our route handler generates an object containing a `path` and `value` property for each index in the range parameter. 

For example, if we request the first two names in our DB, with `name` properties of "Joe" and "Jane", then our route handler will generate an array that looks like this:

```javascript
[
    {
        path: ['names', 0, 'name'],
        value: 'joe'
    },
    {
        path: ['names', 1, 'name'],
        value: 'jane'
    }
]
```

This will be returned to the falcor response handler client-side, which will result in an update of the model cache. The caller will be provided with these names as well.


##### Add a new name record

Our simple names widget also allows us to add new names. I'll cover the client-side portion of this operation shortly. First, take a look at the server-side falcor route:

```javascript
{
    route: 'names.add',
    call: (callPath, args) => {
        var newName = args[0];

        data.names.push({name: newName})

        return [
            {
                path: ['names', data.names.length-1, 'name'],
                value: newName
            },
            {
                path: ['names', 'length'],
                value: data.names.length
            }
        ]
    }
}
```

This is an example of [a Falcor "call"][falcor-call] route. The client will include "names.add" as the path parameter, along with the name to add, as part of a "POST" request. The endpoint described above will be hit, resulting in a new name in our DB. That is expected and straightforward, but the response to this request is interesting. Notice that we are returning two path elements to the client - both describe changes that have occurred to our data set as a result of this new name. The first item in the set indicates that there is a new name added to the end of our names collection. The second item indicates that the number of names in our set has changed. If we were to add a new name of "Bob" to our existing names list of "Joe" and "Jane", the response generated by this route would look like this:

```javascript
[
    {
        path: ['names', 2, 'name'],
        value: 'Bob'
    },
    {
        path: ['names', 'length'],
        value: 3
    }
]
```

So the client doesn't have to ask the server about the index of this new name or the length of the names collection later on - it will be cached by Falcor client-side thanks to the information provided in the response of this "call" request.


### The client

// index page
// implement your components
// config webpack


### Building and using your new app

// building
// running
// using


## Going further

// allowing names to be edited
  // changes to component(s) or new component
  // new graph route(s)
// allowing names to be re-ordered
  // changes to component(s) or new component
  // new graph route(s)


[babel]: https://github.com/babel/babel
[es6-arrow]: http://www.ecma-international.org/ecma-262/6.0/#sec-arrow-function-definitions
[falcor-call]: http://netflix.github.io/falcor/doc/DataSource.html#call
[package.json]: https://github.com/Widen/fullstack-react/blob/1.0.1/package.json
[repo]: https://github.com/Widen/fullstack-react
[request.body]: http://expressjs.com/api.html#req.body
[server.js]: https://github.com/Widen/fullstack-react/blob/1.0.1/server.js
[why-falcor-video]: https://netflix.github.io/falcor/starter/why-falcor.html
