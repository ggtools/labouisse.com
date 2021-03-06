---
layout: post
title: "Handling videos with Android Annotations"
description: "My solution to handle videos through REST using Android Annotations"
category: how-to
lang: en
tags: [android, java, in english, spring, rest]
comments: true
---
Following my post on [Handling videos with RESTX]({% post_url 2014-06-03-handling-videos-with-restx %}) here is the client counterpart. I have server handling both *classical* REST calls and video operations. On the client side I already have the rest client implemented using [Spring Android](http://projects.spring.io/spring-android/) wrapped by [Android Annotations]({% post_url 2014-05-27-android-annotations %}). As I did on the server side I want to use the same system to handle both REST calls and video transfers.

Using Android annotations, the rest client will look like this:

{% highlight java %}
@Rest(converters = {MappingJackson2HttpMessageConverter.class})
@Accept(MediaType.APPLICATION_JSON)
public interface MyRestClient extends RestClientRootUrl {

    // Other methods omitted

    @Put("/videos")
    String addVideo(InputStream videoStream);

    @Get("/videos/{videoId}")
    @Accept("video/mp4")
    File getVideo(String videoId);
}
{% endhighlight %}

The issue I face with this naive implementation is the same I faced on the server side: Jackson is trying to process the video stream. The solution I used was to create a custom `HttpMessageConverter` for the video stream.

{% gist ggtools/206c244e1ee2ca6c021b %}

I had a small issue here with the `readInternal` method. Initially I wanted to pass the http stream directly but it didn't work as the http stream got closed at some point before I had time to use it. So I eventually implement a workaround by saving the video to a file.

Then in the rest client I have to add my converter:

{% highlight java %}
@Rest(converters = {VideoHttpMessageConverter.class,
                    MappingJackson2HttpMessageConverter.class})
@Accept(MediaType.APPLICATION_JSON)
public interface MyRestClient extends RestClientRootUrl {
    // Not change to the class body
}
{% endhighlight %}

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
