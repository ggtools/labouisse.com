---
layout: post
title: "Retour sur Lombok"
description: "Courte introduction à Lombok."
category: libraries
lang: fr
tags: [java, français, lombok]
---
Parmis les projets que j'affectionne il y a [Lombok](http://www.projectlombok.org). En quelques mots, Lombok se charge d'écrire à votre place certaines parties du code qui, bien qu'indispensables, ne sont pas particulièrement enrichissantes à écrire.

## Fonctionnalités

Lombok vous permet donc, via le jeu d'annotations, d'écrire pour vous :

- les accesseurs ;
- les contructeurs simples ;
- les methodes telles que `toString()`, `equals()` et `hashCode()`.



Bien sûr, les IDE ou des bibliothèques comme [Guava](https://code.google.com/p/guava-libraries/) permettent d'automatiser ou d'aider pour ces tâches mais on voit tout de suite les avantages de Lombok sur un simple exemple.

### Petit exemple

On imagine une classe avec 4 attributs : un sera `final`, un autre sera en lecture seule, un troisième ne sera visible que des classes filles et un dernier n'aura pas de restriction d'accès.

Sans Lombok, en générant les méthodes avec IntelliJ, la classe ressemblera à ça :

{% gist ggtools/7d8cbfbbc5f0f615edc8 %}

Avec Lombok la classe se réduira à :

{% gist ggtools/e215f4e7e68c0a1a88bf %}

On voit tout de suite que Lombok gagne sur le plan de la lisibilité en permettant d'avoir un code qui n'est pas les accesseurs et autres.

En plus de cette lisibilité accrue Lombok garanti la cohérence entre les attributs de la classe et les méthodes implémentées : ajouter un attribut l'ajoutera automatiquement aux méthodes `equals()` et `hashCode()`, par exemple.

Outre la création de ces méthodes Lombok possèdent d'autres fonctionnalités : des trucs de fainéant (lire développeur efficace) comme la création automatique du logger pour la classe (avec Commons Logging, java util logging, log4j ou slf4j) ainsi que des trucs qui ne me convainquent pas totalement comme le `@SneakThrows`.

Détail important : Lombok travaille lors de la compilation en générant du code de manière transparente. L'utilisation des méthodes *Lombokisées* n'implique donc pas de dégradation de performance par rapport à des méthodes écritent à la main.

## Utilisation

On ne peut pas faire plus simple. Si vous utilisez Maven il vous suffit d'ajouter une dépendence vers Lombok :

{% highlight xml %}
<dependencies>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>1.12.6</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
{% endhighlight %}

Notez le `<scope>provided</scope>` qui montre que Lombok fait son travail à la compilation et ne demande pas d'ajouter un nouveau jar à l'application.

### Avec les IDE

Si vous utilisez Eclipse le jar Lombok possède un installeur qui va s'ajouter dans le classpath de l'IDE. Eclipse travaillant à partir des `.class` le support est excellent.

Avec IntelliJ c'est un peu moins facile mais le plug-in qui a été pendant pas mal de temps en sommeil est actuellement reguièrement mis à jour. IntelliJ travaillant à partir des fichiers sources utiliser Lombok peut provoquer dans certains cas des warnings intempestifs.

### Marre de Lombok ?

Et bien c'est prévu Lombok est livré avec l'outil
[delombok](http://www.projectlombok.org/features/delombok.html). Celui-ci de créer des fichiers sources comprenant le code généré par Lombok.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
