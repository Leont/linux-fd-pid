package Linux::FD::Pid;

use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: PID file descriptors

=head1 SYNOPSIS

 use Linux::FD::Pid
 
 my $fh = Linux::FD::Pid($pid)

=method new($pid)

This creates a pidfd file descriptor that can be used to await the termination of a process. This provides an alternative to using C<SIGCHLD>, and has the advantage that the file descriptor may be monitored by select, poll, and epoll.

Note that it doesn't (and for now can't) do the actual waiting, one still needs C<waitpid> for that.

=method send($signo)

This sends a signal to the process.

=cut
