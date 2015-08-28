---
title:  Runtime Configuration for AWS' Lambda
author: Mark Feltner
categories: aws lambda hack
published: false
---

A while ago Amazon released its [Lambda](http://aws.amazon.com/lambda/) service. Lambdas are simple, stateless node.js functions that get executed as callbacks to arbitrary AWS "events".

One thing I disliked about Lambda is that you cannot provide any sort of runtime
configuration to it. You can at least give EC2 "user data" which will be available to the system at runtime. Because of this you are forced to build configuration into your source code either via the zip you give Lambda or through some other sort of mechanism.

Lambdas can have an optional `description` [when created](http://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/Lambda.html#createFunction-property). Also, Lambdas can use the [node aws-sdk](https://github.com/aws/aws-sdk-js) to make requests to other AWS web services, including Lambda itself.

What I did was fill the description of the Lambda with valid JSON. Next, when the Lambda is executed code is run which makes a request for information about the lambda itself. If its description is valid JSON then those values are serialized and used as configuration.

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
