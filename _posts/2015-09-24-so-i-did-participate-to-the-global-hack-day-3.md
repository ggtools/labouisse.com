---
layout: post
title: "So, I Did Participate to the Global Hack Day #3"
modified:
categories: misc
tags: [in english, docker, compose, git, notary, Global Hack Day, global-hack-day-3]
comments: true
date: 2015-09-24T08:32:45+02:00
---

So I eventually submit [my contribution]() to Docker's [Global Hack Day #3](https://www.docker.com/community/hackathon). While I'm pretty sure that some [people](http://blog.loof.fr/2015/09/introducing-docker-slaves-jenkins-plugin.html) had though about their hack for quite a long time, I had absolutely no idea that I'll submit git-notary, when Global Hack Day #3 did start.

## `my-life.io`

Having a busy job schedule and an equally busy week-end with [les journées du patrimoine](http://journeesdupatrimoine.culturecommunication.gouv.fr/) I didn't plan to attend to GHD#3; well at least until I had an idea…

Acting often as the [security](https://jasig.github.io/cas/4.0.x/index.html) [guy](http://oauth.net/2/) on the projects I work on, I've been looking greedily to [Notary](https://github.com/docker/notary). My initial plan was to create a system to distribute docker-compose applications relying on Notary to secure it. That implies creating a kind on packaging for Compose applications (*i.e.*: a glorified tar/cpio) and use something like Bintray or a Maven artifact repository to actually store the Compose packages. But at one point I realize that one of the most convenient way to distribute Compose applications was git.

## Here Comes Git Notary

Using git as distribution support resulted in a dramatic simplification of the system as it should only take care of the *trust* part leaving the actual distribution to git. From this I arbitrarily decided that wanted to focus on *released* versions and only certify the tags.

Git already have a powerful feature to sign tags (and commits) using GPG and the initial idea would be to hack the `git-tag` command to introduce a new option, for instance `-N`. Even if hacking git would have been possible in a timely manner, this option is far from the best one for a widespread usage as it'll require all users to have specific and recent version of git. I finally choose to create a new git sub-command: git-notary.

## Workflow

### Creator side

1. The first thing to do is to choose the notary collection, in real life it could be the github URL of the project.

1. The next setup would be to create the tag and add it locally to the notary collection. The name assigned to the git tag will also be used to identify it within the notary collection. The git tag as returned by `git show <tag>` will be feed to notary as contents.

1. Following git workflow the next step will be to push the tag and to publish it to notary.

### Receiver side

1. The first thing to do is to choose the notary collection, in real life it could be the github URL of the project.

1. Get the git tag through git and use notary to check the tag contents against what has been published on notary.

## Implementation

Implementation submitted to GHD#3 is a simple shell implementation closer to a Proof Of Concept than from a production ready version. Each of the step above is mapped to a `git-notary` sub-command: `init`, `tag`, `push` and `verify`. The  [README](https://github.com/ggtools/global-hack-day-3/blob/master/docker-bdx/README.md) gives a more detailed version of `git-notary` usage plus a nice animated gif demo.

## Future

For a future version the most obvious thing to do will be to improve greatly the POC. As a fact I already started a Go version based on [git2go](https://github.com/libgit2/git2go) and Notary client side code. However there are probably some things to be tweaked in the workflow itself.

The first thing it that I really don't like to be forced to use a custom command to push notarized tags. In my opinion when a tag has already been added to notary, pushing it should trigger its publication. This cannot be implemented straightforwardly in a `pre-push` hook as git is using stdin to send the script the references to be pushed and as `notary publish` requires the user to enter a password. Something like a *notary agent* would help but there might be other ways.

Another nice thing would be to verify automatically the pulled tags. This'll be quite easy starting from the `update.sample` hook provided by git and enable this behavior based on the `GIT_CONTENT_TRUST` environment variable. It would be equally easy to implement a server-side hook to reject unsigned tags.

Then regarding the workflow itself I made the choice of not adding anything in the notarized tags' annotations. The main arguments for this choice is that I do not need it as having store the collection's name during the `git notary init` phase nothing else was required for the verification process. I also think that relying on the configured collection name is more secure than storing it in the tag's annotation since tampering with a tag cannot make the receiver side use a different collection name. Beside, it will also open the possibility to have the same tag notarized in different collections. In a nutshell I think that's a good choice but I'd love to discuss it.

My *one more thing* would be be able to have git notary fills its original purpose: secure the distribution of Docker Compose applications.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
