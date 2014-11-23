package SHARYANTO::File::Flock;

use 5.010;
use strict;
use warnings;

use Fcntl ':flock';

our $VERSION = '0.58'; # VERSION

sub lock {
    my ($class, $path, $opts) = @_;
    $opts //= {};
    my %h;

    defined($path) or die "Please specify path";
    $h{path}    = $path;
    $h{retries} = $opts->{retries} // 60;

    my $self = bless \%h, $class;
    $self->_lock;
    $self;
}

# return 1 if we lock, 0 if already locked. die on failure.
sub _lock {
    my $self = shift;

    # already locked
    return 0 if $self->{_fh};

    my $path = $self->{path};
    my $existed = -f $path;
    my $exists;
    my $tries = 0;
  TRY:
    while (1) {
        $tries++;

        # 1
        open $self->{_fh}, ">>", $path
            or die "Can't open lock file '$path': $!";

        # 2
        my @st1 = stat($self->{_fh}); # stat before lock

        # 3
        if (flock($self->{_fh}, LOCK_EX | LOCK_NB)) {
            # if file is unlinked by another process between 1 & 2, @st1 will be
            # empty and we check here.
            redo TRY unless @st1;

            # 4
            my @st2 = stat($path); # stat after lock

            # if file is unlinked between 3 & 4, @st2 will be empty and we check
            # here.
            redo TRY unless @st2;

            # if file is recreated between 2 & 4, @st1 and @st2 will differ in
            # dev/inode, we check here.
            redo TRY if $st1[0] != $st2[0] || $st1[1] != $st2[1];

            # everything seems okay
            last;
        } else {
            $tries <= $self->{retries}
                or die "Can't acquire lock on '$path' after $tries seconds";
            sleep 1;
        }
    }
    $self->{_created} = !$existed;
    1;
}

# return 1 if we unlock, 0 if already unlocked. die on failure.
sub _unlock {
    my ($self) = @_;

    my $path = $self->{path};

    # don't unlock if we are not holding the lock
    return 0 unless $self->{_fh};

    unlink $self->{path} if $self->{_created} && !(-s $self->{path});

    {
        # to shut up warning about flock on closed filehandle (XXX but why
        # closed if we are holding the lock?)
        no warnings;

        flock $self->{_fh}, LOCK_UN;
    }
    close delete($self->{_fh});
    1;
}

sub release {
    my $self = shift;
    $self->_unlock;
}

sub unlock {
    my $self = shift;
    $self->_unlock;
}

sub DESTROY {
    my $self = shift;
    $self->_unlock;
}

1;
#ABSTRACT: Yet another flock module

__END__

=pod

=encoding UTF-8

=head1 NAME

SHARYANTO::File::Flock - Yet another flock module

=head1 VERSION

This document describes version 0.58 of SHARYANTO::File::Flock (from Perl distribution SHARYANTO-File-Util), released on 2014-11-23.

=head1 SYNOPSIS

 use SHARYANTO::File::Flock;

 # try to acquire exclusive lock. if fail to acquire lock within 60s, die.
 my $lock = SHARYANTO::File::Flock->lock($file);

 # explicitly unlock
 $lock->release;

 # automatically unlock if object is DESTROY-ed.
 undef $lock;

=head1 DESCRIPTION

This is yet another flock module. It is a more lightweight alternative to
L<File::Flock> with some other differences:

=over 4

=item * OO interface only

=item * Autoretry (by default for 60s) when trying to acquire lock

I prefer this approach to blocking/waiting indefinitely or failing immediately.

=back

=for Pod::Coverage ^(DESTROY)$

=head1 METHODS

=head2 $lock = SHARYANTO::File::Flock->lock($path, \%opts)

Acquire an exclusive lock on C<$path>. C<$path> will be created if not already
exists. If $path is already locked by another process, will retry (by default
for 60 seconds). Will die if failed to acquire lock.

Will automatically unlock if C<$lock> goes out of scope. Upon unlock, will
remove C<$path> if it was created and is still empty (this behavior is the same
as File::Flock).

Available options:

=over

=item * retries => INT (default: 60)

Number of retries (equals number of seconds, since retry is done every second).

=back

=head2 $lock->unlock

Unlock.

=head2 $lock->release

Synonym for unlock().

=head1 CAVEATS

Not yet tested on Windows. Some filesystems do not support inode?

=head1 SEE ALSO

L<SHARYANTO>

L<File::Flock>

L<File::Flock::Tiny> which is also tiny, but does not have the autoremove and
autoretry capability which I want. See also:
https://github.com/trinitum/perl-File-Flock-Tiny/issues/1

flock() Perl function.

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

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
