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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/Database.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::Database;

use strict;
use Carp;

use base qw/ePortal::ThePersistent::Base/;
our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;

########################################################################
sub _get_sql_for_string_to_datetime {
	my($self, $dt_str) = @_;

  my $dr = $self->_check_driver;

  if ($dr eq 'oracle') {							# Oracle
	if ($dt_str eq '?') {
		return "TO_DATE(?, 'DD.MM.YYYY HH24:MI:SS')";
	} else {
		return "TO_DATE('$dt_str', 'DD.MM.YYYY HH24:MI:SS')";
	}
  } elsif ($dr eq 'mysql') {						# MySQL
	return $dt_str eq '?' ?
		'?':
		"'" . sprintf("%04d.%02d.%02d %02d:%02d:%02d", (split('[\. :-]', $dt_str))[2,1,0,3,4,5]) . "'";
  }
}


sub _get_sql_for_string_to_date {
	my($self, $dt_str) = @_;

	my $dr = $self->_check_driver;
	if ($dr eq 'oracle') {							# Oracle
		if ($dt_str eq '?') {
			return "TO_DATE(?, 'DD.MM.YYYY')";
		} else {
			return "TO_DATE('$dt_str', 'DD.MM.YYYY')";
		}
	} elsif ($dr eq 'mysql') {						# MySQL
		return $dt_str eq '?' ?
			'?':
			"'" . join('.', reverse(split('\.', $dt_str))) . "'";
	}
}

########################################################################
# Function:    _get_sql_for_datetime_to_string
# Description: Returns the SQL to convert a date into a string.
#              The returned SQL is Database specific.
# Parameters:  $dt_col = name of a Date column to be converted into a
#              string.
# Returns:     $sql = SQL to convert the date column into a string
########################################################################
sub _get_sql_for_datetime_to_string {
 	my($self, $dt_col) = @_;

  	my $dr = $self->_check_driver;
	if ($dr eq 'oracle') {	# Oracle
		return "TO_CHAR($dt_col, 'DD.MM.YYYY HH24:MI:SS')";
	} elsif ($dr eq 'mysql') {		# MySQL
		return "DATE_FORMAT($dt_col, '%d.%m.%Y %H:%i:%S')";
	}
}
sub _get_sql_for_date_to_string {
  my($self, $dt_col) = @_;

  	my $dr = $self->_check_driver;
	if ($dr eq 'oracle') {	# Oracle
  		return "TO_CHAR($dt_col, 'DD.MM.YYYY')";
	} elsif ($dr eq 'mysql') {		# MySQL
		return "DATE_FORMAT($dt_col, '%d.%m.%Y')";
	}
}

############################################################################
# Function: _get_time
# Description: Get time part from datetime string
# Parameters:
# Returns:
#
############################################################################
sub _get_time	{	#01/24/02 1:30
############################################################################
	my $self = shift;
	my $datetime = shift;
	return (split('\s', $datetime))[1];
}##_get_time


############################################################################
# Function: _get_date
# Description: get date part from datetime
# Parameters:
# Returns:
#
############################################################################
sub _get_date	{	#01/24/02 1:31
############################################################################
	my $self = shift;
	my $datetime = shift;
	return (split('\s', $datetime))[0];
}##_get_date


############################################################################
# Function: _get_time_HHMM
# Description:
# Parameters:
# Returns:
#
############################################################################
sub _get_time_HHMM	{	#01/24/02 1:32
############################################################################
	my $self = shift;
	my $datetime = shift;
	my $time = $self->_get_time($datetime);
	return join(':', (split(':', $time))[0,1]);
}##_get_time_HHMM


########################################################################
# Function:    _get_column_name
# Description: Returns the name of the column for the attribute of the object.
# Parameters:  $attribute = name of the attribute of the object
# Returns:     $column = name of the column in the table that stores
#                        the attribute of the object
########################################################################

sub _get_column_name {
	my($self, $attribute) = @_;

	### Database returns all column names in UPPER case ###
	my $dr = $self->_check_driver;
	return uc($attribute) if $dr eq 'oracle';
	return lc($attribute) if $dr eq 'mysql';
}


############################################################################
# Function: _field_def
# Description: Generates SQL field definition. Used in table creation
# process. Takes into account database driver type.
# Parameters: Field object.
# Returns: SQL string with field description.
#
############################################################################
sub _field_def	{	#03/08/01 10:30
############################################################################
	my $self = shift;
	my $field = shift;
	my $notnull;

	my $dr = $self->_check_driver;
	my $sql = "$field ";
    if ((ref $self->{Data}->{$field}->[0]) =~ /DateTime$/) {
		$sql .= "date" if $dr eq 'oracle'; # ORA
		$sql .= "datetime" if $dr eq 'mysql'; # MySQL
    } elsif ((ref $self->{Data}->{$field}->[0]) =~ /Date$/) {
		$sql .= "date" if $dr eq 'oracle'; # ORA
		$sql .= "date" if $dr eq 'mysql'; # MySQL
    } elsif ((ref $self->{Data}->{$field}->[0]) =~ /VarChar$/) {
		if ($dr eq 'mysql' and $self->{Data}->{$field}->[0]->max_length > 255) {
					# MySQL does not has long varchar
			$sql .= "text";
		} else {
			$sql .= "varchar(" . $self->{Data}->{$field}->[0]->max_length . ')';
		}

    } elsif ((ref $self->{Data}->{$field}->[0]) =~ /Number$/) {
		$sql .= "number(" if $dr eq 'oracle';
		$sql .= "decimal(" if $dr eq 'mysql'; # MySQL
		$sql .= $self->{Data}->{$field}->[0]->precision . ',' .
				$self->{Data}->{$field}->[0]->scale . ')';

    } elsif ((ref $self->{Data}->{$field}->[0]) =~ /YesNo$/) {
		# I use 2 as scale because -1 uses 2 digits!
		$sql .= "number(2) default 0" if $dr eq 'oracle';
		$sql .= "decimal(2) default 0" if $dr eq 'mysql';
		$notnull = 1;

	} else {
		die "Unsupported datatype [$field]: " . ref $self->{Data}->{$field}->[0];
	}

	my $identity;
	foreach my $f (@{$self->{IdFields}}) {
		$identity = 1 if $field eq $f;
	}
	if ($identity or $notnull) {
		$sql .= " not null";
	} else {
		$sql .= " null";
	}

	return $sql;
}##_field_def


############################################################################
# Function: CreateTable
# Description: Creates table in database
# Returns: undef on error (see errstr)
#
############################################################################
sub CreateTable	{	#03/08/01 10:16
############################################################################
	my $self = shift;

	my @fields;
  	foreach my $field (@{$self->{DataOrder}}) {
		push @fields, $self->_field_def( $field );
  	}

    my $sql = "CREATE TABLE ".$self->{Table} ." (\n" .
  		join(",\n", @fields) . ",\n" .
		"PRIMARY KEY (" . join(',', (@{$self->{IdFields}})) . ")" .
		")\n";

	my $dbh = $self->_get_dbh;
	if ($dbh->do($sql)) {
		return 1;
	} else {
		# See error description in $DBI::errstr
		#logline('d', "SQL error: $DBI::errstr");
		#errstr("Не могу выполнить SQL запрос: ".$DBI::errstr);
		return undef;
	}
}##CreateTable



### end of library ###
1;

