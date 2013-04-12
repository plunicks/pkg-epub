#!/usr/bin/perl

use strict;
use utf8;
use encoding qw(utf8);
use open qw(:encoding(utf8));
use Getopt::Long qw(:config gnu_getopt no_ignore_case);
use EBook::EPUB;
use File::Basename qw(basename);

my %opt = (
    language => 'en',
);
GetOptions(
    'out|outfile|o=s' => \$opt{outfile},
    'author|a=s@' => \$opt{authors},
    'title|t=s' => \$opt{title},
    'language|l=s' => \$opt{language},
    'directory|C=s' => sub { chdir $_[1] },
    'strip-components=i' => \$opt{strip_components},
    'debug' => \$opt{debug},
);
die "Usage: @{[basename $0]} -o OUTFILE -a AUTHOR -t TITLE FILES\n" unless
    $opt{outfile} && $opt{authors} && $opt{title};

# Create EPUB object
my $epub = EBook::EPUB->new;

# Set metadata: title/author/language/id
$epub->add_title("$opt{title}");
foreach (@{$opt{authors} || []}) {
    $epub->add_author(parse_name_pair($_))
}
$epub->add_language($opt{language});

# Parse a string containing a pair of names, such as "Lewis Carroll [Carroll,
# Lewis]", where the second part is optional, and return a list of two strings,
# such as ("Lewis Carroll", "Carroll, Lewis") or ("Lewis Carroll", undef).
# Ignore any extra whitespace before the opening bracket and after the closing
# bracket, but at least one space is required before the opening bracket.
# Behavior is undefined if either name contains any square bracekets.
# In scalar context, only the first name in the pair is returned.
sub parse_name_pair {
    my ($str) = @_;
    my @names = ($str =~ /^(.*?)(?:\s+\[(.*)\]\s*)?$/);
    return wantarray ? @names : $names[0];
}

# strip a number of leading path components from a path
sub destfile {
    my ($file) = @_;
    my $stripn = $opt{strip_components};
    for (1..$stripn) {
        $file =~ s|^/?[^/]+/||;
    }
    $file =~ s|^/||; # always strip leading '/' (EPUB paths must be relative)
    return $file;
}

use File::Basename;
my $play_order = 1;
# must pass args in correct order
while (my $file = shift @ARGV) {
    chomp $file;

    my $destfile = destfile($file);
    my ($base, $ext) = $file =~ /^(.*)\.([^.]+)$/;

    if ($ext eq 'css') {
        my $chapter_id = $epub->copy_stylesheet($file, $destfile);
        print "css file\n" if $opt{debug};
    } elsif ($ext eq 'jpg' or $ext eq 'jpeg') {
        my $chapter_id = $epub->copy_image($file, $destfile, 'image/jpeg');
        print "jpg file\n" if $opt{debug};
    } elsif ($ext eq 'png') {
        my $chapter_id = $epub->copy_image($file, $destfile, 'image/png');
        print "png file\n" if $opt{debug};
    } elsif ($ext =~ /gif/i) {
        my $chapter_id = $epub->copy_image($file, $destfile, 'image/gif');
        print "gif file\n" if $opt{debug};
    } elsif ($ext eq 'js') {
        my $chapter_id = $epub->copy_file($file, $destfile, 'application/javascript');
        print "js file\n" if $opt{debug};
    } else {
        my $label = basename($file, '.html', '.xhtml', '.htm');
        $label =~ s/- 0*(\d+)$/$1/;
        my $chapter_id = $epub->copy_xhtml($file, $destfile);
        print "epub file $file => $label | $destfile | $chapter_id | $play_order\n" if $opt{debug};

        my $navpoint = $epub->add_navpoint(
            label       => $label,
            id          => $chapter_id,
            content     => $destfile,
            play_order  => $play_order++,
            );
        print "  $navpoint\n" if $opt{debug};
    }
}

$epub->pack_zip("$opt{outfile}");

if ($opt{debug}) {
    use Data::Dumper::Concise;
    print Dumper $epub;
}
