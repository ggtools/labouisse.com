---
layout: post
title: "Spring Boot Tests with Embedded MongoDB"
description: "A simple configuration to run SpringBoot tests with an embedded MongoDB server"
category: how-to
tags: [english, mongodb, spring, test, java, spring_boot]
---
{% include JB/setup %}
Although MongoDB cannot be actually embedded there is a nice [tool](https://github.com/flapdoodle-oss/de.flapdoodle.embed.mongo) mimicking the behavior of an actual embedded database. When writing Spring Boot application it is quite easy to replace the connection to a Mongo server with a connection to an *embedded* server with a simple configuration file.

<!--more-->
The following configuration file should do the trick and will enable you to *transparently* use an *embedded* Mongo server instead of connecting to an actual one.

{% gist ggtools/d62aeba970477cec3c52 %}
