# File Scraper Reference

This lists the docs that use `FileScraper` and instructions for building some of them.

Most scrapers fetch their documents themselves — see `download_source` in
`lib/docs/core/scrapers/file_scraper.rb`. The sections below cover the ones that
still need the documents to be built or assembled by hand.

If you open a PR to update one of these docs, please add/fix the instructions.

## date-fns

```sh
git clone https://github.com/date-fns/date-fns docs/date_fns
cd docs/date_fns
git checkout v2.29.2
yarn install
node scripts/build/docs.js
ls tmp/docs.json
```

## gensim

radimrehurek.com/gensim only serves the documentation of gensim 4.3.3. Build that
of the release in `lib/docs/scrapers/gensim.rb` from its sources (Sphinx 5 needs
Python 3.12 or older; the tutorials' output is committed, so they aren't run).
`sphinx.ext.mathjax` replaces `sphinx.ext.imgmath`, which needs LaTeX, so that the
math stays TeX for the `sphinx/math` filter:

```sh
DEVDOCS_ROOT=/path/to/devdocs
RELEASE=4.4.0
docker run --rm -v $DEVDOCS_ROOT/docs/gensim:/out python:3.11 bash -ec "
  git clone -q --depth 1 --branch $RELEASE https://github.com/piskvorky/gensim.git /src
  cd /src
  pip -q install cython numpy scipy smart_open 'sphinx==5.1.1' 'sphinx-gallery==0.11.1' \
    'sphinxcontrib.programoutput==0.17' sphinx_rtd_theme matplotlib memory_profiler \
    scikit-learn nltk pandas testfixtures 'Jinja2<3.2'
  python setup.py -q build_ext --inplace
  cd docs/src && sphinx-build -q -b html -j 4 -D autodoc_mock_imports=Pyro4,nmslib \
    -D extensions=sphinx.ext.autodoc,sphinx.ext.napoleon,sphinx.ext.mathjax,sphinxcontrib.programoutput,sphinx_gallery.gen_gallery \
    . /out"
```

## Gnuplot

The most recent release can be found near the bottom of
https://sourceforge.net/p/gnuplot/gnuplot-main/ref/master/tags/

```sh
DEVDOCS_ROOT=/path/to/devdocs
mkdir gnuplot-src $DEVDOCS_ROOT/docs/gnuplot
git clone -b $RELEASE --depth 1 https://git.code.sf.net/p/gnuplot/gnuplot-main ./gnuplot-src
cd gnuplot-src/
./prepare
./configure
cd docs/
make nofigures.tex
latex2html -html 5.0,math -split 4 -link 8 -long_titles 5 -dir $DEVDOCS_ROOT/docs/gnuplot -ascii_mode -no_auto_link nofigures.tex
```

To install `latex2html` on macOS: `brew install basictex latex2html`, then edit
`/usr/local/Cellar/latex2html/2019.2/l2hconf.pm` to include the path to LaTeX:

<details>

On line 21 (approximately):

```
#  Give the paths to latex and dvips on your system:
#
$LATEX = '/Library/TeX/texbin/latex';	# LaTeX
$PDFLATEX = '/Library/TeX/texbin/pdflatex';	# pdfLaTeX
$LUALATEX = '/Library/TeX/texbin/lualatex';	# LuaLaTeX
$DVILUALATEX = '/Library/TeX/texbin/dvilualatex';	# dviLuaLaTeX
$DVIPS = '/Library/TeX/texbin/dvips';	# dvips
$DVIPNG = '';	# dvipng
$PDFTOCAIRO = '/usr/local/bin/pdf2svg';	# pdf to svg converter
$PDFCROP = '';	# pdfcrop
$GS = '/usr/local/opt/ghostscript/bin/gs';	# GhostScript
```
</details>

## Man

```sh
wget --recursive --no-parent https://man7.org/linux/man-pages/
mv man7.org/linux/man-pages/ docs/man/
```

## NLTK

www.nltk.org only serves the documentation of NLTK 3.9.2. Build that of the
release in `lib/docs/scrapers/nltk.rb` from its sources, in a Python container
(it has Tkinter, which `nltk.draw` needs):

```sh
DEVDOCS_ROOT=/path/to/devdocs
RELEASE=3.10.4
docker run --rm -v $DEVDOCS_ROOT/docs/nltk:/out python:3.13 bash -ec "
  git clone -q --depth 1 --branch v$RELEASE https://github.com/nltk/nltk.git /src
  pip -q install 'sphinx<7' 'sphinxcontrib-apidoc<0.5' nltk_theme jinja2 /src \
    numpy scipy scikit-learn matplotlib pyparsing twython requests python-crfsuite
  python -m nltk.downloader -q perluniprops
  cd /src/web && sphinx-build -q -b html -j 4 . /out"
```

`nltk_theme` doesn't work with Sphinx 7. Only `nltk.book` fails to import (it
needs the book's corpora), as on www.nltk.org.

## OpenJDK
Search 'Openjdk' in https://www.debian.org/distrib/packages, find the `openjdk-$VERSION-doc` package,
download it, extract it with `dpkg -x $PACKAGE ./` and move `./usr/share/doc/openjdk-$VERSION-jre-headless/api/`
to `path/to/devdocs/docs/openjdk~$VERSION`

```sh
curl -O http://ftp.at.debian.org/debian/pool/main/o/openjdk-25/openjdk-25-doc_25+36-1_all.deb
tar xf openjdk-25-doc_25+36-1_all.deb
tar xf data.tar.xz
mv ./usr/share/doc/openjdk-25-jre-headless/api/ docs/openjdk~25
```

If you use or have access to a Debian-based GNU/Linux distribution you can run the following command:
```sh
apt download openjdk-$VERSION-doc
dpkg -x $PACKAGE ./
# previous command makes a directory called 'usr' in the current directory
mv ./usr/share/doc/openjdk-$VERSION-jre-headless/api/ docs/openjdk~$VERSION
```

## R

```bash
sudo dnf install bzip2-devel
sudo dnf install gcc-gfortran
sudo dnf install libcurl-devel
sudo dnf install texinfo
sudo dnf install xz-devel

DEVDOCSROOT=docs/r
RLATEST=https://cran.r-project.org/src/base/R-latest.tar.gz # or /R-${VERSION::1}/R-$VERSION.tar.gz

RSOURCEDIR=${TMPDIR:-/tmp}/R/latest
RBUILDDIR=${TMPDIR:-/tmp}/R/build
mkdir -p "$RSOURCEDIR" "$RBUILDDIR" "$DEVDOCSROOT"

# Download, configure, and build with static HTML pages
curl "$RLATEST" | tar -C "$RSOURCEDIR" -xzf - --strip-components=1
(cd "$RBUILDDIR" && "$RSOURCEDIR/configure" --enable-prebuilt-html --with-recommended-packages --disable-byte-compiled-packages --disable-shared --disable-java --with-readline=no --with-x=no)
make _R_HELP_LINKS_TO_TOPICS_=FALSE -C "$RBUILDDIR"

# Export all html documentation built − global, and per-package
cp -r "$RBUILDDIR/doc" "$DEVDOCSROOT/"
ls -d "$RBUILDDIR"/library/*/html | while read orig; do
    dest="$DEVDOCSROOT${orig#$RBUILDDIR}"
    mkdir -p "$dest" && cp -r "$orig"/* "$dest/"
done
```

## RDoc

### Ruby / Minitest

```sh
git clone https://github.com/minitest/minitest
cd minitest/
echo -e "source 'https://rubygems.org'\n\ngem 'hoe'\ngem 'rdoc', '< 7'" > Gemfile
bundle install
bundle exec rake docs
cp -r docs $DEVDOCS/docs/minitest
```

### Ruby / Rack

```sh
git clone https://github.com/rack/rack
cd rack/
sed -i 's/gem "rdoc"/gem "rdoc", "<7"/' Gemfile
bundle install
bundle exec rdoc
cp -r doc $DEVDOCS/docs/rack
```

### Ruby on Rails
* Run `git clone --branch v$RELEASE --depth 7 https://github.com/rails/rails.git && cd rails`
* Open `railties/lib/rails/api/task.rb` and comment out any code related to sdoc (`configure_sdoc`)
* Run `bundle config set --local without 'db job'` (in the Rails directory)
* Run `bundle install && bundle exec rake rdoc` (in the Rails directory)
* Run `cd guides && bundle exec rake guides:generate:html && cd ..`
* Run `cp -r guides/output html/guides`
* Run `cp -r html $DEVDOCS/docs/rails~$VERSION`

### Ruby
Download the tarball of Ruby from https://www.ruby-lang.org/en/downloads/, extract it, run
`./configure && make html` in your terminal (while your are in the ruby directory) and move
`.ext/html` to `path/to/devdocs/docs/ruby~$VERSION/`.

Or run the following commands in your terminal:
```sh
curl https://cache.ruby-lang.org/pub/ruby/$VERSION/ruby-$RELEASE.tar.gz > ruby.tar; \
tar -xf ruby.tar; cd ruby-$RELEASE; ./configure && make html; mv .ext/html path/to/devdocs/docs/ruby~$VERSION
```

To generate the htmls file you have to run `make` command but it does not install Ruby in your system, only generates html files so you have not
to worry about cleaning or removing a new Ruby installation.

## Sentence Transformers

sbert.net only serves the documentation of the latest release. Build that of the
release in `lib/docs/scrapers/sentence_transformers.rb` from its sources. torch,
torchvision and transformers are pinned to the releases of the ICAIC appendix:
autodoc fails on every class when they don't match.

```sh
DEVDOCS_ROOT=/path/to/devdocs
RELEASE=6.0.1
docker run --rm -v "$DEVDOCS_ROOT/docs/sentence_transformers~6.0:/out" python:3.13 bash -ec "
  git clone -q --depth 1 --branch v$RELEASE https://github.com/huggingface/sentence-transformers.git /src
  pip -q install 'torch==2.14.*' 'torchvision==0.29.*' --index-url https://download.pytorch.org/whl/cpu
  pip -q install '/src[train,image]' 'transformers==5.17.*' --group /src/pyproject.toml:docs
  cd /src/docs && sphinx-build -q -c . -a -E -j 4 .. /out"
```
