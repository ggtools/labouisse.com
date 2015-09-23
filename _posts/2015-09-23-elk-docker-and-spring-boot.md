---
layout: post
title: "ELK, Docker and Spring Boot"
modified:
categories: how-to
tags: [in english, docker, java, spring boot, spring-boot, elk, logstash, kibana, elasticsearch]
date: 2015-09-23T08:04:42+02:00
comments: true
---

In a [previous post](/how-to/2015/09/14/elk-and-docker-1-8/) I plugged Docker's logs into an ELK system using the brand new GELF plugin. The setup was simple and it was working great except for a couple of issues. This article will show how to improve the basic setup to better cope with *real life* logs, in my case the ones created by Spring Boot applications.

While this post focuses mainly on Spring Boot logs, it can be easily used for other logging systems in Java or any other languages at the cost of changing the regular expressions.

## Logs Issues

Docker container logging works by capturing the container console output (stdout & stderr) and sending the lines to the log driver. This is great as many applications print one line for each logging event, at least most of the time. From here there are a couple of items that could be improved.

### Log Message Semantics

The log messages often carry some semantics. For instance in Spring Boot the [default log format](http://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#boot-features-logging-format) is:

    TIME_STAMP LOG_LEVEL PID --- [THREAD_NAME] LOGGER_NAME : LOG_MESSAGE

For instance:

```
2014-03-05 10:57:51.112  INFO 45469 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet Engine: Apache Tomcat/7.0.52
2014-03-05 10:57:51.253  INFO 45469 --- [ost-startStop-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2014-03-05 10:57:51.253  INFO 45469 --- [ost-startStop-1] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 1358 ms
2014-03-05 10:57:51.698  INFO 45469 --- [ost-startStop-1] o.s.b.c.e.ServletRegistrationBean        : Mapping servlet: 'dispatcherServlet' to [/]
2014-03-05 10:57:51.702  INFO 45469 --- [ost-startStop-1] o.s.b.c.embedded.FilterRegistrationBean  : Mapping filter: 'hiddenHttpMethodFilter' to: [/*]
```

With the basic setup, each line is stored in the `short_message` field as a string. While the ELK stack features full search capabilities, it'll be really better to have the those information is specific fields.

### Multi-line Log Messages

In some cases, a logging event can be translated into several lines for instance when printing a stack trace. When this happens, ELK with store each of the lines as a separate events. Here again, it'll be great to regroup the lines in a single ELK event.

## Improved Setup

From the previous article, all changes will be done in the logstash configuration, more precisely by adding a `filter` section:

```
input {
    [...]
}
filter {
}
output {
    [...]
}
```

### Merging Multiline Logs

Logstash provides a mechanism to merge several log events through the [multiline filter](https://www.elastic.co/guide/en/logstash/current/plugins-filters-multiline.html). This filter works by matching one of the event's field against a regular expression.

For Spring Boot, all log messages will start with a timestamp in the ISO format, this'll be the indicator of a new log event. In addition we will need to configure Logstash to look for the log message in the `short_message` field while the default configuration is to look in to the `message` field.

The logs on multiple lines is fixed by adding the following lines in the `filter` section:

```
multiline {
    pattern => "^%{TIMESTAMP_ISO8601}"
    negate => true
    what => "previous"
    source => "short_message"
}
```

#### Filter vs input

The multiline feature is available either as part of the gelf input or as a separate filter. Using the input version would be better as the filter prevent us from using multithreaded filtering. However the input multiline can only use the `message` field which is always filled with an empty string by the gelf input filter. Follow the status of [PR #18](https://github.com/logstash-plugins/logstash-input-gelf/pull/18) that should fix this issue in a fore-coming release.

### Semantics

Extracting data from the logs will be performed using the [grok](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html) Logstash filter. From the log messages we're going to extract:

- the log level
- the PID
- the thread name
- the logger name
- the message (first line)
- the stack trace (lines after the first)

We won't use the timestamp as the one provided by Docker's logging driver is already reliable enough. *Au contraire* we will use the log level from the messages rather than the one provided by the log driver as the log driver only distinguish between the messages printed on *stdout* (log level 6) and the ones printed on *stderr* (log level 3).

Grok's configuration is pretty simple, well at least if you don't look at the regular expressionish part of the configuration. Grok is using a pattern system based on regular expressions. In addition plain regular expressions, Grok features patterns that we are using to extract parts of the log messages. The basic syntax is `%{PATTERN_NAME:field_name}`. If you're interested in Grok's patterns you can should a look to this [nice tool](http://grokconstructor.appspot.com/).

The filter configuration for grok will be:

```
grok {
    match => { "short_message" => "^%{TIMESTAMP_ISO8601}\s+%{LOGLEVEL:log_level}\s+%{NUMBER:pid}\s+---\s+\[\s*%{USERNAME:thread}\s*\]\s+%{DATA:class}\s*:\s*%{DATA:log_message}(?:\n%{GREEDYDATA:stack})?\n*$" }
}
```

### Mutations

At this point, with the two filters above, you'll have multiple line messages merged together into logging events and fields extracted from the messages. This section will do some clean up by replacing the `message` field with the extracted `log_message` and the digital `level` field with the extracted `log_level`. This will be done using the [mutate](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html) filter with the following configuration:

```
mutate {
    replace => { "message" => "%{log_message}" }
    replace => { "level" => "%{log_level}"}
    remove_field => [ "log_level", "log_message" ]
}
```

The real configuration will also have to take care of cases where the grok pattern won't be matched. It is available on [this gist](https://gist.github.com/ggtools/fe1f1c228ecb58693ed5).

## Afterthoughts

I installed this system on the test platforms at my client's a couple of weeks ago and, to say it shortly, it rocks: no need to give ssh access to testers in order to let them have access to the logs, log messages for all servers available in a single place, permalinks to log events and of course the power of Elastic Search behind.

The multiline filter works flawlessly since the beginning. However the grok filter was a little be more troublesome and I while working 99% of the time, some log messages gave him a hard time. The current version should be working fine but it might need some tweaks to cope at some points.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
