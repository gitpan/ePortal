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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/DataType/Date.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::Date;

use strict;
use Carp;

### copy version number from superclass ###
our $VERSION = $ePortal::ThePersistent::DataType::Base::VERSION;
our $REVISION = (qw$Revision: 3.1 $)[1];

  ### month name to number map ###
  my %month_to_num = (
		      'jan' => '01',
		      'feb' => '02',
		      'mar' => '03',
		      'apr' => '04',
		      'may' => '05',
		      'jun' => '06',
		      'jul' => '07',
		      'aug' => '08',
		      'sep' => '09',
		      'oct' => '10',
		      'nov' => '11',
		      'dec' => '12',
		     );

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self = {};  ### allocate a hash for the object's data ###
  bless $self, $class;
  $self->initialize(@_);  ### call hook for subclass initialization ###

  return $self;
}

############################################################################
# Function: initialize
# Description: Constructor -- Create a New Date Object
#  eval {
#    $date = new ePortal::ThePersistent::DataType::Date($datestring);
#    $date = new ePortal::ThePersistent::DataType::Date('now');
#    $date = new ePortal::ThePersistent::DataType::Date('');
#    $date = new ePortal::ThePersistent::DataType::Date(undef);
#    $date = new ePortal::ThePersistent::DataType::Date($year, $month, $day);
#    $date = new ePortal::ThePersistent::DataType::Date(localtime);
# Parameters:
# Returns:
#
############################################################################
sub initialize	{	#09/08/00 10:23
############################################################################
  my $self = shift;

  $self->value(@_);
}

########################################################################
# value
########################################################################

=head2 value -- Accesses the Value of the Date

  eval {
    $date_string = $date->value($datestring);
    $date_string = $date->value('now');
    $date_string = $date->value('');
    $date_string = $date->value(undef);
    $date_string = $date->value($year, $month, $day,
				$hour, $min, $sec);
    $date_string = $date->value(localtime);
  };

=cut

sub value {
  my $self = shift;

  ### common patterns of parts of the date string ###
  my $num4 = '\d{4,4}';
  my $num2 = '\d{1,2}';
  $self->{ready} = undef;

  ### set it ###
  if (@_ == 1) {  ### one argument passed ###
    my $arg = shift;
    if (!defined($arg) || $arg eq '') {
      $self->year(undef);   $self->month(undef);    $self->day(undef);

    } elsif ($arg eq 'now') {
        my @dt = CORE::localtime;
        $dt[4] += 1;
        $dt[5] += 1900;
        $self->year($dt[5]);   $self->month($dt[4]);    $self->day($dt[3]);

    } elsif ($arg =~ /^(\d\d\d\d)(\d\d)(\d\d)/o) {
      $self->year($1);   $self->month($2);    $self->day($3);

    } elsif ($arg =~ /^($num4)[-\/\.]($num2)[-\/\.]($num2)\s*/ox) {
      $self->year($1);   $self->month($2);    $self->day($3);

    } elsif ($arg =~ /^($num2)[-\.\/]($num2)[-\.\/]($num4)\s*/xo) {
      $self->year($3);   $self->month($2);    $self->day($1);
	  $self->{ready} = $arg;

    } elsif ($arg =~ /^($num2)-(\w{3})-($num4)\s*/o) {
      $self->year($3);  $self->month($month_to_num{lc $2});  $self->day($1);

    } elsif ($arg =~ /^$num4$/) {
      $self->year($arg);    $self->month(shift);    $self->day(shift);

    } else {
      croak "date ($arg) does not match any of the valid formats";
    }

  } elsif (@_ > 1 && @_ < 4) {  ### 2..6 arguments passed ###
    $self->year(shift);   $self->month(shift);    $self->day(shift);

  } elsif (@_) {
    croak sprintf("Unknown number of arguments (%s) passed", scalar @_);
  }

	return unless defined wantarray;

  	### return it ###
	return $self->{ready} if defined $self->{ready};

  	my $year = $self->year();
  	my $month = $self->month();
  	my $day = $self->day();
  	if (!defined($year) && !defined($month) && !defined($day) ) {
    	undef;
  	} else {
        sprintf("%02d.%02d.%04d", $day, $month, $year);
  	}
}

########################################################################
# get_compare_op
########################################################################

sub get_compare_op {
  'cmp';  ### string comparison operator ###
}

########################################################################
# year
########################################################################

sub year {
  my $self = shift;

  ### set it ###
  if (@_) {
    my $year = shift;
    $year = undef if $year == 0;

    if (defined $year) {
      croak "year ($year) must be between 0 and 9999" if $year < 0 || $year > 9999;
    }
    $self->{Year} = $year;
  }

  ### return it ###
  $self->{Year};
}

########################################################################
# month
########################################################################


sub month {
  my $self = shift;

  ### set it ###
  if (@_) {
    my $month = shift;
    $month = undef if $month == 0;
    if (defined $month) {
      croak "month ($month) must be between 1 and 12" if $month < 1 || $month > 12;
    }
    $self->{Month} = $month;
  }

  ### return it ###
  $self->{Month};
}

########################################################################
# day
########################################################################

sub day {
  my $self = shift;

  ### set it ###
  if (@_) {
    my $day = shift;
    $day = undef if $day == 0;
    if (defined $day) {
      croak "day ($day) must be between 1 and 31" if $day < 1 || $day > 31;
    }
    $self->{Day} = $day;
  }

  ### return it ###
  $self->{Day};
}

############################################################################
sub sql_value   {   #09/30/02 3:39
############################################################################
    my $self = shift;

    my $year = $self->year();
    my $month = $self->month();
    my $day = $self->day();
    if (!defined($year) && !defined($month) && !defined($day)){
      undef;
    } else {
      sprintf("%04d.%02d.%02d", $year, $month, $day);
    }
}##sql_value


############################################################################
sub array   {   #10/02/02 8:48
############################################################################
    my $self = shift;

    my $year = $self->year();
    my $month = $self->month();
    my $day = $self->day();
    if (!defined($year) && !defined($month) && !defined($day)){
      undef;
    } else {
      ($year, $month, $day);
    }
}##array

### end of library ###

1;

