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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/DataType/YesNo.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::YesNo;
	require 5.6.0;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;

	use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self = {};  ### allocate a hash for the object's data ###
  bless $self, $class;
  $self->initialize(@_);  ### call hook for subclass initialization ###

  return $self;
}

########################################################################
# initialize
########################################################################

=head2 Constructor -- Creates the YesNo Object

  eval {
    my $number = new ePortal::ThePersistent::DataType::YesNo([0|1] as default, $value as current);
  };
  croak "Exception caught: $@" if $@;

=cut

sub initialize {
	my($self, $defaultvalue) = @_;

	# Default value
	if ($defaultvalue eq 'yes' or $defaultvalue) {
		$self->value(1);
	} elsif ($defaultvalue eq 'no') {
		$self->value(0);
	} else {
		$self->value(0);
	}

	return;
}

########################################################################
# value
########################################################################

=head2 value -- Accesses the Value of the Number

  eval {
    ### set the value ###
    $number->value($value);

    ### get the value ###
    $value = $number->value();
  };
  croak "Exception caught: $@" if $@;


=cut

sub value {
	my $self = shift;

	### set the value ###
	if (@_) {
		my $value = shift;
		if ($value eq 'yes') {
			$self->{Value} = 1;
		} elsif ($value eq 'no') {
			$self->{Value} = 0;
		} elsif ($value) {
			$self->{Value} = 1;
		} else {
			$self->{Value} = 0;
		}
	}

	return $self->{Value};
}

########################################################################
# get_compare_op
########################################################################

sub get_compare_op {
  '<=>';  ### number comparison operator ###
}


############################################################################
# Function: sql_value
# Description:
# Parameters:
# Returns:
#
############################################################################
sub sql_value   {   #09/30/02 3:51
############################################################################
    my $self = shift;
    $self->value();
}##sql_value

### end of library ###
1;
