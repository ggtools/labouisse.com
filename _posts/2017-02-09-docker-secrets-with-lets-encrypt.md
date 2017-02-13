---
layout: post
title: Docker Secrets With Letsencrypt
categories: how-to
tags: [in english, docker, swarm, letsencrypt]
comments: true
date: 2017-02-09T08:33:32+01:00
---
Although Docker 1.13 brings it's usual load of features the most prohiminent one is certainly the [secret management](https://docs.docker.com/engine/swarm/secrets/). There are [many](https://blog.docker.com/2017/02/docker-secrets-management/) [nice](https://www.theregister.co.uk/2017/02/09/docker_secrets/) [articles](http://windsock.io/secrets-come-to-docker) [describing](https://blog.mikesir87.io/2017/01/managing-secrets-in-docker-swarm/) this feature so instead of presenting this feature, this article will focus on a solution to use Docker secrets with [Letsencrypt](https://letsencrypt.org).

## Docker Secrets

Docker Secrets aim at providing a simple and secure way to store and use confidential data such as password, private keys, etc. The API is pretty simple:

- a new command `docker secret` to create, delete, list or inspect the secrets
- new options to `docker service create`and `docker service update` to control the container's access to the secrets.

### Secret Management

The secret creation is quite straightforward as `docker secret create --help` will show:

{% highlight bash %}
Usage:	docker secret create [OPTIONS] SECRET file|-

Create a secret from a file or STDIN as content

Options:
      --help         Print usage
  -l, --label list   Secret labels (default [])
{% endhighlight %}

When a secret is created Docker will guarantee to keep it encrypted when sending it to any remote node (encryption in transit) or when stored on the server filesystem (encryption at rest). The secrets are stored in the [Raft](https://raft.github.io/) log which is encrypted and replicated to all the managers in the cluster.

> It is important to know that the log encryption is only performed by Docker 1.13 and above which means that if one of the cluster managers is running docker 1.12, the secrets can be stored uncrypted in this server filesystem.

The other `secret` subcommands are really as simple as this one with a couple of things worth noting:

1. Secrets are immutable: you can create a secret, delete a secret but you cannot change it.
1. A secret cannot be deleted while a service is using it.

### Container Access to Secrets

Docker secrets implementation is strongly tied to swarm as the storage in the Raft log might suggest. As a consequence, secret are not available to *plain old* containers but only to services. At runtime, an in-memory filesystem will be mounted inside the container on `/run/secrets` and will contain one file for each secret the services has been given access to. 

A service can be given access to a secret throught the `--secret` option of the `docker service create` command. For instance: `docker service create --secret cartman` will create a `/run/secrets/cartman` file inside the container. A more complex version of this option allows to specify the name of the secret file and specify the owner, group and the permissions of the secret file (have a look at [Create a service with secret](https://docs.docker.com/engine/reference/commandline/service_create/#create-a-service-with-secrets) for more information).

Similarly, the `docker service update` commands have `--service-rm` and `--service-add` options (more information [here](https://docs.docker.com/engine/reference/commandline/service_update/#adding-and-removing-secrets)).

## Let's Encrypt

Before talking about the integration with Docker secrets, let's have a closer look at how Letsencrypt is actuall working. 

There are many ways of using Letsencrypt in this article I'll be considering only the use of [Cerbot](https://certbot.eff.org). To add more restriction, I've only tested this with the *standalone* plugin while I'm pretty sure it'll also work with the *webroot* plugin as well.

### Obtaining a Certificate

If you are running a server with a public connection, getting the first certificate from Letsencrypt is quite easy:

{% highlight bash %}
docker run --rm -v $PWD/etc:/etc/letsencrypt -v $PWD/logs:/var/log/letsencrypt \
       -p 443:443 quay.io/letsencrypt/letsencrypt certonly \
       --standalone --staging \
       --non-interactive --email you@domain.com --agree-tos -d hostname
{% endhighlight %}

> Here we added the `--staging` option in order to use the [staging](https://letsencrypt.org/docs/staging-environment/) instead of the [production](https://letsencrypt.org/docs/rate-limits/) platform.

In the current directory you'll find a `etc` directory containing the certificates, the private keys and some miscellaneous configuration files used by letsencrypt. For instance the `etc/live/hostname` will contain everything you need to configure a web server with the newly generated certificates as indicated in the `README`:

{% highlight bash %}
This directory contains your keys and certificates.

`privkey.pem`  : the private key for your certificate.
`fullchain.pem`: the certificate file used in most server software.
`chain.pem`    : used for OCSP stapling in Nginx >=1.3.7.
`cert.pem`     : will break many server configurations, and should not be used
                 without reading further documentation (see link below).

We recommend not moving these files. For more information, see the Certbot
User Guide at https://certbot.eff.org/docs/using.html#where-are-my-certificates.
{% endhighlight %}

### Renewing the certificates

Letsencrypt create certificate with a very short validity: 90 days. The idea is to leverage the automated system to renew frequently your web servers' certificate. Renewal is even easier that the creation as it can be done with:

{% highlight bash %}
docker run --rm -v $PWD/etc:/etc/letsencrypt -v $PWD/logs:/var/log/letsencrypt \
           -p 443:443 quay.io/letsencrypt/letsencrypt renew \
           --staging --force-renewal
{% endhighlight %}

> Note the `--force-renewal` option in addition to `--staging` in order to renew the certificate even if we are not withing 30 days of the expiration date.

At this point you can notice that symbolic links in the `etc/live/hostname` directory have been updated to reflect the certificate renewal. If you look closer you'll see that the files are merely symbolic links to files located under `etc/archive`

## First Integration with Secrets

In order to test the integration I created a version of [Nginx](https://hub.docker.com/_/nginx/) with SSL enabled and using key and certificate located under `/run/secrets` to be compatible with Docker Secrets:

{% gist ggtools/8f089143245752e54f9d68789ee0aacd %}

You can build your own image or use the pre-built [ggtools/test-nginx-ssl](https://hub.docker.com/r/ggtools/test-nginx-ssl/). 

### Creating the Secrets

We are going to create two secrets:

1. `test_site.key` from `etc/live/<hostname>/privkey.pem`
1. `test_site.crt` from `etc/live/<hostname>/fullchain.pem`

{% highlight bash %}
docker secret create test_site.key etc/live/hostname/privkey.pem
docker secret create test_site.crt etc/live/hostname/fullchain.pem
{% endhighlight %}

### Creating the Service

The next step is to create a service using these secret:

{% highlight bash %}
docker service create -p 8443:443 --name nginx_test \
       --secret source=test_site.key,target=site.key \
       --secret source=test_site.crt,target=site.crt ggtools/test-nginx-ssl
{% endhighlight %}

Thanks to the *source*/*target* syntax, the secret names can be mapped to the file names expected by the image.

At this point, this should be working and the nginx container could be accessed from a browser. There should have been a security warning from the browser but as we used the staging environment this is completely normal. Should we celebrate then? Naaaah. There's a small issue with this setting: upgrading the certificate will be *complicated* as secrets are immutable and cannot be deleted until removed from all services. That'll be mean that when the certificate is renewed, both secrets will have to be removed from *all* services.

## Improving the Integration

We have seen that the files from the `etc/live/<hostname>` directory are symbolic links to files in the `etc/archive/<hostname>` directory. If we look at this directory we'll find that Letsencrypt is actually versioning the certificates and files. Which is exactly what we need to implement [secret rotation](https://docs.docker.com/engine/swarm/secrets/#/example-rotate-a-secret).

### Creating the Secrets

We are still going to create two secrets but we will use the files from `etc/archive/<hostname>` and will add a version to the secret names:

{% highlight bash %}
docker secret create test_site.key.1 etc/archive/hostname/privkey1.pem
docker secret create test_site.crt.1 etc/archive/hostname/fullchain1.pem
{% endhighlight %}

When renewing the certificate, Letsencrypt will create new files with a new version number. Will will then create new versionned secret:

{% highlight bash %}
docker secret create test_site.key.2 etc/archive/hostname/privkey2.pem
docker secret create test_site.crt.2 etc/archive/hostname/fullchain2.pem
{% endhighlight %}

### Creating the Service

Not much difference at this point as we are only referencing the versionned secrets:

{% highlight bash %}
docker service create -p 8443:443 --name nginx_test \
       --secret source=test_site.key.1,target=site.key \
       --secret source=test_site.crt.1,target=site.crt ggtools/test-nginx-ssl
{% endhighlight %}

When renewing a certificate services could be updated one at the time since the *old* secrets will still exist:

{% highlight bash %}
docker service update --secret-rm test_site.key.1 --secret-rm test_site.crt.1 \
       --secret-add source=test_site.key.2,target=site.key \
       --secret-add source=test_site.crt.2,target=site.crt nginx_test
{% endhighlight %}

This command will be completed using the *normal* service update mechanism and will stop and restart the service's tasks according to the update configuration.

### Automation

Letsencrypt and Docker secrets have a very similar philosophy with versionned immutable files/secrets which means that setting up a (basic) automation would be really simple:

{% gist ggtools/a6a963be12e91c690e804bbdd5d4c053 %}

This can be run using the `--post-hook` option or a more elaborate version could be run with `--rew-hook` option to update only the secrets from domains that have been actually updated.

In a second step, we can *inspect* the service and automatically update the services using outdated certificates. The script will be a little be more complicated as we have to retrieve the full configuration to add the renewed certificates (target, uid, gid and mode). Also total automation might not be wanted as the service updates can be triggered at any time.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
