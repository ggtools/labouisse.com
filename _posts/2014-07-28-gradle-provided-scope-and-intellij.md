---
layout: post
title: "Gradle Provided Scope and IntelliJ"
description: "A provided scope for Gradle working correctly with IntelliJ"
category:
tags: [gradle, provided, scope, intellij, dependencies]
---
{% include JB/setup %}
While Gradle is a great building tool some concepts natural to a Maven user are not (yet ?) part of the basic package. One of them is the *provided* scope.

<!--more-->
Gradle is very flexible and this missing feature is quite easy to implement: Google *gradle and provided scope* will give you many hints on how to implement this. However when it comes to make it works with IntelliJ Gradle plugin things can be a little bit more complicated.

After some *try and fail* cycles I came to the configuration below that works fine with IntelliJ:

```groovy
apply plugin: 'idea'

configurations {
    provided
    compile.extendsFrom provided
}

sourceSets {
    main { compileClasspath += [configurations.provided] }
}

idea {
    module {
        scopes.PROVIDED.plus += [configurations.provided]
    }
}

dependencies {
    provided("org.projectlombok:lombok:1.12.6")
}
```

It is working with Gradle 2.0 and IntelliJ 13.1.4 and in the project structure, the compile and provided dependencies are correctly configured.
