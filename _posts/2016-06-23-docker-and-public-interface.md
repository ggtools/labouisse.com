---
layout: post
title: Docker and Public Interface
categories: hack
tags: [in english, docker, ipchains, firewall, ufw, systemd]
comments: true
date: 2016-06-23T21:04:27+00:00
---
When you install Docker on an Ubuntu server following the [instructions](https://docs.docker.com/engine/installation/linux/ubuntulinux/) you'll soon discover that all containers' published ports are reachable on all interfaces including the public ones. Until now I choose to use `--ip` to make Docker publish ports on a specific (private) interface but the inception of nifty features such has the [networks](https://docs.docker.com/engine/userguide/networking/) and the [swarm integration](https://docs.docker.com/engine/swarm/) in Docker 1.12 something new was definitely required. Hacking time has come …  

## Important Note (July 1st, 2016)

I discovered that restarting a container may (will?) make this useless as Docker engine rearranges the rules and put back its own chains first.

## The Docker/UFW issue

When the docker engine publishes a port with the default configuration the proxies responsible for the publication listen to all interfaces as you can see by a simple `ps`:

{% highlight bash %}
$ docker run -P -d nginxdemos/hello
$ pgrep -af proxy
xxxx docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 32770 -container-ip 172.17.0.2 -container-port 443
yyyy docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 32771 -container-ip 172.17.0.2 -container-port 80
{% endhighlight %}


If you are running Ubuntu you're probably using the cool [ufw](https://wiki.ubuntu.com/UncomplicatedFirewall) firewall. In this case you'll soon discover that your firewall is powerless when it comes to preventing external connections from reaching your container's published ports. The reason is quite simple: Docker's configuration tells you to change the `FORWARD` chain default policy to `ACCEPT` and ufw is putting rules on the `INPUT` and `OUTPUT` chains. So you're (put here the word you fell the more appropriate to express your dismay including [this one](https://www.youtube.com/watch?v=FvPbxZmZxZ8)).

## Quick Fix

Until recently I ran the engine daemon with the `--ip 172.17.42.1 --bip 172.17.42.1/16`. In a nutshell, these options tells Docker to launch proxies listening only on the bridge network interface as demonstrated by the same `ps` command:

{% highlight bash %}
$ docker run -P -d nginxdemos/hello
$ pgrep -af proxy
xxxx docker-proxy -proto tcp -host-ip 172.17.42.1 -host-port 32770 -container-ip 172.17.0.2 -container-port 443
yyyy docker-proxy -proto tcp -host-ip 172.17.42.1 -host-port 32771 -container-ip 172.17.0.2 -container-port 80
{% endhighlight %}

In this configuration the published ports can non longer be reached on public interfaces. While this configuration may require some routing configuration to connect to the bridge ip from other machines the risk/benefit balance for this workaround if fairly good for *privatish* servers. The only significant problem arises when you want to have some publically reachable containers which involves setting up a proxy based on [haproxy](http://www.haproxy.org/) or [ngnix](https://www.nginx.com/). However the difficulty is not that big as [several](https://github.com/ehazlett/interlock) [systems](https://hub.docker.com/r/jwilder/nginx-proxy/) [for this](http://gliderlabs.com/registrator/latest/) are available.

## Here Comes … the Progress

The new network system, after being experimental for a while, became generally available in release 1.10. This new system includes many nifty features such as transparent overlay support or the use of several bridge networks to provide better isolation to containers. Release 1.12 also includes a *wow* feature which is the integration of [swarm into the engine](https://docs.docker.com/engine/swarm/).

Using the `--ip` workaround with Docker Engine 1.12 is still working (as well as the [dynamic DNS hack](/how-to/2014/11/30/dynamic-dns-update-for-docker-containers)) as long as you are using the default bridge network. However as soon as you start using a non default network or create a swarm service you're back to square one:

{% highlight bash %}
$ docker network create test
$ docker run -P -d --net test nginxdemos/hello
$ pgrep -af proxy
xxxx docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 32770 -container-ip 172.20.0.2 -container-port 443
yyyy docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 32771 -container-ip 172.20.0.2 -container-port 80
{% endhighlight %}

## IPTables is the Key

Since Docker cannot be prevented to listen to public interfaces when using the newest features and ufw is out of the picture the solution will be to use `iptables` on the `FORWARD` chain. At the top of the `FORWARD` chain you'll find a couple of rules created by the Docker engine:

{% highlight bash %}
# With Docker engine 1.12rc1
$ iptables -L FORWARD -nv
Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
  14M  947M DOCKER-ISOLATION  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    6   739 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
# Rest of the listing ommitted
{% endhighlight %}

A working solution is to add some rules at the top of the `FORWARD` chain just before the Docker rules. For instance a set of rules opening the *public* ports and a blanket rule to forbid access to the public interfaces on the other ports:

{% highlight bash %}
iptables -I FORWARD -j REJECT --reject-with icmp-port-unreachable
iptables -I FORWARD -p tcp --dport 32769 -j ACCEPT
{% endhighlight %}

This will work for as long as you don't restart the server or even the Docker daemon. In this case the daemon will recreate its chains and will **insert**  them at the top of the chain and your beautifully hand crafted rules will then be useless: life is unfair (feel free to substitute this with any expression of dismay).

A slightly intense googling session will suggest not much except starting Docker with `--iptables=false`. This will have the effect of preventing Docker from messing up with your rules. While this should be decently working when I see the number of rules Docker is creating on a very simple configuration I really have a bad feeling about this and very afraid that I'll need to add manually many rules everytime I'll be creating *something*.

## Hacktime

The iptables rules is essentially the good way to protect the container ports from access through public interfaces but it needs automated a bit. The final script is almost a direct implementation of the test with a few changes:

- a specific chain for the rules: `DOCKER-PUB`
- a *stop* mode saving the rules in the `DOCKER-PUB` table
- a *start* mode either creating the `DOCKER-PUB` chain from scratch or restoring the previous state.

In addition the this script I also create a systemd configuration file to be put, for instance, in `/etc/systemd/system/docker.service.d`. This file will run the script in *start* mode just after the engine startup and will run the script in *stop* mode just after the engine shutdown.

Both files are available in the following gist:

{% gist ggtools/da80f320bfa960dfc647f4313434789e %}

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
