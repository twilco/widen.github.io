---
title: "AWS CloudFront User Authentication using Lambda@Edge"
date: 2018-02-07
author: Payton Garland
categories: aws cloudfront lambda@edge authentication authorization widen
excerpt: "We want to protect private S3 content distributed by Amazon's CloudFront service, but we don't want to run a proxy server to authenticate requests. I'll explain the development process of creating a dynamic Lambda function that authenticates viewer requests utilizing the AWS CloudFront feature, Lambda@Edge."
comments: false
---

Our CI server is configured to write build reports to a S3 bucket. However, we found that there's no easy way to serve __private__ files without running an EC2 instance with [proxy software](https://github.com/jcomo/s3-proxy) or living with the limitations of [IP address restrictions](https://pete.wtf/2012/05/01/how-to-setup-aws-s3-access-from-specific-ips/) using IAM rules.

CloudFront has a feature named [origin access identity](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html#private-content-creating-oai-console) that allows you to serve private S3 content. The missing link is the ability to validate requests as they are received by CloudFront. On July 17, 2017, Amazon released a new AWS Lambda feature named [Lambda@Edge](https://docs.aws.amazon.com/lambda/latest/dg/lambda-edge.html). From a developer's perspective, Lambda@Edge allows Node.js functions to inspect, and modify, requests as they arrive at CloudFront POPs around the world.

Having the ability to execute Lambda functions upon *[viewer request](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-cloudfront-trigger-events.html)* gives us the opportunity to authenticate the request in any way we wish. For our initial proof of concept, we checked for basic authentication with a static username/password.

```
'use strict';
exports.handler = (event, context, callback) => {

    const request = event.Records[0].cf.request;
    const headers = request.headers;

    // Configure authentication
    const authUser = 'widen-user';
    const authPass = 'secret-password';

    // Construct expected basic auth header value
    const authString = 'Basic ' + new Buffer(authUser + ':' + authPass).toString('base64');

    // If basic auth header does not match, send WWW-Authenticate response
    if (typeof headers.authorization == 'undefined' || headers.authorization[0].value != authString) {
        const body = 'Unauthorized';
        const response = {
            status: '401',
            statusDescription: 'Unauthorized',
            body: body,
            headers: {
                'www-authenticate': [{key: 'WWW-Authenticate', value:'Basic realm="Widen CI Artifacts"'}]
            },
        };
        callback(null, response);
    }

    // Continue request processing if authentication passed
    callback(null, request);
};
```

This works surprisingly well; however, there was a lot of room for improvement. The most glaring obvious scalability problem is having a single shared password. One option we considered was to extend this code to improve the loading of passwords; the major downsides were still needing to manually manage user credentials and requiring users to remember yet another password.

We use [Google's G Suite](https://gsuite.google.com/) internally for email; we thought if we were to leverage their support of [OpenID Connect](http://openid.net/connect/) as a relying party we could completely remove the need for our Lambda@Edge function to know anything about usernames or passwords.

At this point, the plan seemed clear:

1. Configure CloudFront to inspect HTTP requests as they were received.
2. If the request is not already __authenticated__, use one of the many [OpenID implementations](http://openid.net/developers/certified/) to redirect the user to the Google login UX.
5. Perform user __authorization__ (email whitelist, Google Groups membership, etc.)
3. Set a stateless JWT authentication token, as a cookie, with a configurable TTL.
4. Redirect user to original request path.

As is the case with every new project, the original plan never lasts long. Lambda@Edge has a few major [limitations](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-limits.html#limits-lambda-at-edge) that interfered:

1. Max size of zipped Lambda function (including libraries) is 1MB
2. Environment variables are not supported

Having such a small size limit posed a big issue with the use of an OpenID implementation to interact with OpenID Connect providers. All of the supported implementations exceeded the 1MB limit alone (typically ~2MB). I wrote the URL query parameter composition from scratch focusing on the bare minimum we needed for full functionality.

The lack of environment variables created another hurdle to overcome. My end goal for this project was to allow the user to configure a function without having to touch the code. Not having environment variables at hand meant user-specific variables must be stored in the Lambda@Edge Javascript function itself. The next best option seemed to be an interactive build script allowing the Lambda function to be dynamically built without having to manually edit a configuration file.

Although having a configuration file and build script seemed cumbersome at first, it proved to be a useful addition. The build script freed up expansion options greatly by easily processing user input and automating the creation of the ZIP file to upload to Lambda. For example, the build script will also make structural changes to the project based on the selections chosen (e.g. moving the Google Groups authorization file to the root as auth.js).

After our set of detours, it was an open road. After completing the Google version, we also added support for GitHub and Microsoft authentication. The authentication providers have different authorization methods based upon the specific user data available:

  - **Google**: Hosted domain verification, email whitelist or Google Groups membership
  - **Microsoft**: Azure AD membership or Azure AD username whitelist
  - **GitHub**: Organization membership

[cloudfront-auth](https://github.com/widen/cloudfront-auth) is now available on GitHub as an open source project under the [ISC License](https://opensource.org/licenses/ISC).



