---
layout: post
title: "Discovering Spring Boot"
description: "My first feedback after attending a conference on Springboot"
category: libraries
lang: en
tags: [java, english, spring, spring_boot]
---
{% include JB/setup %}
[Spring Boot](http://projects.spring.io/spring-boot/) is one of the latests projects of the Spring galaxy. I discovered at the [Bordeaux JUG](http://bordeauxjug.org/) during a [session]({% post_url 2014-05-26-des-applications-reactives-avec-spring4-angulardart-et-websocket %}) by Sébastien Deleuze. The main features are: creation of standalone applications, simplified configuration and fast startup but there is more.

<!--more-->
## YASP!

Everybody knows Spring, many had work with Spring, for some if was good, for others less good. I wrote *Spring galaxy* above and that might be a valid metaphor. Sometime I feel that taking a trendy technical word and prefixing it with *Spring* gives an actual Spring project. Let's try:

- *framework* easy: [Spring Framework]()
- *social media* almost: [Spring Social]()
- *data*: [Spring Data]()
- *cloud*: [Spring Cloud]()
- *docker*: ok nothing for this one but as we will see it might not be needed with Spring Boot.

So do we need *Yet Another Spring Project*?

## Hello World!

So to give a try to Spring Boot I decided to follow the [tutorial](http://docs.spring.io/spring-boot/docs/current-SNAPSHOT/reference/htmlsingle/#getting-started-first-application). In order to have a rest service replying *Hellow World!* we only need two files: a Java file and a `pom.xml` (the use of gradle is also supported and described in the documentation).

The Java file is pretty short actually 5 lines of code or annotation, not so bad:
```java
@RestController
@EnableAutoConfiguration
public class Example {

    @RequestMapping("/")
    String home() {
        return "Hello World!";
    }

    public static void main(String[] args) throws Exception {
        SpringApplication.run(Example.class, args);
    }

}
```

For the build we are a tiny `pom.xml` with one parent, one dependency and one plugin:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.ggtools</groupId>
    <artifactId>springboot-hello</artifactId>
    <version>0.0.1-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.1.1.RELEASE</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

Keep in mind that we still have Spring MVC underneath and to measure the feat that is done by Spring Boot, have a look [here](http://www.mkyong.com/spring-mvc/spring-mvc-hello-world-example/) or [there](http://javahash.com/spring-4-mvc-hello-world-tutorial-full-example/) to see how a Spring MVC *Hello World* tutorial looks like.

To run the project you only need to have Java installed:

```bash
mvn package # if needed
java -jar target/springboot-hello-0.0.1-SNAPSHOT.jar
```

## Conclusion

Writing a *Hello World!* following the documentation is hardly testing a framework. But, for what I saw, I really have the impression that Spring Boot is a big step in the right direction: self contained executable jars out of the box, a very effective simplification either on the code or the build, and some nice features related to configuration, monitoring (easy integration of [CRaSH](http://www.crashub.org/)).

### Docker

I spoke about Docker earlier telling that there is not need for a *Spring-Docker* project and it is not really needed since a `Dockerfile` would be something like:

```
ROM java

ADD target/springboot-hello-0.0.1-SNAPSHOT.jar /tmp/application.jar

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/urandom", "-jar", "/tmp/application.jar"]
```
