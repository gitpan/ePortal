#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::Application - The base class for ePortal applications.

=head1 SYNOPSIS

To create an application derive it from ePortal::Application and place base
module in lib/ePortal/App/YourModule.pm

This manual is incomplete !!!

=head1 METHODS

=cut

package ePortal::Application;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ACL/;

	use ePortal::Global;
	use ePortal::Utils;


############################################################################
sub new {   #09/08/2003 1:53
############################################################################
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->config_load;
    return $self;
}##new

=head2 initialize()

This is application initializer. By default initialize() creates new
DBISource if any of dbi_xxx parameters are meet in config file.

=cut

################################################################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my $self = shift;
    my %p = @_;

    # Add attributes to config object
    $p{Attributes}{uid} ||= {};
    $p{Attributes}{id} = { 
            type => 'ID', 
            default => '!' . $self->ApplicationName . '!',
            dtype => 'VarChar'};
    $p{Attributes}{dbi_source_type} = {
          type => 'Transient',
          fieldtype => 'radio_group',
          default => 'ePortal',
          values => ['ePortal', 'custom'],
          label => pick_lang(rus => "Подключение к базе данных", eng => "Database connect"),
          labels => { 
            ePortal => pick_lang(rus => "Стандартное", eng => "Standard"),
            custom  => pick_lang(rus => "Специальное", eng => "Custom"),
          }};

    $p{Attributes}{dbi_source} = {
            size => 50,
#            label => pick_lang(rus => "Источник данных DBI", eng => "DBI connect string"),
            default => 'ePortal',
      };
    $p{Attributes}{dbi_username} = {
            size => 20,
#            label => pick_lang(rus => "Имя пользователя DBI", eng => "DBI user name")
      };
    $p{Attributes}{dbi_password} = {
            size => 20,
#            label => pick_lang(rus => "Пароль пользователя DBI", eng => "DBI password")
      };
    $p{Attributes}{storage_version} = {
            dtype => 'Number',
    };

    $self->SUPER::initialize(%p);

    # Base method new() calls clear after initialize()
#    $self->config_load;
}##initialize


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



############################################################################
sub config_load {   #03/17/03 4:55
############################################################################
    my $self = shift;
    my @parameters = @_;

    $self->_id('!' . $self->ApplicationName . '!');

    # Try load config hash
    my $c = $ePortal->_Config('!' . $self->ApplicationName . '!', 'config');
    if ( ref($c) eq 'HASH' ) {
        foreach ($self->attributes_a) {
            $self->value($_, $c->{$_}) if exists $c->{$_};
        }

    } else {    # Old style 'row per parameter' config
        foreach (qw/ dbi_source dbi_username dbi_password /) {
            $self->value($_, $ePortal->_Config('!' . $self->ApplicationName . '!', $_));
        }
    }
    
    $self->dbi_source_type( $self->dbi_source eq 'ePortal' ? 'ePortal' : 'custom' );
}##config_load



############################################################################
sub config_save {   #03/17/03 4:55
############################################################################
    my $self = shift;
    my @parameters = @_;

    my $c = {};

    # Save configuration parameters
    foreach ($self->attributes_a ) {
        $c->{$_} = $self->value($_);
    }
    $ePortal->_Config('!' . $self->ApplicationName . '!', 'config', $c);


    # Special handling for dbi_xxx parameters
    # These parameters shuld be accessible alone for DBConnect to work
    foreach (qw/ dbi_source dbi_username dbi_password /) {
        $ePortal->_Config('!' . $self->ApplicationName . '!', $_, $self->value($_) );
    }

}##config_save


############################################################################
sub Config  {   #07/29/2003 11:21
############################################################################
    my $self = shift;
    $ePortal->_Config('!' . $self->ApplicationName . '!', @_);
}##Config





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
# Load attributes from ApplicationObject->{attribute}
sub restore {   #11/22/01 11:49
############################################################################
    my $self = shift;
    $self->config_load;
    1;
}##restore


############################################################################
sub restore_where   {   #11/22/01 11:52
############################################################################
    my $self = shift;

    throw ePortal::Exception::Fatal(-text => "restore_where is not supported by ".__PACKAGE__);
}##restore_where

############################################################################
sub restore_next    {   #11/22/01 11:50
############################################################################
    my $self = shift;
    undef;
}##restore_next

############################################################################
sub update  {   #11/22/01 11:53
############################################################################
    my $self = shift;
    
    $self->dbi_source('ePortal') if $self->dbi_source_type eq 'ePortal';

    # clear storage_version for external storages
    if ($self->dbi_source ne 'ePortal') {
        $self->storage_version(0);
    }

    if ($self->dbi_source ne 'ePortal') {
        my $d = eval {
            DBI->connect( $self->dbi_source, $self->dbi_username, $self->dbi_password);
        };
        if (! $d or $@) {
            throw ePortal::Exception::DataNotValid(-text => 
                pick_lang(rus => "Не могу подключиться к БД", eng => "Cannot connect to database") . "<br><small>$@</small>");
        }
    }

    $self->config_save;
    1;
}##update


############################################################################
sub insert  {   #11/22/01 11:53
############################################################################
    my $self = shift;
    $self->update;
}##insert



# ------------------------------------------------------------------------
# This is standard set of XACL methods
# Other Applications may have another methods
#
#sub xacl_check_read { 1; }
#sub xacl_check_children { shift->xacl_check_update; }
sub xacl_check_insert { 0; }     # impossible for Application
sub xacl_check_delete { 0; }     # impossible for Application
sub xacl_check_admin  { $ePortal->isAdmin; }
sub xacl_check_update   { 
    my $self = shift;
    if ($self->attribute('xacl_write')) {
        return $self->xacl_check('xacl_write');
    } else {
        return $ePortal->isAdmin;
    }
}



1;

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
