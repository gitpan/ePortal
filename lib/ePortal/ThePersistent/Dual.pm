#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.1 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/Dual.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# The main ThePersistent class without ACL checking. All system tables
# without ACL should grow from this class
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::Dual - Single row ThePersistent object.

=head1 SYNOPSIS

See C<ePortal::ThePersistent::Support> and its base classes for more
information. The Dual provides "single record" virtual storage.

It can be used to create pseudo persistent objects with use all power of
C<Support.pm>

=head1 METHODS

=cut

package ePortal::ThePersistent::Dual;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Support/;

	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang

################################################################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
	$self->SUPER::initialize(@_);
    if (! $self->attribute('id')) {
        $self->add_attribute( id => { type => 'ID', dtype => 'Number', default => 1 });
    }

	$self->_id(1);
}##initialize

############################################################################
sub restore	{	#11/22/01 11:49
############################################################################
	1;
}##restore


############################################################################
sub restore_where	{	#11/22/01 11:52
############################################################################
	my $self = shift;

	return $self->{dual_restored} = 1;
}##restore_where

############################################################################
sub restore_next	{	#11/22/01 11:50
############################################################################
	my $self = shift;
	my $result = $self->{dual_restored};
	$self->{dual_restored} = undef;
	return $result;
}##restore_next


############################################################################
sub delete	{	#11/22/01 11:53
############################################################################
	1;
}##delete


############################################################################
sub update	{	#11/22/01 11:53
############################################################################
	1;
}##update


############################################################################
sub insert	{	#11/22/01 11:53
############################################################################
	1;
}##insert


1;

__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
