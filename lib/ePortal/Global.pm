#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------

package ePortal::Global;
    our $VERSION = '4.2';

	# --------------------------------------------------------------------
	# Symbols to export
	#
    use base qw/Exporter/;
    our @EXPORT = qw/$ePortal $dbh %session %gdata /;

   	# --------------------------------------------------------------------
	# Global variables
	#
    our $ePortal;
	our $dbh;
	our %session;
	our %gdata;


1;


__END__


=head1 NAME

ePortal::Global.pm - Global variables for entire ePortal.



=head1 SYNOPSIS

This package exports some global variables. Use this package everywhere
when you need these variables.



=head2 $ePortal

Global object blessed to ePortal::Server. This is main engine.





=head2 $dbh

Global database handle

=head2 %session

This is hash of Session data storage


=head2 %gdata

This is temporary hash object. It exists only during apache request
processing.




=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
