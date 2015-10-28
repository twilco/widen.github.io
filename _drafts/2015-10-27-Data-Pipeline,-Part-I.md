---
title: "Data Pipeline, Part I"
date: 2015-10-27
---

This is part one of a series of posts on how we architected and implemented a(n) [insert-adjectives-here] data-pipeline.

# Part I: The Producers

## Background

Recently, we released a new addition to one of our products, [Media Collective](), called [Insights](). It gives Media Collective administrators a simple way to visualize their site's activity by allowing them to create graphs, charts, and dashboards. 

To do this we had to come up with a plan to migrate historical data, ingest future data, and join and massage all this data into a more malleable form. We architected a "data pipeline" that we now use to consume massive amounts of data and transform it into something usable.

## The Pipeline

The pipleine would consist of three main sections:

1. Producers - would generate "events"
1. Amazon Kinesis - would serve as our real-time message queue
1. Connectors - Elasticsearch for our application; S3 and DynamoDB for backup

The *Producers* are in charge of generating events from a user's action. We have two main producers: our main application and CloudFront. The *Producers* forward generated events to *AWS Kinesis* -- for _[rapid and continuous data intake and aggregation](http://docs.aws.amazon.com/kinesis/latest/dev/introduction.html?tag=duckduckgo-d-20). Kinesis then is polled via our fleet of *Connectors* which suck data out of Kinesis and send them to other sources. In our case, the connectors send events to Elasticsearch for easy searching, and S3 and DynamoDB for backup purposes[1](https://aphyr.com/posts/323-call-me-maybe-elasticsearch-1-5-0).

This post mainly discusses the Producers, and we we tuned them.

## CloudFront

We rely heavily on AWS, and have used CloudFront as a CDN for years now with [little complaints](#fine-uploader-cloudfront-issue). We use CloudFront to host embed and share links -- ways users can externally share content in Media Collective. To capture CloudFront events such as a view or download, we used a relatively new AWS offering called [Lambda]().

We simply set up an S3 bucket that would consume new CloudFront logs. Whenever a gzipped log file was created it would fire a new Lambda. The job of the Lambda was to parse the gzipped logfile, and send the individual records to the Kinesis stream.

### Lambda Throttling

At one point we needed to migrate our historical CloudFront log files into the new Elasticsearch cluster. Initially, we just copied the numerous logs into the bucket, but immediately hit the number of concurrent Lambdas (which is 1,000, btw).

### Lambda Runtime

Another issue we ran into when using Lambda was the time limit. Some of our log files were relatively large (>2MB), and the Lambda in some instances were timing out before completely finishing processing. Lambda is great, but when it does not work it can really suck.

The recently announced 5 minute time limit is well received here at Widen.

## Media Collective

Another major source of events was via our main application. Any time a user would perform a meaningful action we wanted to record that event. We used a Quartz Job with a queue of events that we would flush to our Kinesis stream.
