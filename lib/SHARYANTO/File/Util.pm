package SHARYANTO::File::Util;

use 5.010001;
use strict;
use warnings;

use Cwd ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(file_exists l_abs_path dir_empty);

our $VERSION = '0.57'; # VERSION

our %SPEC;

sub file_exists {
    my $path = shift;

    !(-l $path) && (-e _) || (-l _);
}

sub l_abs_path {
    my $path = shift;
    return Cwd::abs_path($path) unless (-l $path);

    $path =~ s!/\z!!;
    my ($parent, $leaf);
    if ($path =~ m!(.+)/(.+)!s) {
        $parent = Cwd::abs_path($1);
        return undef unless defined($path);
        $leaf   = $2;
    } else {
        $parent = Cwd::getcwd();
        $leaf   = $path;
    }
    "$parent/$leaf";
}

sub dir_empty {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my @d = grep {$_ ne '.' && $_ ne '..'} readdir($dh);
    my $res = !@d;
    #$log->tracef("dir_is_empty(%s)? %d", $dir, $res);
    $res;
}

1;
# ABSTRACT: File-related utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::File::Util - File-related utilities

=head1 VERSION

This document describes version 0.57 of SHARYANTO::File::Util (from Perl distribution SHARYANTO-File-Util), released on 2014-05-17.

=head1 SYNOPSIS

 use SHARYANTO::File::Util qw(file_exists l_abs_path dir_empty);

 print "file exists" if file_exists("/path/to/file/or/dir");
 print "absolute path = ", l_abs_path("foo");
 print "dir exists and is empty" if dir_empty("/path/to/dir");

=head1 DESCRIPTION

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 file_exists($path) => BOOL

This routine is just like the B<-e> test, except that it assume symlinks with
non-existent target as existing. If C<sym> is a symlink to a non-existing
target:

 -e "sym"             # false, Perl performs stat() which follows symlink

but:

 -l "sym"             # true, Perl performs lstat()
 -e _                 # false

This function performs the following test:

 !(-l "sym") && (-e _) || (-l _)

=head2 l_abs_path($path) => STR

Just like Cwd::abs_path(), except that it will not follow symlink if $path is
symlink (but it will follow symlinks for the parent paths).

Example:

 use Cwd qw(getcwd abs_path);

 say getcwd();              # /home/steven
 # s is a symlink to /tmp/foo
 say abs_path("s");         # /tmp/foo
 say l_abs_path("s");       # /home/steven/s
 # s2 is a symlink to /tmp
 say abs_path("s2/foo");    # /tmp/foo
 say l_abs_path("s2/foo");  # /tmp/foo

Mnemonic: l_abs_path -> abs_path is analogous to lstat -> stat.

Note: currently uses hardcoded C</> as path separator.

=head2 dir_empty($dir) => BOOL

Will return true if C<$dir> exists and is empty.

=head1 FAQ

=head2 Where is file_empty()?

For checking if some path exists, is a regular file, and is empty (content is
zero-length), you can simply use the C<-z> filetest operator.

=head1 SEE ALSO

L<SHARYANTO>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-File-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-SHARYANTO-File-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-File-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
