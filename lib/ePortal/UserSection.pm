#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.4 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/UserSection.pm,v 3.4 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::UserSection - users section in home page.

=head1 SYNOPSIS

ePortal::UserSection used to store information about content of user's home
page.


=cut

package ePortal::UserSection;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.4 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Support/;

	use ePortal::Global;
	use ePortal::PageSection;
	use ePortal::Utils;

	my $attributes = {
        id => { type => 'ID',
				order => 1,
				dtype => 'Number',
                auto_increment => 1,
		},
		pv_id => { dtype => 'Number'},
		ps_id => { dtype => 'Number'},
		colnum => { dtype => 'Number'},
		minimized => {dtype => 'YesNo'},
		setupinfo => {
				dtype => 'Varchar',
                maxlength => 8000,
				order => 9,
		},
	};

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
	my $attr = shift || $attributes;

	$self->{ps} = new ePortal::PageSection;
    $self->SUPER::initialize(Attributes => $attr);
}##initialize


############################################################################
# Function: parent
############################################################################
sub parent	{	#05/17/01 3:32
############################################################################
	my $self = shift;

	my $parent = new ePortal::PageView;
    if ($parent->restore($self->pv_id)) {
        return $parent;
    } else {
        return undef;
    }
}##parent


############################################################################
sub restore_next	{	#10/12/01 2:29
############################################################################
	my $self = shift;
	my $result = $self->SUPER::restore_next(@_);

	if ($result) {
		$self->{ps}->restore($self->ps_id);
	} else {
		$self->{ps}->clear;
	}
	$result
}##restore_next




# ------------------------------------------------------------------------
# Here some attributes functions used to get values from related PageSection
# object
sub title	{	my $self = shift;	return $self->{ps}->title;	}
sub URL		{	my $self = shift;	return $self->{ps}->URL;}
sub width	{	my $self = shift;	return $self->{ps}->width;}
sub component{	my $self = shift;	return $self->{ps}->component;}
sub params	{	my $self = shift;	return $self->{ps}->params;}
sub content {	my $self = shift;	return $self->{ps}->content($self) ;}
sub setup_button {my $self = shift; return ($self->{ps}->Setupable and $self->parent()->xacl_check_update);}
sub cancel_button{my $self = shift; return $self->parent()->xacl_check_update;}



1;
