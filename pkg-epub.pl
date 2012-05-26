#!/usr/bin/perl

use strict;
use utf8;
use encoding qw(utf8);
use open qw(:encoding(utf8));

use EBook::EPUB;
use File::Basename qw(basename);

# Create EPUB object
my $epub = EBook::EPUB->new;

my ($outfile, $author, $title) = @ARGV;
shift;shift;shift;

# Set metadata: title/author/language/id
$epub->add_title("$title");
$epub->add_author("$author");
$epub->add_language('en'); # assumption for now
# $epub->add_identifier('1440465908', 'ISBN');
#$epub->add_translator(...);

use File::Basename;
my $play_order = 1;
open my $fh, "files/list";
# must past args in correct order
while (my $file = shift @ARGV) {
    chomp $file;

    my $basename = basename($file);
    my ($base, $ext) = $basename =~ /^(.*)\.([^.]+)$/;

    if ($ext eq 'css') {
        my $chapter_id = $epub->copy_stylesheet($file, $basename);
        print "css file\n";
    } elsif ($ext eq 'jpg') {
        my $chapter_id = $epub->copy_image($file, $basename, 'image/jpeg');
        print "jpg file\n";
    } elsif ($ext eq 'png') {
        my $chapter_id = $epub->copy_image($file, $basename, 'image/png');
        print "png file\n";
    } elsif ($ext =~ /gif/i) {
        my $chapter_id = $epub->copy_image($file, $basename, 'image/gif');
        print "gif file\n";
    } elsif ($ext eq 'js') {
        my $chapter_id = $epub->copy_file($file, $basename, 'application/javascript');
        print "js file\n";
    } else {
        my $label = basename($file, '.html', '.xhtml', '.htm');
        $label =~ s/- 0*(\d+)$/$1/;
        my $chapter_id = $epub->copy_xhtml($file, $basename);
        print "epub file $file => $label | $basename | $chapter_id | $play_order\n";

        my $navpoint = $epub->add_navpoint(
            label       => $label,
            id          => $chapter_id,
            content     => $basename,
            play_order  => $play_order++,
            );
        print "  $navpoint\n";
    }
}

$epub->pack_zip("$outfile");

use Data::Dumper::Concise;
print Dumper $epub;
