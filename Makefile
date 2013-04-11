PREFIX=/usr/local

build:

install: build
	install -d $(PREFIX)/bin
	install pkg-epub.pl $(PREFIX)/bin/pkg-epub

