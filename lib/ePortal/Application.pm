#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.5 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Application.pm,v 3.5 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::Application - The base class for ePortal applications.

=head1 SYNOPSIS

An application is registered with ePortal via parameter

 application ePortal::App:ApplicationName

To create an application derive it from ePortal::Application and register
in ePortal.conf.


=head1 INITIALIZATION

During Apache's startup phase an application object will be created and
initialized.

  new()
  initialize_config() (overwrite it)
    read [common:ApplicationName] (by ePortal::Application)
    read [vhost:ApplicationName] (by ePortal::Application)
  initialize() (overwrite it)
    create DBISource if needed (by ePortal::Application)
    create sysacl if needed
    create user groups if needed
  ?????
  register PageView sections
  register cron events
  register database upgrade script


=head1 DATABASE ACCESS

ePortal::Application registers in initialize_config() three parameters for
you: dbi_source, dbi_user, dbi_password. During initialize() a DBISource
object will be create with a name of ApplicationName().

Use this new DBISource as the follows:

 my $obj = new ePortal::ThePersistent::Support("SQL", undef, "ApplicationName");
 my $obj = new ePortal::ThePersistent::Support($attributes, "table_name", "ApplicationName");
 # here ApplicationName is a name of DBISource object.


=head1 SECURITY


=head1 METHODS

=cut

package ePortal::Application;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.5 $ =~ /: (\d+).(\d+)/;

	use ePortal::Global;
	use ePortal::Utils;

    use ePortal::MethodMaker( read_only => [qw/ dbi_source dbi_username dbi_password /]);


=head2 ApplicationName

You should overwrite this method to supply your own application name. By
default a last part of application's package name is used.

=cut

############################################################################
sub ApplicationName	{	#04/18/02 2:33
############################################################################
	my $self = shift;
	my $appname = ref($self);
	$appname =~ s/.*:://;
	return $appname;
}##ApplicationName


=head2 new($config)

Application constructor. Should be never overwrited. Use Initialize_xxx
methods if you need an extra initialization.

=cut

############################################################################
sub new	{	#12/26/00 3:34
############################################################################
	my $proto = shift;
	my $class = ref($proto) || $proto;

    my $self = {};
	bless $self, $class;

    $self->config_load;
	$self->initialize;

	return $self;
}##new


############################################################################
sub config_load {   #03/17/03 4:55
############################################################################
    my $self = shift;
    my @parameters = @_;

    foreach (qw/ dbi_source dbi_username dbi_password /, @parameters) {
        $self->{$_} = $ePortal->_Config('!' . $self->ApplicationName . '!', $_);
    }
}##config_load



############################################################################
sub config_save {   #03/17/03 4:55
############################################################################
    my $self = shift;
    my @parameters = @_;

    foreach (qw/ dbi_source dbi_username dbi_password /, @parameters) {
        $ePortal->_Config('!' . $self->ApplicationName . '!', $_, $self->{$_});
    }

}##config_save




=head2 initialize()

This is application initializer. By default initialize() creates new
DBISource if any of dbi_xxx parameters are meet in config file.

=cut

############################################################################
# Function: initialize
# Description: Application initializator. Called once during server startup
# and after config is read.
#
############################################################################
sub initialize	{	#04/18/02 2:19
############################################################################
	my $self = shift;

}##initialize


############################################################################
sub dbh	{	#05/06/02 2:46
############################################################################
	my $self = shift;
    return $ePortal->DBConnect($self->ApplicationName);
}##dbh


=head2 onDeleteUser,onDeleteGroup

This is callback function. Do not call it directly. It is called from
ePortal::Server. Overload it in your application package to remove user or
group specific data.

Parameters:

=over 4

=item * username or groupname

User or Group name to delete.

=back

=cut

############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;

}##onDeleteUser


############################################################################
sub onDeleteGroup    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $groupname = shift;

}##onDeleteGroup


############################################################################
sub xacl_check  {   #02/20/03 8:29
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    my $dummy = new ePortal::ThePersistent::ExtendedACL(
        XACL_Attributes => { $xacl_field => "Dummy xacl attribute" }
        );
    $dummy->value($xacl_field, $self->{$xacl_field});
    return $dummy->xacl_check($xacl_field);
}##xacl_check


# ------------------------------------------------------------------------
# This is standard set of XACL methods
# Other Applications may have another methods
# 
sub xacl_check_read { 1; }
sub xacl_check_update   { shift->xacl_check('xacl_write'); }
sub xacl_check_children { shift->xacl_check_update; }
sub xacl_check_insert {0; }     # impossible for Application
sub xacl_check_delete {0; }     # impossible for Application

1;
