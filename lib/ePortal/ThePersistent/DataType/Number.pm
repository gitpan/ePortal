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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/DataType/Number.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::Number;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

use Carp;

### copy version number from superclass ###
$VERSION = $ePortal::ThePersistent::DataType::Base::VERSION;
$REVISION = (qw$Revision: 3.1 $)[1];


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

=head2 Constructor -- Creates the Number Object

  eval {
    my $number = new ePortal::ThePersistent::DataType::Number($value, $precision, $scale);
  };
  croak "Exception caught: $@" if $@;



=cut

sub initialize {
	my($self, $precision, $scale, $value) = @_;
    # ÏÎÌÅÍßÒÜ ÌÅÑÒÀÌÈ^^^^^^^^
    #
    # scale - is maxlength in characters
    # precision is a number of digits after .

	if ($precision+$scale == 0) {
		$precision = length($value);
	}

	### set the attributes ###
	$self->precision($precision);
	$self->scale($scale);
	$self->value($value) if ($value);
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

  my $precision = $self->precision();
  my $scale = $self->scale();

  ### set the value ###
  if (@_) {
    my $value = shift;
    #$value = $value + 0;  ### force numeric context ###
	# This not work with ID. ID is corrent when field defined but ID cannot be 0

	if (length($value) > $precision) {
		confess "Length of value [$value] is greater then precision [$precision]";
	}

    $self->{Value} = $value;

  }
	return unless defined wantarray;

  ### return the value ###
	if ($scale == 0) {
        return $self->{Value};
	} else {
        return sprintf '%.'.$scale.'f', $self->{Value};
	}
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
sub sql_value   {   #09/30/02 2:34
############################################################################
    my $self = shift;
    return $self->value();
}##sql_value


########################################################################
#
# --------------
# PUBLIC METHODS
# --------------
#
########################################################################

########################################################################
# precision  Accesses the Precision of the Number
########################################################################

sub precision {
  my $self = shift;

  ### set the precision ###
  if (@_) {
    my $precision = shift;
    $precision = 0 if $precision == 0;
    $self->{Data}->{Precision} = $precision;
  }

  ### return the precision ###
  $self->{Data}->{Precision};
}

########################################################################
# scale   Accesses the Scale of the Number
########################################################################

sub scale {
  my $self = shift;

  ### set the scale ###
  if (@_) {
    my $scale = shift;
    $scale = 0 if $scale <= 0;
    $self->{Data}->{Scale} = $scale;
  }

  ### return the scale ###
  $self->{Data}->{Scale};
}

########################################################################
# Function:    _parse_number
# Description: Parses the number into digits before and after the
#              decimal point.  Insignificant trailing zeroes will be
#              truncated.
# Parameters:  None
# Returns:     None
########################################################################
sub _parse_number {
  my $value = shift;

  my $before = '';
  my $after = '';

  if (defined $value) {
    if ($value =~ /^[+-]?(\d*)\.?(\d*)$/o) {
      $before = $1;  $after = $2;
      $after =~ s/0+$//;  ### remove trailing zeroes ###
    } else {
      croak "'$value' is not a number";
    }
  }

  ($before, $after);
}

### end of library ###
1;
