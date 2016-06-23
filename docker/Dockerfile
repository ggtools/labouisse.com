FROM ruby

# RUN apt-get update -q && \
#     apt-get install -yq build-essential make zlib1g-dev ruby ruby-dev python-pygments nodejs && \
#     gem install --no-rdoc --no-ri github-pages && \
#     rm -rf /var/lib/apt/lists/*

RUN gem install --no-rdoc --no-ri github-pages
# RUN gem install --no-rdoc --no-ri blankslate -v 2.1.2.4
# RUN gem install --no-rdoc --no-ri hitimes -v 1.2.2
# RUN gem install --no-rdoc --no-ri timers -v 4.0.1
# RUN gem install --no-rdoc --no-ri celluloid -v 0.16.0
# RUN gem install --no-rdoc --no-ri fast-stemmer -v 1.0.2
# RUN gem install --no-rdoc --no-ri classifier-reborn -v 2.0.3
# RUN gem install --no-rdoc --no-ri

ADD wrapper.sh /wrapper.sh

WORKDIR /blog
VOLUME /blog

EXPOSE 4000
CMD ["/wrapper.sh"]
