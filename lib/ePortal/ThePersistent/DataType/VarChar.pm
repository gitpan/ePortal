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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/DataType/VarChar.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::VarChar;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

use Carp;

### copy version number from superclass ###
$VERSION = $ePortal::ThePersistent::DataType::String::VERSION;
$REVISION = (qw$Revision: 3.1 $)[1];

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self = {
    Value => undef,
    MaxLength => 0,
    };
  bless $self, $class;
  $self->initialize(@_);  ### call hook for subclass initialization ###

  return $self;
}

########################################################################
# initialize
########################################################################

=head2 Constructor -- Creates the VarChar Object

  eval {
    my $string = new ePortal::ThePersistent::DataType::VarChar($value, $max_length);
  };
=cut

sub initialize {
	my($self, $max_length, $value) = @_;

    $self->max_length($max_length) if $max_length;
	$self->value($value) if ($value);
	return;
}

sub value {
  my $self = shift;

  ### set the value ###
  if (@_) {
    my $value = shift;
    $value = undef if $value eq '';
    my $max_length = $self->max_length();

    ### check the length ###
    if ($max_length and (length($value) > $max_length)) {
        $value = substr($value, 0, $max_length);
    }
    $self->{Value} = $value;
  }

  ### return the value ###
  $self->{Value};
}



########################################################################
# max_length
########################################################################

sub max_length {
  my $self = shift;

  ### check the arguments ###
  if (@_) {
    my $max_length = shift;
    if ($max_length < 0) {
      carp "maximum length must be >= 0";
    }

    ### shorten the value if too long ###
    if ($self->{MaxLength} > $max_length) {
        $self->{Value} =  substr($self->{Value}, 0, $max_length);
    }

    $self->{MaxLength} = $max_length;
  }

  $self->{MaxLength};
}

sub length {
  my $self = shift;

  ### return the length ###
  CORE::length($self->value());
}

sub get_compare_op {
  'cmp';  ### string comparison operator ###
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


### end of library ###
1;
