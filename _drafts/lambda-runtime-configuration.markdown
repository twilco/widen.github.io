---
title:  Runtime Configuration for AWS' Lambda
author: mfeltner
categories: aws lambda hack
layout: post
---

Amazon recently released a new service into preview called [Lambda](http://aws.amazon.com/lambda/). Lambdas are simple, stateless node.js functions that get executed as callbacks to arbitrary AWS "events". Lambdas automatically scale up/down to process concurrently, and the only "sysadmin" type configuration you need to do is to set the maximum amount of memory it shall use (128MB-512MB), and the maximum amount of time it shall run (default is 3 seconds).

I would definitely suggest reading up on Lambda if you are not familiar.

One potential downside of Lambda is that you cannot provide any sort of runtime configuration to it. With EC2, by contrast, you can provide "user data" which will then be available to the system at runtime. These data can then be used to modify the behavior of software on the instance such as connecting to a different database depending on whether the instance is in a production, staging, or development environment.

It _appears_ that Amazon expect you to have your function set up ahead of time, but this is a bit unreasonable because ... well ... now you have to set up your function beforehand.

I noticed a tiny detail about Lambdas: they can have a `description`. Also, Lambdas can use the [node aws-sdk](https://github.com/aws/aws-sdk-js) to make requests to other AWS web services, including Lambda itself.

What I did was fill the description of the Lambda with valid JSON. When the Lambda is executed it makes a request for information about itself. If its description is valid JSON then those values are serialized and used.

Here's an example of a Lambda that is processing its own description as a sort of runtime configuration.

``` javascript
console.log('Loading event');

var aws = require('aws-sdk');

exports.handler = function(event, context) {
    
    var lambda = new aws.Lambda({apiVersion: '2014-11-11'});
    lambda.getFunctionConfiguration({ FunctionName: "whatstheenv" }, function(err, data){
        if (err) {context.done(err, err.stack); }
        var runtimeConfiguration = {};
        try {
            runtimeConfiguration = JSON.parse(data.Description);
        } catch (except) {
            console.log("unable to parse description as JSON");
        }
        console.log(runtimeConfiguration);
        context.done(null, "We are done here.");
    });

};
```

Now, we can simply edit the description in the console, and voilà, our next lambda run will have different data!


