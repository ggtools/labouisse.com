---
layout: post
title: "Ippevent MongoDB à Bordeaux"
description: "Premier ippevent à Bordeaux avec Tugdual Grall"
category: talks
tags: [mongodb, français, tgrall, ippevent]
lang: fr
---
À l'occasion du premier [Ippevent](http://blog.ippon.fr/inscription-aux-ippevents/) organisé sur Bordeaux [Ippon](http://www.ippon.fr/) avait invité [Tugdual Grall](https://twitter.com/tgrall) pour une présentation de MongoDB. Devant une salle comble composée en majorité de développeurs Java JEE,  Tugdual s'est livré à une présentation de deux heures qui s'est rapidement éloignée des slides au fil des questions du public. Mon résumé de faux débutant :

<!--more-->
En début de présentation Tugdual a indiqué que le principal problème lors de l’adoption de NoSQL pour les dév est la culture en base des données relationnelles. Lapidaire mais après avoir assisté à la conférence je trouve que cela résume bien mes expériences avec MongoDB.

## La diversité en NoSQL

Par rapport aux SGBD relationels qui ont tous plus ou moins les même fonctionnalités, le monde NoSQL est plus riche, plus diversifié et aussi plus segmenté. [NoSQL](http://nosql-database.org/) recense actuellement 150 base de données NoSQL différentes. Il est important de choisir la base de données adaptée à ses besoins qui n'est pas nécessairement MongoDB. Dans des applications *fortement transactionnelles* comme du paiement électronique une base de données relationnelles peut-être préférable (voir [l'attaque](http://www.infoq.com/news/2014/04/bitcoin-banking-mongodb) contre [Flexcoin](http://flexcoin.com/)).

## Flexibilité de la structure des données

Si les collections et les documents dans MongoDB sont analogues aux tables et aux lignes d'une base de données relationnelle, ils sont beaucoup plus flexibles :

- il n'est pas nécessaire de déclarer prélablement la structure des documents avant des le stocker ;
- une collection peut accueillir des documents de structures différentes ;
- les documents étant similaire à du JSON il est possible d'y stocker des types *simples* mais aussi des tableaux ou des données structurées ;
- on peut sans interruption de service modifier la structure des documents déjà stockés.

L'idée et donc d'utiliser au mieux cette flexibilité par exemple :

- stocker dans une même collection des documents similaires même s'ils n'ont pas pas exactement la même structure (l'exemple des articles d'un site de e-commerce avec des caractérisques communes et d'autres uniques) ;
- privilégier le développement itératif plutôt qu'essayer de prévoir un modèle intégrant dès le départ des besoins futurs ;
- stocker dans un même document l'ensemble des données afin de pouvoir tout retrouver en une seule opération (bonus, MongoDB est capable de faire des mises à jour ou des lectures d'un sous-ensemble des attributs).

## La dénormalisation c'est bon

En continuant sur la lancée du dernier point on arrive rapidement à dénormalizer le schéma en dupliquant les données dans différents documents.On a ainsi toutes les données en une seule requête. Comme l'a fait remarqué un des spectateurs la conception du modèle de données se fait alors plus à partir des données à afficher sur les écrans.

Au technique intéressante : celle du *bucketing*. Dans l'exemple donné, on imagine une application de e-commerce avec des commentaires associés à chaque article. On va donc stocker un sous ensemble des commentaires (10 derniers par exemple) directement dans l'article et les autres dans une collection dédiée.

Pour terminer sur le sujet des données il est évident que l'absence de vérification de l'intégrité référentielle déplace cette fonctionnalité côté applicatif.

## Clustering

Dans la plupart des SGBD relationnels il n'est possible de faire de la haute-disponiblité ou de la répartition de charge sans devoir ajouter quelque chose au SGBD en lui même. MongoDB intègre ces fonctionnalités directement :

- haute-disponibilité via un système de réplication avec un système actif/passif
- repartition de charge grâce au *[sharding](http://docs.mongodb.org/manual/core/sharding-introduction/)* qui va répartir les différents documents sur des instances ou des clusters différents.

Dans ce dernier système, la répartition s'effectuant à partir d'une clé de sharding il est important de choisir celle-ci en fonction des besoins. L'exemple pris est celui d'une base de clients que l'on interroge souvent en fonction de leur pays : un clé aléatoire (numéro de client) obligera à interroger l'ensemble des instances alors qu'une clé passé sur la région (US, Europe, etc.) permettrait de ne s'adresser qu'à un sous-ensemble des instances.

## En vrac

Le shell de Mongo est en Javascript on peut donc créer des variables, des fonctions, etc. Pour qui a dû souffrir avec SQL*Plus c'est un soulagement.

Les write-concerns peuvent être utiliser pour choisir un compromis vitesse/sécurité au niveau de chaque requête. Par exemple utiliser le write-concern par défault qui ne garanti que l'écriture sur le primaire lorsqu'un client ajoute un article à son panier mais utiliser un write-concern *majority* qui va garantir l'écriture sur la majorité des instances pour le passage de la commande.

MongoDB supporte des données et des opérateurs géographiques. Plus de détails sur [le blog de Tugdual](http://tugdualgrall.blogspot.fr/2014/08/introduction-to-mongodb-geospatial.html).

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
