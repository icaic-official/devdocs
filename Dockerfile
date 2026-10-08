FROM ruby:4.0.6
ENV LANG=C.UTF-8

WORKDIR /devdocs

RUN apt-get update && \
    apt-get -y install git nodejs libcurl4 libarchive-tools webp && \
    gem install bundler && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock Rakefile /devdocs/

RUN bundle config set path.system true && \
    bundle install && \
    rm -rf ~/.gem /root/.bundle/cache /usr/local/bundle/cache

ENV RACK_ENV=production
# Serve the docs from this server instead of documents.devdocs.io, don't force
# HTTPS so the image also works on plain-HTTP (offline) networks, and drop the
# devdocs.io domain warning and analytics prompt.
ENV DOCS_ORIGIN=/docs
ENV FORCE_SSL=false
ENV SELF_HOSTED=true
ENV ENABLE_SERVICE_WORKER=true

COPY . /devdocs

# Only the docs listed in config/icaic_docs.yml end up in the image.
RUN thor icaic:install && \
    thor assets:compile && \
    rm -rf /tmp/*

EXPOSE 9292
CMD ["sh", "-c", "exec rackup -o 0.0.0.0 -p ${PORT:-9292}"]
