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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/DataType/Array.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::Array;

our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;
use Carp;


sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self = {
    Value => [],
    };
  bless $self, $class;
  $self->initialize(@_);  ### call hook for subclass initialization ###

  return $self;
}

########################################################################
# initialize
########################################################################

=head2 Constructor -- Creates the Array Object

  eval {
    my $string = new ePortal::ThePersistent::DataType::Array($arrayref);
  };
=cut

sub initialize {
    my($self, $value) = @_;

	$self->value($value) if ($value);
	return;
}

sub value {
  my $self = shift;

  ### set the value ###
  if (@_) {
    my $value = shift;
    $value = [] if ref($value) ne 'ARRAY';
    $self->{Value} = $value;
  }

  ### return the value ###
  $self->{Value};
}



sub length {
  my $self = shift;

  ### return the length ###
  scalar( @{$self->value} );
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
