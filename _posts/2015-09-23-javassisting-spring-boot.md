---
layout: post
title: "Javassisting Spring Boot"
modified:
categories: quicky
tags: [in english, java, spring boot, spring-boot, javassist, byte code, instrumentation]
image:
  feature:
date: 2015-09-23T15:34:55+02:00
comments: true
---

I'm a big fan of [Spring Boot](http://projects.spring.io/spring-boot/) and I'm also a very big fan [Javassist](http://jboss-javassist.github.io/javassist/). I came on an interesting issue where everything was working OK from an IDE but not when launched on a test server.

The instrumentation is pretty simple as is consists in the following code:

{% highlight java %}
public static void doBlackMagic() {
    ClassPool cp = ClassPool.getDefault();
    CtClass cc = cp.get("com.package.Class");
    // Do you stuff
    cc.toClass();
    cc.detach();
}
{% endhighlight %}

This code is called from the `main` just before calling `SpringApplication.run` in order to instrument the class before it gets any chance of being loaded during the context loading. I works fine from an IDE but once deployed on the test server it failed with a nice stack trace:

```
10:37:56.325 [main] ERROR calling.Class - Cannot perform instrumentation javassist.NotFoundException: com.package.Class
        at javassist.ClassPool.get(ClassPool.java:450) ~[javassist-3.18.1-GA.jar!/:na]
```

The diagnostic is pretty easy: from an IDE, the application runs with a *normal* classpath containing some `classes` directories and the jars for the dependencies. On the server, the application is running with Spring Boot's Über-jar as classpath. As Javassist relies on this classpath to find the class to instrument he'll only have access to the Spring Boot loader classes and the classes belonging directly to the application, but not the dependencies that are packed into the Über-jar under the `lib` directory.

## Solution

The solution is based on the `SpringApplicationRunListener` interface which will allow us to call `SpringApplication.run` and run Javassist as soon as possible. The code above will be slightly changed:

{% highlight java %}
public class Warlock implements SpringApplicationRunListener {
    private final SpringApplication application;

    public Warlock(SpringApplication application, String[] args) throws IOException {
        this.application = application;
    }

    @Override
    public void started() {
        doBlackMagic();
    }
}
{% endhighlight %}

At this point, this is not enough and the instrumentation is still failing with the same exception. The last tweak will be done in the `doBlackMagic` method:

{% highlight java %}
public void doBlackMagic() {
    ClassPool cp = ClassPool.getDefault();
    cp.appendClassPath(new LoaderClassPath(application.getClassLoader()));
    CtClass cc = cp.get("com.package.Class");
    // Do you stuff
    cc.toClass();
    cc.detach();
}
{% endhighlight %}

And *voilà*.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
