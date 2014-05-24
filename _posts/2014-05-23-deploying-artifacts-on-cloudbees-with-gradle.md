---
layout: post
title: "Deploying artifacts on Cloudbees with Gradle"
description: "How to deploy artifacts on Cloudbees Maven repositories when you are using Gradle"
category: how-to
tags: [java, gradle, cloud, cloudbees, jenkins, in english]
comments: true
---
{% include JB/setup %}
I use Cloudbees for Java application development using git, Jenkins, Tomcat and
the Maven repositories. Everything is nicely integrated until I start working
with Gradle: when creating a Maven job, Jenkins has a special post-build action
to deploy the artifacts onto Cloudbees' private repositories:

![Post build actions with Maven](/images/2014-05-23-001_Deploy-to-private-repository.png)

Unfortunately this item is no longer here in a Gradle project:

![Post build actions with Gradle](/images/2014-05-23-002_No-deploy-to-private-repository.png)

<!--more-->

My solution has been inspired by many internet readings, especially the one from
[AppSatori].

## What do I want?

Basically I wanted to have the artifacts of a multiple project Gradle job to be
deployed automatically on my Cloudbees's snapshot repository. I also have some
more requirements:

- Implementation should be 100% Gradle.
- Could be either run during the *build* phase or as a *post-build* step.
- Should work easily from Jenkins, IntelliJ or from the command line.
- No passwords should be commited in git (I'm paranoid, I know).

## Deployment

### Maven publish plug-ins

Gradle 1.12 ships with two plug-ins to deploy artifacts to Maven repositories:

1. the [maven](http://www.gradle.org/docs/current/userguide/maven_plugin.html) plug-in.
2. the [maven-publish](http://www.gradle.org/docs/current/userguide/publishing_maven.html) plug-in.

`Maven-publish` is the new way to deploy Maven artifacts but as Cloudbees uses
WebDAV which is not (yet) supported by `maven-publish` the `maven` plug-in was
the only choice.

### Configuration

In order to enable the artifact deployment we need to add some configuraiton
instruction in the `build.gradle` of the project we want to deploy.

#### Artifact information

In order to deploy an artifact on a Maven repository you need to define the group,
the artifact id and the version. This could be done as follow:

```groovy
group = "net.ggtools.cloudbees"
version = '0.1-SNAPSHOT'
```

I didn't explicitely defined the artifact id which will defaults to the gradle
project name.

#### Apply the plugin

```groovy
apply plugin: 'maven'
```

#### Dependencies

FWe need to add a dependency to support the WebDAV operations. We are creating
a specific configuration in order not to mix the deployment dependencies with
the  *regular* ones:

```groovy
configurations {
    deployerJars
}

dependencies {
    deployerJars "org.apache.maven.wagon:wagon-webdav:1.0-beta-2"
}
```

#### Deployer configuration

The `maven`plug-in uses the `uploadArchives` to deploy the artifacts onto the
repository the configuration will be the following:

```groovy
uploadArchives {
    repositories {
        mavenDeployer {
            configuration = configurations.deployerJars
            repository(url: "dav:https://<your-repo-url>.forge.cloudbees.com/snapshot/") {
                authentication(userName: cloudbeesUsername, password: cloudbeesPassword)
            }
        }
    }
}
```

### Credentials

This configuration will be working but there a need to supply the credentials
to make it work. [AppSatori] choose to but those credentials directly in the
`build.gradle` file by adding at the beginning:

```groovy
def cloudbeesUsername = "my.username"
def cloudbeesPassword = "You'll never find me"
```

This is working but I don't like it as it requires to have the password pushed
onto the git repository.

#### Jenkins passwords

Jenkins supports the injection of passwords when running the grade script. To
do this you have to activate *Inject passwords to the build as environment variables*
in the *Build environment* section of you job configuration:

![Inject passwords](/images/2014-05-23-003_Inject-passwords.png)

At this point you have two options: using global passwords defined in Jenkins
configuration (*Mange Jenkins* and then *Configure System*) or use job defined
passwords. I choose the global ones as this enables me to share this configuration
between jobs.

In either options you just have to declare two *passwords*, one named
`cloudbeesPassword` containing your password and one named `cloudbeesUsername`
containing your username. I might not be using this the way it was design but
doing this makes Jenkins run gradle with:

```bash
-DcloudbeesUsername=my.username -DcloudbeesPassword="You'll never find me"
```

Doing this we have a username/password configuration which no longer needs to
be pushed onto the git repository making it possible to change the credentials
without touching the source code. Another nice thing is that Jenkins takes care
of removing the password in the log pages.

#### Jenkins to Gradle

The last step is to bridge the system properties injected by Jenkins with the
Gradle variables. Quite easy to do:

```groovy
ext.cloudbeesUsername = System.properties['cloudbeesUsername']
ext.cloudbeesPassword = System.properties['cloudbeesPassword']
```

### Usage

At this point you have a working build file and you can use it by adding the
`uploadArchives` task either in the build phase or as a post-build phase and
everything should get deployed on your Cloudbees snapshot repository.

## Using the deployed artifacts

The next step will be to use the deployed artifacts from another project. This
is is quite straightforward by adding a new Maven repository:

```groovy
    repositories {
        maven {
            name "cloudbees"
            url "https://<your-repo-url>.forge.cloudbees.com/snapshot/"
            credentials {
                username cloudbeesUsername
                password cloudbeesPassword
            }
        }
    }
```

Of course you'll also need to add the system property to gradle bridge in this
project too. And *voilà* it works from Jenkins.


### Without Jenkins

If you build your project outside of Jenkins it won't work as the credentials are
not injected. The lazy approach would be to manually add `-DcloudbeesUsername=my.username
-DcloudbeesPassword="You'll never find me"` to the command line when running
`gradle`. You'll also need to tell your IDE to add those options to the build
command line too. This will be working but I discover that IntelliJ was adding
those options to a configuration file that will be committed to git.So I went
for a another solution.

I just created a `cloudbees.gradle` file in `$HOME/.gradle/init.d` with the
following contents:

```groovy
// Set system properties for cloudbees connection.

allprojects {
    if (System.properties['cloudbeesUsername'] == null) {
        logger.info("Setting default cloudbees username & password")
        System.properties['cloudbeesUsername'] = "my.username"
        System.properties['cloudbeesPassword'] = "You'll never find me"
    }
}
```

[AppSatori]: http://en.appsatori.eu/2011/08/using-gradle-with-cloudbees-maven.html
