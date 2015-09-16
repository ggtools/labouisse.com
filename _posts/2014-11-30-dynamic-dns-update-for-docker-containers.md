---
layout: post
title: "Dynamic DNS update for Docker containers"
description: "Implementation of dynamic dns for docker containers"
category: how-to
tags: [in english, docker, python]
comments: true
---

A common way to access a Docker container *from the outside* is to use the publish ports options (`-P` or `-p`). However if you are running your containers with the default networking setup you can access the container ports directly by using the container IP address you can find using `docker inspect` on a running container. Although convenient this is hardly useable since the IP address is dynamically (read: *randomly*) assigned on the container startup. But there is still hope if you have a name server supporting dynamic updates.

## As a Docker administrator…

As a Docker administrator I want a simple way to access the containers so that I won't have to use `docker inspect` and update gazillions of configuration files when I need to access unpublished container ports. The answer to this story will be to leverage the bind9 DNS server dynamic update feature to assign a fixed hostname to a Docker container every time it get started.

## Prerequisites

In order to had this working you first need to have a working bind9 server with the dynamic updates enabled. I found [two](https://www.erianna.com/nsupdate-dynamic-dns-updates-with-bind9) comprehensive [articles](https://www.debian-administration.org/article/591/Using_the_dynamic_DNS_editor_nsupdate) explaining the setup required have dynamic dns updates working.

## Implementation

I shamelessly based my implementation on a [very interesting post](http://objectiveoriented.com/devops/2014/02/15/docker-io-service-discovery-your-network-and-how-to-make-it-work/) from Kelly Becker. I a nutshell the script will run as a daemon and will use `docker events` to get notified of starting containers and then:

1. inspect the starting container to get its IP address, hostname and container name
1. use `nsupdate` to add:
  1. an `A` record associating the container IP address to the container hostname
  1. a `CNAME` record to defind the container name as an alias to the hostname


And *voilà*. The script as well as some files to use it with [upstart](http://upstart.ubuntu.com/) are available on [github](https://github.com/ggtools/docker-tools).


### Differences from Kelly's script

With the exception of the implementation language the difference between Kelly's script and mine is the use of namespaces. The original script was using `ip netns` to make the DNS updates *from inside the container*. I removed this part as it was adding a great deal of complexity to the script and was not needed in my case. The other difference is the addition of the `CNAME` to be able to reference a container by its name in addition to the hostname.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
