---
title:  Runtime Configuration for AWS' Lambda
author: mfeltner
categories: aws lambda
layout: post
---

Lately, my team and I (the A-Team) have been working on architecting a system to gather, process, and evaluate all sorts of events from Media Collective. The end goal is to provide our clients with a flexible platform for analyzing their digital asset library.

One challenge we faced was processing events for our embedded links. These links are static URLs that use CloudFront to serve up an asset. With embed links, clients have a single pointer to an asset, and many use this feature to embed assets on the web in `<img>` tags and whatnot.

When a user views an embedded image, CloudFront generates a line in a logfile with information about that user's request. Information includes IP address, user agent, what asset was viewed, and more. Perfect analytics data!

The CloudFront log is eventually put in an S3 bucket automatically for us. The challenge was how to respond to that event.

With impeccable timing, Amazon recently released a new service into preview, [Lambda](http://aws.amazon.com/lambda/). Lambda can respond to arbitrary AWS "events" with a simple, stateless node.js function. Lambdas automatically scale up/down to process concurrently, and the only "sysadmin" type configuration you need to do is to set the maximum amount of memory it shall use (128MB-512MB), and the maximum amount of time it shall run (default is 3 seconds).

I would definitely suggest reading up on Lambda if you are not familiar.

One potential downside of Lambda is that you cannot provide any sort of runtime configuration to it. With EC2, by contrast, you can provide "user data" which will then be available to the system at runtime. These data can then be used to modify the behavior of software on the instance such as connecting to a different database depending on whether the instance is in a production, staging, or development environment.

It _seems_ like Amazon expect you to have your function set up ahead of time, but this is a bit unreasonable because now you have to set up your function beforehand.

I noticed a tiny detail about Lambdas: they can have a description. Also, Lambdas can use the [node aws-sdk]() to make requests to other AWS web services, including Lambda itself.

What I did was fill the description of the Lambda with valid JSON. When the Lambda is run it makes a request for information about itself. If its description is valid JSON then those values are serialized and used.

Here's an example of a Lambda that is processing its own description as a sort of runtime configuration.

``` javascript
console.log('Loading event');

var aws = require('aws-sdk');

exports.handler = function(event, context) {

    var lambda = new aws.Lambda({apiVersion: '2014-11-11'});
    lambda.getFunctionConfiguration({ FunctionName: "whatstheenv" }, function(err, data){
        if (err) {context.done(err, err.stack); }
        var runtimeConfiguration = JSON.parse(data.Description);
        console.log(runtimeConfiguration);
        context.done(null, data);
    });

};
```




