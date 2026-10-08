# Deploying the ICAIC 2026 DevDocs

This repository is [DevDocs](https://github.com/freeCodeCamp/devdocs) limited to the
documentation of the components listed in the
[ICAIC 2026 technical appendix](https://icaic-official.github.io/docs/technical-appendix.html):
Python 3.13 and the Python packages of section 2. Nothing else is installed or shown.

The selection lives in [`config/icaic_docs.yml`](config/icaic_docs.yml), one entry per
appendix item. Docs come from one of two places:

- `docs-packages/<doc>.tar.gz`, for docs built by this repository's scrapers (committed);
- otherwise downloads.devdocs.io, for docs DevDocs already publishes (Python, PyTorch,
  scikit-learn, NumPy, pandas, Polars and scikit-image).

`thor icaic:install` then embeds every image that is still remote (those of the
devdocs.io packages and a few large ones in the Hugging Face docs) into the docs, so they
are complete without internet access. It prints a warning for any image it can't fetch;
four images are broken at their source (one in TRL, three in Transformers).

Three docs are of a slightly different release than the appendix lists, because the
projects' sites don't publish the docs of that release: NLTK 3.9.2 (appendix: 3.10),
gensim 4.3.3 (4.4) and Sentence Transformers 6.1.0 (6.0, same API).

## Docker (recommended)

The image is self-contained: the docs are installed when it's built, so the running
container needs no internet access. It is about 4.9 GB (1.5 GB compressed), 1.4 GB of
which are the docs.

```sh
docker build -t icaic-devdocs .
docker run --rm --init -p 9292:9292 icaic-devdocs
# → http://localhost:9292
```

Building needs internet access (Ruby gems, downloads.devdocs.io and the images embedded
by `thor icaic:install`) and takes about 10 minutes. To move the image to an offline
machine:

```sh
docker save icaic-devdocs | gzip > icaic-devdocs.tar.gz   # about 1.5 GB
# on the offline machine
docker load < icaic-devdocs.tar.gz
docker run -d --restart unless-stopped --init -p 80:9292 --name devdocs icaic-devdocs
```

Browsers can also keep the docs themselves: in the app, **Offline Data** installs any doc
in the browser, after which it works without the server.

Environment variables (already set in the image):

| Variable | Value in image | Purpose |
| --- | --- | --- |
| `RACK_ENV` | `production` | Precompiled, minified assets. |
| `DOCS_ORIGIN` | `/docs` | Serve docs from this server rather than documents.devdocs.io. |
| `FORCE_SSL` | `false` | Don't redirect to HTTPS; set to `true` when served over HTTPS. |
| `SELF_HOSTED` | `true` | No "must be loaded from devdocs.io" warning, no analytics. |
| `PORT` | `9292` | Port the server listens on. |

## Without Docker

Requires Ruby 4.0.6, bundler and `bsdtar` (libarchive-tools).

```sh
bundle install
thor icaic:install            # installs exactly the docs in config/icaic_docs.yml, embedding their images
thor assets:compile
RACK_ENV=production DOCS_ORIGIN=/docs FORCE_SSL=false SELF_HOSTED=true \
  bundle exec rackup -o 0.0.0.0 -p 9292
```

## Lapiz branch preview

The preview builds the image and runs it on port 9292:

- setup: `docker rm -f icaic-devdocs-preview || true`, then `docker build -t icaic-devdocs .`
- start: `exec docker run --rm --init --name icaic-devdocs-preview -p 9292:9292 icaic-devdocs`

## Adding or updating a doc

1. Write or update the scraper in `lib/docs/scrapers` (and its filters in `lib/docs/filters`).
2. Build it into `docs-packages/`: `thor icaic:build <name>` (or `<name>@<version>`); `--jobs 3`
   parses the pages of docs scraped from files (e.g. the Hugging Face ones) in parallel.
   Scrapers skip pages that fail to download, so compare the new package's page count with
   the old one's (`tar xzf … db.json`) and build again if pages are missing.
3. Set the entry's `doc` in `config/icaic_docs.yml` to the doc's slug.
4. Commit the scraper, the package and the config, then rebuild the image.

`thor icaic:status` lists every appendix item with the doc that covers it, and where
it's installed from.
