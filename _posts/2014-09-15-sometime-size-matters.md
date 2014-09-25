---
layout: post
title: "Sometime size matters"
description: "or: Why you should choose wisely your base image"
category: how-to
lang: en
tags: [java, restx, english, docker, linux]
---
{% include JB/setup %}
Sometime size does matter, for Godzilla of course but also for Docker images. I came across an interesting article this week-end about a [2 week experience with Docker](http://t37.net/is-docker-ready-for-production-feedbacks-of-a-2-weeks-hands-on.html) to see if it was production ready and a [follow-up](http://blog.loof.fr/2014/09/is-docker-ready-for-production.html) by Nicolas De Loof.

<!--more-->
One of Frédéric de Villamil's concerns was the size of the Docker images: *your container will most likely weight more than 1GB* which seems true as you'll need to include a Linux distro in your images. In order to mitigate this, Nicolas suggested to start *from* an images based on Busybox rather than Debian or Ubuntu for instances [David's Java8](https://registry.hub.docker.com/u/dgageot/java8/).

## Java 8 Images

At the moment there are a couples of base images for Java 8 applications out there. I guess the most popular are [dockerfile/java](https://registry.hub.docker.com/u/dockerfile/java/) and the *[official one](https://registry.hub.docker.com/_/java/)*. Let's have a look at those images.

Image|From|Size
-----|----|-----
dockerfile/java:oracle-java8|dockerfile/ubuntu|917.7 MB
java:8|debian:experimental|692.2 MB
dgageot/java8|dgageot/busybox-ubuntu|201.7 MB

The size difference is quite significant as we have a 3.5 or 4.5 factor between the lightweight Java image and the regular ones. Even if you add a 100MB application to this base images you'll still have at least a 2.5 size factor in favor of the lightweight image.

### Caveat

Since David's image is very small many things won't be included. For instance there is no package manager, no JDK but only a JRE (with `tools.jar`), etc. Depending on your application you might need to add some extra contents.
