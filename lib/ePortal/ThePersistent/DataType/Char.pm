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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/DataType/Char.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::Char;
require 5.004;

use strict;
use vars qw($VERSION $REVISION @ISA);

### a subclass of the all-powerful ePortal::ThePersistent::DataType::String class ###
use ePortal::ThePersistent::DataType::String;
@ISA = qw(ePortal::ThePersistent::DataType::String);

use Carp;

### copy version number from superclass ###
$VERSION = $ePortal::ThePersistent::DataType::String::VERSION;
$REVISION = (qw$Revision: 3.1 $)[1];


########################################################################
# initialize
########################################################################

=head2 Constructor -- Creates the Char Object

  eval {
    my $string = new ePortal::ThePersistent::DataType::Char($max_length, $value);
  };
  croak "Exception caught: $@" if $@;

=cut

sub initialize {
  my($self, $value, $max_length) = @_;

  if (!defined($max_length)) {
    if (!defined($value) || $value eq '') {
      $max_length = 1;
    } else {
      $max_length = length($value);
    }
  }
  $self->max_length($max_length);
  $self->value($value);
}

########################################################################
# value
########################################################################

sub value {
  my $self = shift;

  ### superclass does all the work, just pad the value with spaces ###
  my $value = $self->SUPER::value(@_);
  if (defined $value) {
    my $max_length = $self->max_length();
    sprintf("%-${max_length}s", $value);
  } else {
    $value;
  }
}

########################################################################
#
# --------------
# PUBLIC METHODS
# --------------
#
########################################################################

########################################################################
# length
########################################################################

=head2 length -- Returns the Length of the String

  eval {
    $value = $string->length();
  };
  croak "Exception caught: $@" if $@;

Returns the length of the string which is always the same as the
maximum length for a fixed length string.  This method throws Perl
execeptions so use it with an eval block.

Parameters:

=over 4

=item None

=back

=cut

sub length {
  my $self = shift;

  ### no setting allowed ###
  croak "length is read-only" if @_;

  ### return the length ###
  $self->max_length();
}

########################################################################
# max_length
########################################################################

=head2 max_length -- Accesses the Maximum Length of the String

  eval {
    ### set the maximum length ###
    $string->max_length($new_max);

    ### get the maximum length ###
    $max_length = $string->max_length();
  };
  croak "Exception caught: $@" if $@;

Sets the maximum length of the string and/or returns it.  This method
throws Perl execeptions so use it with an eval block.

Parameters:

=over 4

=item I<$max_length>

Maximum length of the string value.  The maximum length must be
greater than zero, otherwise, an exception is thrown.

=back

=cut

sub max_length {
  my $self = shift;

  ### check the arguments ###
  if (@_) {
    my($max_length) = @_;
    if (!defined($max_length) || $max_length eq '' || $max_length <= 0) {
      croak(sprintf("maximum length (%s) must be > 0",
		    defined $max_length ? $max_length : 'undef'));
    }
  }

  ### superclass does the work ###
  $self->SUPER::max_length(@_);
}

### end of library ###
1;

