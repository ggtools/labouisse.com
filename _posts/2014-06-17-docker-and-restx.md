---
layout: post
title: "Docker and Restx"
description: "My Docker images for rest applications"
category: how-to
tags: [java, restx, english, docker]
---
{% include JB/setup %}
After quite a while I finally got some time to install and experiment [Docker](http://docker.io/). My first *public* experiment would be to dockerize the sample hello world application which can be generated by [RESTX](http://restx.io) when creating a new application.
<!--more-->

In a nutshell I wanted to create a restx archive for the hello application and find a simple and generic way to create a Docker image to run this application.

## Restx application

Nothing magic here, I just created a new application with `restx app new` and asked to create the sample resource. The only *hairy* part being the creation of the restx archive:

```bash
restx deps install + app compile + app archive /tmp/restx-app.jar
```

## Docker images

Since I want something generic I planned to have two images: one containing only the restx installation and the to run the applications.

### Restx

I started from Frédéric Camblor's [image](https://registry.hub.docker.com/u/fcamblor/restx-docker/) and made a bunch of modifications:

1. Upgraded restx to the latest version
1. Replaced the base image (`dockerfile/java`, 1 GB)  by a leaner one (`java`, 600MB)
1. Created a restx user as I really loath running applications as root
1. Exposed port `8080`

Which lead to the following `Dockerfile`:

```
FROM        java
MAINTAINER  Christophe Labouisse

# Update and install curl that will be needed later
RUN         apt-get -yqq update
RUN apt-get -yqq install curl

# Rest x configuration
ENV RESTX_VERSION 0.33.1
ENV RESTX_USER restx
ENV HOME /var/lib/restx
ENV PATH ${PATH}:${HOME}/.restx

# Creating a restx user and use it from now on
RUN useradd --home ${HOME} --create-home ${RESTX_USER}
USER restx

RUN         curl -Ls http://restx.io/install.sh > /tmp/install-restx.sh
RUN         chmod 700 /tmp/install-restx.sh

RUN         /tmp/install-restx.sh ${RESTX_VERSION} && rm /tmp/install-restx.sh

RUN         restx shell install io.restx:restx-core-shell:${RESTX_VERSION}
RUN         restx shell install io.restx:restx-build-shell:${RESTX_VERSION}
RUN         restx shell install io.restx:restx-specs-shell:${RESTX_VERSION}

EXPOSE 8080
```

This image is uploaded to Docker Hub as [ggtoos/restx-docker](https://registry.hub.docker.com/u/ggtools/restx-docker/).

### Application

Starting with the restx archive should be straight forward:

1. `restx grab` to unpack the archive
1. `restx deps install`
1. `restx app run`

The resulting `Dockerfile`is:

```
FROM        ggtools/restx-docker
MAINTAINER  Christophe Labouisse

ADD restx-app.jar /tmp/restx-app.jar

RUN restx app grab file:///tmp/restx-app.jar + deps install

CMD cd ${HOME}/.restx/apps/restx-app && restx app run --mode=prod --fg
```

Using this `Dockerfile` you'll only need to copy your restx archive to `/tmp/restx-app.jar` and build your image with `docker build`.

## Results

First impression: this is blazing fast as it only take 5 seconds to create the container and launch the application. I admit this is not a big application but this is way better than deploying a war on a recent tomcat.

My only issue is that the creation of the application image is really slow as restx needs to fetch the dependencies at this time. This is a waste of time as the dependencies had most probably already been fetched on the developement/build environment. Creating an executable jar at build time would probably be more efficient.