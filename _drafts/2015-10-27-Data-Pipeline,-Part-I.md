---
title: "Data Pipeline"
date: 2015-10-27
---

This is part one of a series of posts on how we architected and implemented a scalable data-pipeline.

# Background

Media Collective hosts thousands of terabytes of digital content (video, images, audio files, ...) for our customers. 
The tool also allows administrators to permission, categorize, convert, and share their content.
Recently, we saw a growing need for our customers to get a better picture of what is going on inside of their Media Collective.
Since many of our customers are marketing agencies or departments they need data on who is using their assets, where they are using them, and what they are using them for.
They would also like to be able to compare historical data.

To do this we had to come up with a plan to migrate historical data, ingest future data, join and massage all this data into a more malleable form, and then develop a user interface for accessing all the data that was usable by someone whose background was not statistics or data science.

This post is the story of how we accomplished all of these goals and in the process created our first scalable data-ingestion and procesing pipeline.

# The Pipeline

The pipleine consists of three main sections:

1. Producers - would generate "events" and send them a central aggregator
1. Amazon Kinesis - would serve as our real-time message queue
1. Connectors - Elasticsearch for our application; S3 and DynamoDB for backup

The *Producers* are in charge of generating events from a user's action.
We have two main producers: our main application and CloudFront (with many more planned for the future).
The *Producers* forward generated events to *AWS Kinesis* -- for _[rapid and continuous data intake and aggregation](http://docs.aws.amazon.com/kinesis/latest/dev/introduction.html?tag=duckduckgo-d-20)_.
Data in Kinesis is sucked out from our fleet of *Connectors* which massage the data and send them to other sources.
In our case, the connectors send events to Elasticsearch for easy searching, and S3 and DynamoDB for backup purposes[1](https://aphyr.com/posts/323-call-me-maybe-elasticsearch-1-5-0).

# CloudFront

We rely heavily on AWS, and have used CloudFront as a CDN for years now. We use CloudFront to host embed and share links -- ways users can externally share content in Media Collective. To capture CloudFront events such as a view or download we used a relatively new AWS offering called [Lambda]().

We simply set up an S3 bucket that would consume new CloudFront logs. Whenever a gzipped log file was created it would fire a new Lambda. The job of the Lambda was to parse the gzipped logfile, and send the individual records to the Kinesis stream.

## Lambda Throttling

At one point we needed to migrate our historical CloudFront log files into the new Elasticsearch cluster. Initially, we just copied the numerous logs into the bucket, but immediately hit the number of concurrent Lambdas (which is 1,000, btw).

## Lambda Runtime

Another issue we ran into when using Lambda was the time limit. Some of our log files were relatively large (>2MB), and the Lambda in some instances were timing out before completely finishing processing. Lambda is great, but when it does not work it can really suck.

The recently announced 5 minute time limit is well received here at Widen.

## Error Handling

One annoyance we ran into was the way that Kinesis and the provided AWS Kinesis SDK handles errors. 

# Media Collective

Another major source of events was via our main application. Any time a user would perform a meaningful action we wanted to record that event. We used a Quartz Job with a queue of events that we would flush to our Kinesis stream.

# Kinesis

# Connectors

## S3

## Elasticsearch

# UI

## Experience

## Translation
