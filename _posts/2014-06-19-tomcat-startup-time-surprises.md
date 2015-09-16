---
layout: post
title: "Tomcat startup time surprises"
description: "Tomcat can be slow to start, sometime"
category: misc
lang: en
tags: [tomcat, entropy, docker, in english]
comments: true
---
While testing [Spring Boot](http://projects.spring.io/spring-boot/) I came on a very strange result: it was faster to start Spring Boot's *Hello World!* from a minimal Docker image than directly from the command line. I know that Docker is using containers which are way faster than full fledged virtual machines, it didn't make sense especially considering than on Mac OS X, the Docker daemon runs in a virtual machine.

I tried on a Dédibox and the first time I ran the application from Docker I got:

    Started Example in 4.44 seconds (JVM running for 5.197)

When running directly from the Dédibox I got:

    Started Example in 16.75 seconds (JVM running for 18.319)

Restarting a second time lead to:

    Started Example in 4.384 seconds (JVM running for 4.986)

Even if the second time got better I was amazed by how fast Docker was. I started to make some more run and then my world collapse: running the application from Docker started taking a long time to start. When I say *long* I mean slower by a factor 10, 20 or even more:

    Started Example in 240.774 seconds (JVM running for 241.466)
    Started Example in 62.58 seconds (JVM running for 63.384)

Then I spotted in the logs the following message:

    Creation of SecureRandom instance for session ID generation using [SHA1PRNG] took [235,853] milliseconds.

And everything was clear.

I a nutshell, on startup Tomcat (which is embedded by Spring Boot) creates a secure id generator for the session. In order to provide the highest security level, Java uses `/dev/random` gather some entropy. In both cases, the Docker daemon was running on a virtual machine which is only used for development purposes. The first time I ran the application, there were enough entropy in the system pool to create the `SHA1PRNG` but since the VM wasn't doing anything, the random pool got depleted creating delay on application startup.

So added `-Djava.security.egd=file:/dev/urandom` on the command line and everything went back to normal. On the Dédibox with Docker running a KVM virtual machines, the startup times were approximatly the same (around 5 seconds); which is quite amazing. On my Mac, Docker took around 8 seconds to start while it only took 5 seconds to start natively.

## random or urandom?

`[Update on 2014/11/02]` I original wrote that `/dev/urandom` was ok in a development or test environment but that `/dev/random` should be the choice in production. After a discussion on this topic on Twitter it appears that there is no sensible reason to keep using `/dev/random` for the purpose of initializing Tomcat PRNG. This [great article](http://www.2uo.de/myths-about-urandom/) contains everything you need to understand why `/dev/urandom` is secure enough for Tomcat PRNG initialization.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
