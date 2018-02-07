---
title: "AWS CloudFront User Authentication using Lambda@Edge"
date: 2018-02-07
author: Payton Garland
categories: aws cloudfront lambda@edge authentication authorization widen
excerpt: "We want to protect private S3 content distributed by Amazon's CloudFront service, but we don't want to run a proxy server to authenticate requests. I'll explain the development process of creating a dynamic Lambda function that authenticates viewer requests utilzing the new Lambda feature, Lambda@Edge."
comments: false
---

The inspiration for this project grew from the need to protect private S3 content distributed by Amazon's [CloudFront](https://aws.amazon.com/cloudfront/) service without running a proxy server to authenticate requests.

On July 17, 2017, Amazon released a new AWS Lambda feature called [Lambda@Edge](https://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html). This allows users to run Node.js functions at CloudFront edge locations and modify the request/response upon four events: *viewer request*, *origin request*, *origin response* and *viewer response*.

Having the ability to execute Lambda functions upon *viewer request* gives us the opportunity to authenticate the user in any way we wish.  Previously, we were using a basic authentication method with a static username/password.  However, there was a lot of room for expansion, particularly utilizing [OpenID Connect](http://openid.net/connect/).  Tech giants Google and Microsoft are both OpenID Connect providers.  Being that our own organization uses [Google's G Suite](https://gsuite.google.com/), that seemed like an excellent place to start.

At this point, the plan seemed clear:

1. Send CloudFront requests to Lambda function (upon viewer request)
2. Use one of the many [OpenID implementations](http://openid.net/developers/certified/) to redirect user and handle callback
3. Set our own JWT with custom token lifetime
4. Redirect user to original request path
5. Authorize user with JWT verification and preferred method (email whitelist, Google Groups membership, etc.)

As with what seems to be every new project, my original plan can never proceed accordingly.

Lambda@Edge has a few [limitations](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html#limits-lambda-at-edge) that interfered:

1. Max size of zipped Lambda function (including libraries) is 1MB
2. Environment variables are not supported

Having such a small size limit posed a big issue with the use of an OpenID implementation to interact with OpenID Connect providers.  All of the supported implementations exceeded the 1MB limit alone (typically ~2MB), so I had to write it from scratch focusing on the bare minimum we need for full functionality. 

The lack of environment variables created another hurdle to bypass. My end goal for this project was to allow the user to configure a function without having to touch the code. Not having environment variables at hand meant user-specific variables must be stored in the function itself. 

My next best option seemed to be an interactive build script allowing the function to be dynamic without direct user intervention.  I created a configuration file, `config.json`, storing user-specific information that gets generated based on the user's input.

Although having such a configuration file and build script seemed cumbersome, it proved to be quite a useful addition. The build script freed up expansion options greatly by easily processing user input and automating the setup process. For example, the build script will also make structural changes to the project based on the user's choices (ie moving the Google Groups authorization file to the root as auth.js).

After our set of detours, it was an open road. 

Various authentication and authorization methods have been added:

1. **Google**: Hosted Domain Verification, Email Whitelist, Google Groups Membership

2. **Microsoft**: Azure AD Membership, Azure AD Username Whitelist

3. **GitHub**: Organization Membership

[cloudfront-auth](https://github.com/widen/cloudfront-auth) is now available on GitHub as an open source project.



