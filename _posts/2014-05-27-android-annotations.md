---
layout: post
title: "Android Annotations"
description: "Présentation de la bibliothèque AndroidAnnotations"
category: android
lang: fr
tags: [java, android, en français]
comments: true
---
J'ai commencé il y a quelques semaines le développement Android et je suis tombé sur une bibliothèque carrément sympa pour simplifier le développement Android : [Android Annotations](https://github.com/excilys/androidannotations/wiki).

En quelques mots, la programmation Android est très verbeuse avec beaucoup de classes anonymes, de callbacks dès que l'on veut faire du multithread, etc. Android Annotations propose donc de se charger de la plomberie grâce à des annotations Java lors de la compilation. On trouve entre autres :

- Injection de dépendences ;
- Simplification de l'API pour les threads ;
- Client REST.

## Exemples

### Démarrer une autre activité

Pour [démarrer une autre activité](https://developer.android.com/training/basics/firstapp/starting-activity.html) sans AA il faut donc :

- Créer une constante qui servira de clé pour retrouver la donnée passée d'une activité à l'autre ;
- Créer un `intent` dans la première activité ;
- Lancer l'activité à partir de l'`intent` ;
- Récupérer la donnée passer dans les *extras* de l'intent dans la nouvelle activité.

Côté première activité on a donc :

{% highlight java %}
public class MainActivity extends Activity {
    public final static String EXTRA_MESSAGE = "com.example.myfirstapp.MESSAGE";

    public void sendMessage() {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        EditText editText = (EditText) findViewById(R.id.edit_message);
        String message = editText.getText().toString();
        intent.putExtra(EXTRA_MESSAGE, message);
        startActivity(intent);
    }
}
{% endhighlight %}

Et côté seconde :

{% highlight java %}
public class DisplayMessageActivity extends ActionBarActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        // ...
        Intent intent = getIntent();
        String message = intent.getStringExtra(MainActivity.EXTRA_MESSAGE);
        // ...
    }
}
{% endhighlight %}

Avec AA le code ressemblerait à, pour la première activité :

{% highlight java %}
@EActivity(R.layout.activity_main)
public class MainActivity extends Activity {
    @ViewById
    protected EditText editText;

    public void sendMessage() {
        DisplayMessageActivity_.intent(getContext()).message(editText.getText().toString()).start();
    }
}
{% endhighlight %}

Et pour la seconde :

{% highlight java %}
@EActivity(R.layout.activity_display_message)
public class DisplayMessageActivity extends ActionBarActivity {
    @Extra
    protected String message;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        // ...
        // Rien en fait la donnée de l'intent est directement injectée dans
        // le champ message
        // ...
    }
}
{% endhighlight %}

C'est clairement plus court avec une jolie API *fluent* du plus bel effet et surtout on évite les erreurs de type sur la données passée ou sur la clé à utiliser.

### Tâches en arrière plan

Comme dans d'autres système, il faut éviter d'effectuer des opérations trop longue dans le thread de l'UI. Sur un scénario simple où un click déclenche une opération assez longue qui doit au final mettre à jour l'UI on aura avec Android Annotations quelque chose qui ressemblera à ça :

{% highlight java %}

public void onClick() {
    longOperation(arg);
}

@Background
public void longOperation(String myArg) {
    // Do long operation
    updateUI(message);
}

@UiThread
public void updateUI(String message) {
    // Update the UI with the message.
}
{% endhighlight %}

Sans AA le résultat serait nettement plus verbeux.

## Pour la fin

Mon plus *grand* reproche à Android Annotations est lié à la manière dont il est implémenté. En effet lors du traitement des annotations, Android Annotations génère des classes filles avec un `_` à la fin. De ce fait tout ce qui reçoit une annotation doit être accessible par cette classe ce qui interdit d'utiliser les annotations sur des attributs ou des méthodes `private`. L'approche de [Lombok](/libraries/2014/05/28/retour-sur-lombok/) bien que plus complexe à mettre en œuvre est plus élégante.

Et puis finalement Android Annotations marche très bien, trop bien même et finalement je me dis que j'aurais dû attendre un peu avant de l'utiliser pour souffrir encore un peu et pour mieux comprendre le fonctionnement intrisèque du développement Android. Au final j'aurais été nettement plus content de découvrir Android Annotations.

<section id="table-of-contents" class="toc">
<header>
<h3>Overview</h3>
</header>
<div id="drawer" markdown="1">
*  Auto generated table of contents
{:toc}
</div>
</section><!-- /#table-of-contents -->
