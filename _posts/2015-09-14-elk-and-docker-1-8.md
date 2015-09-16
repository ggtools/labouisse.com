---
layout: post
title: "ELK and Docker 1.8"
modified: 2015-09-16T21:48:33+02:00
categories: how-to
tags: [in english, docker, docker-compose, elk, logstash, kibana, elasticsearch]
date: 2015-09-14T17:18:33+02:00
comments: true
---

Starting with version 1.6, Docker introduced the ability to configure the log driver when creating a container. Using the `syslog` driver made it possible to push containers' log messages to the local syslog or even to a centralized ELK based system. There are some nice articles describing how to set up such a system like [this one](http://technologyconversations.com/2015/05/18/centralized-system-and-docker-logging-with-elk-stack/). Some nifty features introduced in version 1.8 made this system even better.

## Pushing Through syslog

While working find I had some of issues with this setup. First of all the configuration as a little bit complex and getting only the raw messages required a complex configuration:

```
input {
  syslog {
    type => syslog
    port => 25826
  }
}

filter {
  if "docker/" in [program] {
    mutate {
      add_field => {
        "container_id" => "%{program}"
      }
    }
    mutate {
      gsub => [
        "container_id", "docker/", ""
      ]
    }
    mutate {
      update => [
        "program", "docker"
      ]
    }
  }
}

output {
  elasticsearch {
    host => db
  }
}
```

Still on the complexity side, was the need to install and configure `rsyslog` to forward some messages to Logstash.

In addition to this complexity, the only information given by the syslog driver to Logstash, in addition to the message itself, is the container id. In practice this made the use of the collected logs quite difficult as the container id changed every time a container is restarted.

## Docker 1.8

Docker 1.8 improved the log driver mechanism by adding many log drivers: journald, fluentd and gelf. This last one is the most interesting in our case as Logstash includes an [input plugin for Gelf](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-gelf.html).

Using the Gelf plugin remove the need of using rsyslog to send log messages directly to Logstash. In addition, the [source code](https://github.com/docker/docker/blob/master/daemon/logger/gelf/gelf.go) show that the messages sent to Logstash now have the container name and even more:

{% highlight go %}
fields := gelfFields{
    hostname:      hostname,
    containerID:   ctx.ContainerID,
    containerName: string(containerName),
    imageID:       ctx.ContainerImageID,
    imageName:     ctx.ContainerImageName,
    command:       ctx.Command(),
    tag:           ctx.Config["gelf-tag"],
    created:       ctx.ContainerCreated,
}
{% endhighlight %}

### Setup

Using Gelf for communication, the Logstash configuration will be deeply simplified:

```
input {
  gelf {
    type => docker
    port => 12201
  }
}

output {
  elasticsearch {
    host => db
  }
}
```

My `docker-compose.yml` for the ELK platform is:

{% highlight yaml %}
elasticsearch:
    image: elasticsearch
    volumes_from:
        - elasticsearchData
    ports:
        - "9200"

logstash:
    image: logstash
    environment:
        TZ: Europe/Paris
    expose:
        - "12201"
    ports:
        - "12201:12201"
        - "12201:12201/udp"
    volumes:
        - ./conf:/conf
    links:
        - elasticsearch:db
    command: logstash -f /conf/gelf.conf

kibana:
    image: kibana
    links:
        - elasticsearch:elasticsearch
    ports:
        - "5601"

elasticsearchData:
    image: busybox
    command: "true"
    volumes:
        - /usr/share/elasticsearch/data
{% endhighlight %}

### Containers Configuration

After starting the ELK platform, individual containers can use it by adding the following options to `docker run`:

{% highlight bash %}
--log-driver=gelf --log-opt gelf-address=udp://172.17.42.1:12201
{% endhighlight %}

#### With Compose

At the time of this writing, compose does not support the `gelf` driver. Until the release of compose 1.5.0, you have two solutions: wait until the next release, build it from master or use [this version](https://bintray.com/artifact/download/clabouisse/Miscellaneous/docker-compose-dev) built from github master.

## Next Step

This simple setup is a very good start but for real life applications we might want to add extra features:

- keep multi line log messages such as stack traces in a single event
- extract information from log messages such as the log severity

In a coming article I'll improve the configuration for Spring boot applications.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
