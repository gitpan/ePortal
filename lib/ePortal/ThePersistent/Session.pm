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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/Session.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# The main ThePersistent class without ACL checking. All system tables
# without ACL should grow from this class
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::Session - ThePersistent object stored in %session
hash.

=head1 SYNOPSIS

See C<ePortal::ThePersistent::Support> and its base classes for more
information. This class stores objects in users session hash.

It can be used to create pseudo persistent objects with use all power of
C<Support.pm>

=head1 METHODS

=cut

package ePortal::ThePersistent::Session;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Support/;

	use Carp qw/croak/;
	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang

################################################################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
	$self->SUPER::initialize(@_);
    $self->add_attribute (
        id => { type => 'ID',
                dtype => 'VarChar',
                maxlength => 255 },
                );
}##initialize

############################################################################
sub restore	{	#11/22/01 11:49
############################################################################
	my $self = shift;
	my $id = shift;

	$self->{wanted_id} = $id;
	if (exists $session{"st_s_$id"} and ref($session{"st_s_$id"}) eq 'HASH') {
		$self->data( $session{"st_s_$id"} );
		return 1;
	} else {
		return undef;
	}
}##restore


############################################################################
sub restore_where	{	#11/22/01 11:52
############################################################################
	my $self = shift;

    croak "restore_where is not supported by ".__PACKAGE__;
}##restore_where

############################################################################
sub restore_next	{	#11/22/01 11:50
############################################################################
	my $self = shift;
	$self->clear;
	undef;
}##restore_next


############################################################################
sub delete	{	#11/22/01 11:53
############################################################################
	1;
}##delete


############################################################################
sub update	{	#11/22/01 11:53
############################################################################
	my $self = shift;
    return undef if ! $self->check_id();

	my $id = ($self->_id)[0];
	$session{"st_s_$id"} = $self->data();
	1;
}##update


############################################################################
sub insert	{	#11/22/01 11:53
############################################################################
	my $self = shift;
    $self->_id($self->{wanted_id} || 1);
	$self->update;
}##insert


1;

__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
