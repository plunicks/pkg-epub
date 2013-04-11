PREFIX=/usr/local

build:

install: build
	mkdir $(PREFIX)/bin
	install pkg-epub.pl $(PREFIX)/bin/pkg-epub

