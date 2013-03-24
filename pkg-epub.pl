#!/usr/bin/perl

use strict;
use utf8;
use encoding qw(utf8);
use open qw(:encoding(utf8));
use Getopt::Long qw(:config gnu_getopt no_ignore_case);
use EBook::EPUB;
use File::Basename qw(basename);

my %opt;
GetOptions(
    'out|outfile|o=s' => \$opt{outfile},
    'author|a=s@' => \$opt{authors},
    'title|t=s' => \$opt{title},
    'directory|C=s' => sub { chdir $_[1] },
);
die "Usage: @{[basename $0]} -o OUTFILE -a AUTHOR -t TITLE FILES\n" unless
    $opt{outfile} && $opt{authors} && $opt{title};

# Create EPUB object
my $epub = EBook::EPUB->new;

# Set metadata: title/author/language/id
$epub->add_title("$opt{title}");
$epub->add_author("$_") foreach @{$opt{authors} || []};
$epub->add_language('en'); # assumption for now
# $epub->add_identifier('1440465908', 'ISBN');
#$epub->add_translator(...);

use File::Basename;
my $play_order = 1;
open my $fh, "files/list";
# must past args in correct order
while (my $file = shift @ARGV) {
    chomp $file;

    my $destfile = $file;
    my ($base, $ext) = $file =~ /^(.*)\.([^.]+)$/;

    if ($ext eq 'css') {
        my $chapter_id = $epub->copy_stylesheet($file, $destfile);
        print "css file\n";
    } elsif ($ext eq 'jpg' or $ext eq 'jpeg') {
        my $chapter_id = $epub->copy_image($file, $destfile, 'image/jpeg');
        print "jpg file\n";
    } elsif ($ext eq 'png') {
        my $chapter_id = $epub->copy_image($file, $destfile, 'image/png');
        print "png file\n";
    } elsif ($ext =~ /gif/i) {
        my $chapter_id = $epub->copy_image($file, $destfile, 'image/gif');
        print "gif file\n";
    } elsif ($ext eq 'js') {
        my $chapter_id = $epub->copy_file($file, $destfile, 'application/javascript');
        print "js file\n";
    } else {
        my $label = basename($file, '.html', '.xhtml', '.htm');
        $label =~ s/- 0*(\d+)$/$1/;
        my $chapter_id = $epub->copy_xhtml($file, $destfile);
        print "epub file $file => $label | $destfile | $chapter_id | $play_order\n";

        my $navpoint = $epub->add_navpoint(
            label       => $label,
            id          => $chapter_id,
            content     => $destfile,
            play_order  => $play_order++,
            );
        print "  $navpoint\n";
    }
}

$epub->pack_zip("$opt{outfile}");

use Data::Dumper::Concise;
print Dumper $epub;
