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

My current stack often consists of Java on the server, AngularJS for all of my browser-related code, Jersey for REST API support, along with a whole host of various libraries such as jQuery, underscore, lodash, jQuery UI, and Bootstrap. When designing the underlying sample web application, which I will be discussing shortly, I had four specific goals in mind:

1. **A new and shiny approach**. Instead of developing yet another AngularJS-based UI, or deferring to jQuery, or creating a Java-based endpoint server using Jersey, or doing all three, I really wanted to make use of an entirely new set of tools. I hoped that this would allow me to gain a new perspective and help me to evolve a bit more as a developer.

2. **Simplicity** is another desire of mine. I very much have grown to dislike the substantial learning curve associated with AngularJS 1.x, and am disappointed to discover that the learning curve for v2 is even more steep. The same is true of Java, which I have traditionally used server-side. I'd like to avoid as much boilerplate code as possible and get my application up and running as quickly as possible without sacrificing scalability. Being able to easily describe my frontend as a collection of standalone focused components is also part of this goal. And traditional REST APIs are awkward to maintain and evolve. The frontend developers must coordinate with the backend developers to expose a set of API endpoints that properly support the browser-side representation of the model. As the needs of the UI change, this often requires the API to change as well. Surely there must be a better approach!

3. Some of the issues associated with a traditional REST API in terms of unnecessary request overhead and number of requests and response payloads, were a concern. I was less concerned about client-side rendering performance, which React and AngularJS both handle fairly well, though React is much more monolithic and complex, making it easier to unknowingly introduce serious performance issues into an app. So, **efficiency** is my fourth goal.

4. Finally, I was looking for some approaches or tools that allow me to write uncharacteristically **elegant** code. The code itself should be easy to follow. Looking up and changing data from the UI should be intuitive. Ideally I would like to think about my model, and only my model - not in terms of available API endpoints. I'd also like to avoid much of the noisy boilerplate that is required of my current stack.

In order to address each of these goals, I decided to replace my current lineup of tools with an _entirely_ new set, some of which I initially had never used before. This was very much a learning experience, one which I would like to share with you. Next, I'll document each notable new tool. After the stack is clear, I'll walk you though, from start to finish, creation of a simple web application that is both functional and idiomatic of all items involved in this new stack.


## A futuristic stack

A more traditional stack, at least in my experience, my consist of Angular and/or jQuery and/or backbone on the frontend, with Java handling requests on the backend via some form of a REST API, perhaps using Jersey. In this article, we're going to explore an entirely new stack, one that can be considered "futuristic", at least as of September 2015.

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

ECMAScript 6, also known as ECMAScript 2015, is currently the latest specification for the JavaScript language. It defines some big new features, such as fat arrow functions, classes, string interpolation, and the ability to create block scope. While ES6 support is limited to the newest browsers, it presents a host of elegant solutions and syntax that many developers find appealing and useful, myself included. Before ES6, developers that wanted to make use of some of these features had to settle for CoffeeScript or TypeScript. But now, all of the niceties in these higher-level abstractions are available in the underlying language itself. Horray! And if we want to ensure our ES6 code is executable in older browsers, a compiler named [babel][babel] can be used to transform your ES6 code into ES5 code as part of a build step. Once all of your supported browsers fully implement the specification, you can simply remove this build step and everything should work.


## Building a simple app

// explain goals

### Setup

// divide the app up into 2 pieces
// design your model
// design your UI
  // components?
// dependencies


### Creating a server

// HTTP server
// static files
// graph endpoint
  // implement your routes


### The browser client

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
[repo]: https://github.com/Widen/fullstack-react
[why-falcor-video]: https://netflix.github.io/falcor/starter/why-falcor.html
