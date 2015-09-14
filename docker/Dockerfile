FROM debian

RUN apt-get update -q && \
    apt-get install -yq build-essential make zlib1g-dev ruby ruby-dev python-pygments nodejs && \
    gem install --no-rdoc --no-ri github-pages && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /blog
VOLUME /blog

EXPOSE 4000
CMD ["jekyll", "serve", "--config", "_config.yml,_config-boot2docker.yml", "-w", "-V"]
