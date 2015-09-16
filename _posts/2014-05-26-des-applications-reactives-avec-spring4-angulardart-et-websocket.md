---
layout: post
title: "Des applications réactives avec Spring4, AngularDart & Websocket"
description: "Présentation au Bordeaux JUG le 22 mai 2014"
category: talks
lang: fr
tags: [java, spring, dart, angular, websocket, html5, jug, mongodb, en français]
comments: true
---
[Sébastien Deleuze](https://twitter.com/sdeleuze) était l'invité du Bordeaux JUG le 22 mail dernier pour sa présentation de Devoxx France : *des applications réactives avec Spring4, AngularDart & Websocket*. Il va sans dire que la présentation était très dense et très intéressante. En quelques mots Sébastien détaillait le développement d'une application HTML5 **réactive**, performante avec de la vidéo, une communication bidirectionnelle entre client et serveur et une stack qui donne envie de l'utiliser.

L'application choisie pour illustrer la présentation était une clone de Snapchat : [Opensnap](http://opensnap.io) dont le source est disponible sur [github](https://github.com/sdeleuze/opensnap). Pour que l'application soit réactive, l'implémentation était asynchrone non-bloquante de bout en bout. Pour parvenir à ça Sébastien a mis en place la stack suivante :

- Côté serveur :
  - Java 8
  - Spring framework 4
  - Spring boot
  - Mongo DB

- Côté client :
  - Dart
  - AngularDart
  - SockJS
  - HTML5

Auxquels on ajoutera :

- Communication par Websocket
- Stomp
- Gradle pour le build

Un présentation très dense dont je retiendrai pas mal de choses :

- l'usage des [CompletatbleFutures](http://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html) introduites par Java 8 et leur support par Spring Framework 4 et Mongo DB.
- SockJS qui utilise Websocket lorsque cela est possible mais peut de manière transparente dégrader la communication vers *autre chose* lorsque le navigateur ou le réseau empêchent l'utilisation de ce protocole.
- Stomp comme surcouche à SocketJS qui implémente une communication à base de messages entre client et serveur.
- Spring Boot qui permet de créer rapidement une application Spring pour fonctionner à la fois au sein d'un container comme Tomcat ou se comporter comme une application autonome ; Spring comble ainsi un vide qui avait été pris par des bibliothèques comme [RestX](http://restx.io).
- La découverte de Dart qui, avec son transcodage vers Javascript, semble un langage crédible pour réaliser des applications HTML5 complexes.

Pour plus d'information, la présentation faite à Devoxx France est (déjà) disponible sur le site de [Parleys](http://www.parleys.com/play/535f5b7ae4b0c5ba17d434e7)
