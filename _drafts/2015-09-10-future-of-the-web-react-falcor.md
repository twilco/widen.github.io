---
title:  The Future of Web Development: React + Falcor + ES6
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

// More "traditional" stack = ...
// "Futuristic" often means changing your perspective
  // this can be frustrating at first, but is a useful step in evolution

### React

// Advantages over Angular/Ember
// Virtual DOM
// Simple & focused components
// Relatively small and simple. Elegant. Small learning curve

### Falcor

// Complete departure from traditional REST API
// efficient
// The API is the model
  // intuitive
  // decouple the model/API from the data source(s)
// Mind-bending concepts, but easy to get up and running once concepts are down


### Webpack

// further supports modularization of small focused React components
// minify, concat, source maps


### ES6

// elegance and power without an abstraction like CoffeeScript
// Babel for browsers that don't fully support ES6 syntax


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


[repo]: https://github.com/Widen/fullstack-react
