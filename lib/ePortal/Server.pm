#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.13 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Server.pm,v 3.13 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
#
# Description: The kernel of ePortal.
#
# ------------------------------------------------------------------------


=head1 NAME

ePortal::Server - The core module of ePortal project.

=head1 SYNOPSIS

ePortal is a set of perl packages and HTML::Mason components to easy 
implement intranet WEB site for a company. ePortal is writen with a help of 
Apache, mod_perl, HTML::Mason. The current version of ePortal use MySQL as 
database backend.

=head1 METHODS

=cut

package ePortal::Server;
	require 5.6.1;
    our $REVISION = sprintf '%d.%03d', q$Revision: 3.13 $ =~ /: (\d+).(\d+)/;
    our $VERSION = '3.2';

    use ePortal::Global;
    use ePortal::Utils;

    # Localization and cyrillization.
    use POSIX qw(locale_h);
    use locale;

    # System modules
    use strict;
    use DBI;
    use Storable qw/freeze thaw/;
    use Mail::Sendmail ();
    use File::Basename ();
    use Data::Dumper;           # Sometimes I use it (print config)
    use MD5;

    # Exception handling and parameters validating modules
    use Error qw/:try/;
    use ePortal::Exception;
    use Params::Validate qw/:types/;

    # ePortal's packages
    use ePortal::ApplicationConfig;
    use ePortal::Catalog;
    use ePortal::epGroup;
    use ePortal::epUser;
    use ePortal::Exception;
    use ePortal::PageView;
    use ePortal::PopupEvent;

    # ThePersistent packages
    use ePortal::ThePersistent::ExtendedACL;
    use ePortal::ThePersistent::UserConfig;
    use ePortal::ThePersistent::UserConfig;
    use ePortal::ThePersistent::Utils;


    # Some usefull read only internal variables
    use ePortal::MethodMaker( read_only => [qw/ user username config_file/]);

    # Main configuration parameters
    my @MAIN_CONFIG_PARAMETERS = (qw/ dbi_source dbi_username dbi_password admin_mode /);
    eval 'use ePortal::MethodMaker( read_only => [@MAIN_CONFIG_PARAMETERS] );';

    my @GENERAL_CONFIG_PARAMETERS = (qw/
            admin debug log_filename log_charset disk_charset
            vhost applications
            days_keep_sessions language refresh_interval date_field_style
            smtp_server www_server mail_domain
            ldap_server ldap_base ldap_binddn ldap_bindpw ldap_charset
            ldap_uid_attr ldap_fullname_attr ldap_title_attr
            ldap_ou_attr ldap_group_attr ldap_groupdesc_attr
            /);
    eval 'use ePortal::MethodMaker( read_only => [@GENERAL_CONFIG_PARAMETERS] );';

    # Global hash to store vhost instances of ePortal
    # This is used for multihome servers
    our (%ePortal_server);

    # True if the module loaded under Apache HTTP server
    our $RUNNING_UNDER_APACHE = $ENV{MOD_PERL} || $ENV{SERVER_SOFTWARE};

############################################################################
# Function: new
# Description: ePortal object Constructor
# Parameters:
#   vhost name, config hash
# or
#   vhost name, config filename
# Returns:
#   ePortal blessed object
#
############################################################################
sub new {   #12/26/00 3:34
############################################################################
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %p = Params::Validate::validate_with( params => \@_, spec => {
        config_file => { type => UNDEF | SCALAR, optional => 1},
        });

    my $self = {
        config_file => $p{config_file},
        };
    bless $self, $class;

    # This is global variable imported from ePortal::Global;
    $ePortal = $self;

    # Discover main parameters needed for database connection
    my %main_parameters = $self->config_main_parameters( $p{config_file} );
    foreach (keys %main_parameters) {
        $self->{$_} = $main_parameters{$_};
    }

    return $self;
}##new

############################################################################
# Function: initialize
# Description: new() is a general class initializer
#   initialize() does all initialization with accordance with configs
# Parameters:
# Returns:
#
############################################################################
sub initialize  {   #03/21/03 3:51
############################################################################
    my $self = shift;

    $self->DBConnect;
    $self->config_load;

    # Load application modules
    foreach my $app_name ($self->ApplicationsConfigured) {
        eval "use ePortal::App::$app_name;";
        if ( $@ ) {
            throw ePortal::Exception::Fatal(-text => "Cannot load application module $app_name: $@");
        } else {
            $self->{_application_object}{$app_name} = "ePortal::App::$app_name"->new();
            logline('info', "Loaded application module $app_name");
        }
    }

    # Precreate some objects
    $self->{user} = new ePortal::epUser;
}##initialize

############################################################################
sub config_load {   #03/17/03 3:38
############################################################################
    my $self = shift;
    # Load configuration parameters
    foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
        $self->{$par} = $self->Config($par);
    }
    # Initialize some of the parameters to empty values
    $self->{admin} = [] if ref($self->{admin}) ne 'ARRAY';
    $self->{applications} = {} if ref($self->{applications}) ne 'HASH';
}##config_load


############################################################################
sub config_save {   #03/17/03 3:38
############################################################################
    my $self = shift;

    # Load configuration parameters
    foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
        $self->{$par} = $self->Config($par, $self->{$par});
    }
}##config_save

############################################################################
# Function: config_main_parameters
# Description:
# Parameters:
# Returns:
#
############################################################################
sub config_main_parameters  {   #03/13/03 1:41
############################################################################
    my $self = shift;
    my $filename = shift;

    my %hash = (
        dbi_source => undef,
        dbi_username => undef,
        dbi_password => undef,
        admin_mode => undef,
        );

    if ($RUNNING_UNDER_APACHE) {
        throw ePortal::Exception::Fatal( -text => "Apache::Request object \$r is not available.")
            if ! $self->r;
        $hash{dbi_source}   ||= $self->r->dir_config('ePortal_dbi_source');
        $hash{dbi_username} ||= $self->r->dir_config('ePortal_dbi_username');
        $hash{dbi_password} ||= $self->r->dir_config('ePortal_dbi_password');
        $hash{admin_mode}   ||= $self->r->dir_config('ePortal_admin_mode');
    }

    $hash{dbi_source}   ||= $ENV{EPORTAL_DBI_SOURCE};
    $hash{dbi_username} ||= $ENV{EPORTAL_DBI_USERNAME};
    $hash{dbi_password} ||= $ENV{EPORTAL_DBI_PASSWORD};
    $hash{admin_mode}   ||= $ENV{EPORTAL_ADMIN_MODE};

    if ( $filename and -r $filename ) {
        open(F, $filename);
        while(my $line = <F>) {
            $line =~ tr/\r\n//d;
            next if $line =~ /^\s*#/;
            if ( $line =~ /^\s*(\S+)\s*=\s*(\S+)\s*$/ ) {
                $hash{$1} ||= $2 if exists $hash{$1};
            }
        }
        close F;
    }

    return wantarray ? %hash : \%hash;
}##config_main_parameters



=head2 Application(app_name, (options hash))

Returns ePortal::Application object or undef if no such object exists.

Returns $ePortal itself for application called 'ePortal'.

Returns array of registered applications names if app_name is undef.

Options:

throw => 1 throw Exception::ApplicationNotInstalled if the application is
not installed.

=cut


############################################################################
sub Application {   #04/26/02 12:47
############################################################################
    my $self = shift;
    my $app_name = shift;
    my %p = @_;

    return $self if $app_name eq 'ePortal';

    if ( exists $self->{_application_object}{$app_name} ) {
        return $self->{_application_object}{$app_name};
    }

    if ($p{unconfigured}) {
        eval "use ePortal::App::$app_name;";
        throw ePortal::Exception::ApplicationNotInstalled(-text => $app_name)
            if $@;
        return $self->{_application_object}{$app_name} = "ePortal::App::$app_name"->new();
    }

    throw ePortal::Exception::ApplicationNotInstalled(-text => $app_name)
        if $p{throw};

    return undef;
}##Application


=head2 ApplicationsConfigured()

Returns array of installed and configured application names.

=cut

############################################################################
sub ApplicationsConfigured  {   #04/15/03 8:56
############################################################################
    my $self = shift;
    my @app;

    foreach (keys %{ $self->{applications} }) {
        push @app, $_ if $self->{applications}{$_}; # if configured
    }    
    return @app;
}##ApplicationsConfigured


=head2 ApplicationsInstalled()

Returns array of installed application names based on modules found in
ePortal::App directory

=cut

############################################################################
sub ApplicationsInstalled   {   #03/17/03 11:14
############################################################################
    my $self = shift;

    my $ePortal_pm = $INC{'ePortal/Server.pm'};
    throw ePortal::Exception::Fatal(-text => "Looking for 'ePortal/Server.pm' in \%INC hash but not found!")
        if ! $ePortal_pm;
    my ($name, $path) = File::Basename::fileparse($ePortal_pm, '\.pm');

    my @ApplicationsInstalled;
    throw ePortal::Exception::Fatal(-text => "Cannot open dir $path for reading")
        if ! opendir(DIR, "$path/App");
    while(my $file = readdir(DIR)) {
        if ($file =~ /^(.+)\.pm$/oi) {
            push @ApplicationsInstalled, $1;
        }
    }
    closedir DIR;

    logline('debug', "Found installed applications: ". join(',', @ApplicationsInstalled));
    return @ApplicationsInstalled;
}##ApplicationsInstalled


############################################################################
sub ApplicationName {   #05/15/02 9:02
############################################################################
    'ePortal';
}##ApplicationName

############################################################################
# Function: handle_request
# Description: Подготовка глобального объекта ePortal к обработке
# HTTP запроса.
# Parameters: $r - Apache request
# Returns: Nothing
#
############################################################################
sub handle_request  {   #12/26/00 3:17
############################################################################
    my $self = shift;
    my $r = shift;      # Apache::Request

    # --------------------------------------------------------------------
    # User recognition system
    #
    RECOGNIZE_USER: {

        my $U = $self->{user};

        if ($self->admin_mode) {
            $U->restore('admin');
            $U->UserName('admin');
            $U->FullName('Administrator');
            $U->Enabled(1);
            $U->save;
        } else { # This is normal mode
            last RECOGNIZE_USER if ! $r->connection->user;
            last RECOGNIZE_USER if $self->CheckUserAccount(
                user => $U,
                username => $r->connection->user,
                quick => 1 );
        }
        $self->{username} = $U->username;

    } # end_of_RECOGNIZE_USER


    # Browser recognition system
    if ($ENV{HTTP_USER_AGENT} =~ /MSIE ([\d\.]+)/o) {
        $self->{MSIE} = 1;
        $self->{JavaScript} = $1;
    } else {
        $self->{MSIE} = undef;
        $self->{JavaScript} = undef;
    }

    logline('info', "Connected user[$self->{username}], session[$session{_session_id}]");
    1;
}##handle_request





=head2 CheckUserAccount($username,$password)

Complete checks for a user account. If it is external user then local copy
is created. If local copy is expired, then it is refreshed.

This function is used during login phase.

Parameters:

=over 4

=item * username

User name to check. It is from login dialog box

=item * password

A password from login dialog box to verify

=back

Returns: C<(username,reason)> in array context and C<username> in scalar
context.

In case of bad login the C<username> is undefined and C<reason> is
the code of denial.

In case of successful login C<username> returned

=cut

############################################################################
sub CheckUserAccount    {   #06/21/01 2:00
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with( params => \@_, spec => {
        user => { type => OBJECT, optional => 1},
        username => { type => UNDEF | SCALAR},
        password => { type => UNDEF | SCALAR, optional => 1},
        quick => {type => BOOLEAN, optional => 1}
        });

    $p{reason} = undef;
    $p{user} ||= new ePortal::epUser;

    $self->_CheckUserAccount_username(\%p);

    if ($p{quick}) {    # quick check
        $self->_CheckUserAccount_restore(\%p);
        $self->_CheckUserAccount_require_restored(\%p);
        $self->_CheckUserAccount_disabled(\%p);
        $self->_CheckUserAccount_last_checked_days(\%p);
        if ( $p{last_checked_days} ) {
            if (! $p{user}->ext_user) {
                $self->_CheckUserAccount_restore(\%p);
                $self->_CheckUserAccount_disabled(\%p);
            } else {    
                $self->_CheckUserAccount_ldap_connect(\%p);
                $self->_CheckUserAccount_ldap_search(\%p);
                $self->_CheckUserAccount_ldap_refresh_info(\%p);
            }
        }

    } else { # Complete check
        $self->_CheckUserAccount_restore(\%p);
        if ($p{user_exists} and !$p{user}->ext_user) {
            $self->_CheckUserAccount_disabled(\%p);
            $self->_CheckUserAccount_password(\%p);
        } else {
            $self->_CheckUserAccount_ldap_connect(\%p);
            $self->_CheckUserAccount_ldap_search(\%p);
            $self->_CheckUserAccount_ldap_password(\%p);
            $self->_CheckUserAccount_ldap_refresh_info(\%p);
        }
    }

    if ($p{reason}) {
        logline('warn', "CheckUserAccount: failed for reason: $p{reason}, username: $p{username}");
        $p{user}->clear;
        return (undef, $p{reason});
    } else {
        $p{user}->last_login('now');
        $p{user}->update;

        logline($p{quick} ? 'info' : 'notice',
            "CheckUserAccount: User $p{username} checked successfully");
        return ($p{user}->Username, undef);
    }
}##CheckUserAccount


############################################################################
sub _CheckUserAccount_username {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    if ($p->{username} eq '') {
        $p->{reason} = 'no_user';
    }
}##_CheckUserAccount_username


############################################################################
sub _CheckUserAccount_restore {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    $p->{user_exists} = $p->{user}->restore($p->{username});
    if ( ($p->{user}->Username ne $p->{username}) and
         ($p->{user}->DN ne $p->{username})) {
        $p->{user_exists} = undef;
    }
}##_CheckUserAccount_restore

############################################################################
sub _CheckUserAccount_require_restored {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    if ( !$p->{user_exists} ) {
        $p->{reason} = 'bad_user';
    }
}##_CheckUserAccount_require_restored


############################################################################
sub _CheckUserAccount_password {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    if  (
        ($p->{password} eq '') or
        ($p->{user}->Password ne $p->{password})
        ) {
        $p->{reason} = 'bad_password';
        return;
    }
}##_CheckUserAccount_password


############################################################################
sub _CheckUserAccount_disabled {   #10/31/02 2:54
############################################################################
    my $self = shift;
    my $p = shift;

    return if $p->{reason};

    if ( ! $p->{user}->Enabled ) {
        $p->{reason} = 'disabled';
    }
}##_CheckUserAccount_disabled


############################################################################
sub _CheckUserAccount_last_checked_days {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    my @last_checked = $p->{user}->attribute_object('last_checked')->array;
    @last_checked = (1970,1,1) if @last_checked != 3;
    if ( ! Date::Calc::check_date(@last_checked) ) {
        logline('error', "CheckUserAccout: [last_checked] date from DB is not valid!: ",@last_checked);
        @last_checked = (1970,1,1); # force revalidation
    }

    $p->{last_checked_days} = Date::Calc::Delta_Days(Date::Calc::Today(), @last_checked);
}##_CheckUserAccount_last_checked_days


############################################################################
sub _CheckUserAccount_ldap_connect {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    eval "
    require Net::LDAP;
    require Unicode::Map8;
    require Unicode::String;
    ";
    die $@ if $@;    

    if (!$self->ldap_server) {
        $p->{reason} = 'bad_user';
        return;
    }

    $p->{ldap_server} = $self->ldap_connect();
    if (!$p->{ldap_server}) {
        $p->{reason} = 'system_error';
    }
}##_CheckUserAccount_ldap_connect


############################################################################
sub _CheckUserAccount_ldap_search {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    $p->{ldap_entry} = $self->ldap_search_entry(
            $p->{ldap_server},
            $self->ldap_uid_attr, $p->{username});

    if (!$p->{ldap_entry}) {
        $p->{reason} = 'bad_user';
    }
}##_CheckUserAccount_ldap_search


############################################################################
sub _CheckUserAccount_ldap_password{   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    my $test_connect = $self->ldap_connect(
                            $p->{ldap_entry}->dn, $p->{password});
    if (!$test_connect) {
        $p->{reason} = 'bad_password';
    }
}##_CheckUserAccount_ldap_password


############################################################################
sub _CheckUserAccount_ldap_refresh_info {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    my $ldap_charset = $self->ldap_charset;
    $p->{user}->last_checked('now');
    $p->{user}->UserName(   $p->{username} );
    $p->{user}->DN(         $p->{ldap_entry}->dn);
    $p->{user}->FullName(   cstocs($ldap_charset,'WIN', $p->{ldap_entry}->get_value($self->ldap_fullname_attr)));
    $p->{user}->Title(      cstocs($ldap_charset,'WIN', $p->{ldap_entry}->get_value($self->ldap_title_attr)));
    $p->{user}->Department( cstocs($ldap_charset,'WIN', $p->{ldap_entry}->get_value($self->ldap_ou_attr)));
    $p->{user}->ext_user( 1 );
    $p->{user}->Enabled( 1 );

    my $res = $p->{user_exists} ? $p->{user}->update : $p->{user}->insert;
    $p->{user_exists} = 1;
    if (!$res) {
        $p->{reason} = 'system_error';
    }
}##_CheckUserAccount_ldap_refresh_info






############################################################################
# Function: ldap_connect
# Description: internal function. Used in CheckUserAccount and ValidateUserAccount
# Parameters: optional username and password to connect
# Returns: LDAP server object or undef
#
############################################################################
sub ldap_connect    {   #10/30/02 4:08
############################################################################
    my ($self, $connect_username, $connect_password) = Params::Validate::validate_with( params => \@_, spec => [
        { type => OBJECT },
        { type => UNDEF | SCALAR, optional => 1},
        { type => UNDEF | SCALAR, optional => 1} ] );

    if (!$self->ldap_server) {
        logline('emerg', 'ldap_connect: ldap_server parameter is empty in ePortal.conf');
        return undef;
    }

    # Connect to LDAP server
    if ($connect_username eq '') {
        $connect_username = $self->ldap_binddn;
        $connect_password = $self->ldap_bindpw;
    }
    if ($connect_username ne '' and $connect_password eq '') {
        logline('error', 'ldap_connect: password is empty. Cannot connect to LDAP');
        return undef;
    }
#    $connect_password = cstocs('WIN', 'DOS', $connect_password);
#    $connect_password = cstocs('WIN', 'UTF8', $connect_password);

    my $ldap_server = new Net::LDAP( $self->ldap_server, onerror => 'warn', version => 3 );
    if (!$ldap_server) { return undef; }

    my $mesg;
    if ($connect_username) {
        $mesg = $ldap_server->bind( $connect_username,
                password => $connect_password);
        logline('error', "ldap_connect: authenticating with $connect_username. Error code:", $mesg->is_error);
    } else {
        $mesg = $ldap_server->bind();
        logline('info', "ldap_connect: binding anonymously. Error code:", $mesg->is_error);
    }

    return $mesg->is_error? undef : $ldap_server;
}##ldap_connect



############################################################################
# Function: ldap_search_entry
# Description: internal function.
#
############################################################################
sub ldap_search_entry   {   #10/30/02 4:13
############################################################################
    my ($self, $ldap_server, $search_attr, $search_value) =
        Params::Validate::validate_with( params => \@_, spec => [
        { type => OBJECT },
        { type => OBJECT },
        { type => SCALAR},
        { type => SCALAR} ] );

    my $source_charset = $self->ldap_charset;
    $search_value = cstocs('WIN', $source_charset, $search_value);

    my $filter = sprintf q|(&(%s=%s))|, $search_attr, $search_value;

    my $mesg;
    if ($search_attr eq 'dn') {
        $mesg = $ldap_server->search(
            base => $search_value,
            filter => 'cn=*',
            deref => 'always',
            scope => 'base',
            timelimit => 600,
            attrs => ['*']);
    } else {
        $mesg = $ldap_server->search(
            base => $self->ldap_base,
            deref => 'always',
            filter => $filter,
            scope => 'sub',
            timelimit => 600,
            attrs => ['*']);
    }

    if ($mesg->is_error) {
        logline('emerg', "An error occured during LDAP query: ", $mesg->error);
        return undef;
    }

    my $entry = $mesg->pop_entry;
    if (! ref($entry)) {
        logline('notice', "LDAP entry not found: $search_attr=$search_value");
        return undef;
    }

    return $entry;
}##ldap_search_entry


=head2 cleanup_request()

Cleans all internal variables and caches after request is completed.

=cut

############################################################################
sub cleanup_request {   #12/26/00 3:18
############################################################################
    my $self = shift;
    my $r = shift;

    # --------------------------------------------------------------------
    # Clear ThePersistent cache
    ePortal::ThePersistent::Cached::ClearCache();
    my ($hits, $total, $ratio) = ePortal::ThePersistent::Cached::Statistics();
    logline ('info', "Cache hits: $hits, total: $total, ratio: $ratio");

    # disconnect from database
    if (ref($self->{dbh} eq 'HASH')) {
        foreach (keys %{$self->{dbh}}) {
            $self->{dbh}{$_}->disconnect;
            delete $self->{dbh}{$_};
        }
    }
}##cleanup_request

############################################################################
# Function: ShortUserName
# Parameters: None
# Returns: Фамилия И.О. или Гость
#
############################################################################
sub ShortUserName   {   #12/27/00 9:49
############################################################################
    my $self = shift;

    my $name = $self->user->FullName;
    if ($name) {
        $name =~ s/^(\S+)\s+(\S)\S*\s+(\S)\S*/$1 $2. $3./;
        return $name;
    } elsif ($self->username) {
        return $self->username;
    } else {
        return "Гость";
    }
}##ShortUserName

=head2 isAdmin()

Check current for for admin privilegies.

If the server run under command line then the user always is admin.

Returns [1|0]

=cut

############################################################################
sub isAdmin {   #10/27/00 1:42
############################################################################
    my $self = shift;

    # cache results. see cleanup_request()
    return $self->{_isadmin} if defined $self->{_isadmin};

    # check if running under WEB server or from command line
    return 1 if not exists $ENV{SERVER_SOFTWARE};

    # admin_mode
    return 1 if $self->admin_mode;

    # anonymous cannot be admin
    my $u = $self->username;

    return undef unless $u;

    # iterate list of usernames in admin list
    foreach (@{ $self->admin }) {
        if ($u eq $_) {
            $self->{_isadmin} = 1;
            return 1;
        }
    }

    $self->{_isadmin} = 0;
    return 0;
}##isAdmin


=head2 UserConfig()

Retrieve/store configuration parameter for a user. Anonymous users share
the same parameters. Use $session hash for session specific parameters.

 UserConfig(parameter, value)

Optional C<value> may be hashref of arrayref

Returns current or new value of the parameter.

=cut

############################################################################
sub UserConfig  {   #01/09/01 1:27
############################################################################
    my $self = shift;

    return $self->_Config($self->username, @_);
}##UserConfig


=head2 Config

The same as C<UserConfig> but stores server specific parameters.

=cut

############################################################################
sub Config  {   #03/24/01 10:28
############################################################################
    my $self = shift;
    return $self->_Config('!ePortal!', @_);
}##Config

############################################################################
# Function: _Config
# Description: Вспомогательная функция. Сохранение конфигурационных значений.
# Parameters: username, key, [newvalue]
# Returns: old value or undef if not found
#
############################################################################
sub _Config {   #03/24/01 10:28
############################################################################
    my $self = shift;
    my $username = shift || '!!nouser!!';
    my $keyname = shift;
    my $value;

    # restore existing value from database
    my $dbh = $self->DBConnect;
    my ($dummy_keyname, $dummy_value) =
        $dbh->selectrow_array("SELECT userkey,val FROM UserConfig WHERE username=? and userkey=?",
            undef, $username, $keyname);
    if ($dummy_value =~ /^_REF_/) {
        $dummy_value = thaw(substr($dummy_value, 5));
    }

    # store new value into database
    if (scalar @_) {    # Need to save new value
        my $freezed = $dummy_value = shift @_;
        $freezed = '_REF_' . freeze($dummy_value)
            if (ref $dummy_value);

        if ($dummy_keyname) {   # the key exists
            $dbh->do("UPDATE UserConfig SET val=? WHERE username=? and userkey=?",
                undef, $freezed, $username, $keyname);
        } else {    # the key not exists
            $dbh->do("INSERT into UserConfig(username,userkey,val) VALUES(?,?,?)",
                undef, $username, $keyname, $freezed);
        }
    }

    return $dummy_value;
}##_Config




=head2 DBConnect()

In general C<DBConnect()> is used to get ePortal's database handle.

This function returns C<$dbh> - database handle or throws 
L<ePortal::Exception::DBI|ePortal::Exception>.

=cut

############################################################################
sub DBConnect   {   #02/19/01 11:15
############################################################################
    my $self = shift;
    my $nickname = shift || 'ePortal';

    my $dbi_source = $self->dbi_source;
    my $dbi_username = $self->dbi_username;
    my $dbi_password = $self->dbi_password;

    if ($nickname ne 'ePortal') {
        $dbi_source = $self->_Config("!$nickname!", 'dbi_source');
        if ( $dbi_source eq '' ) {
            throw ePortal::Exception::DBI(-text => "dbi_source [$nickname] not configured")
        } elsif ($dbi_source eq 'ePortal') {
            $dbi_source = $self->dbi_source;
            $nickname = 'ePortal';
        } else {
            $dbi_username = $self->_Config("!$nickname!", 'dbi_username');
            $dbi_password = $self->_Config("!$nickname!", 'dbi_password');
        }
    }

    my $ErrorHandler = sub {
        local $Error::Debug = 1;
        local $Error::Depth = $Error::Depth + 1;
        throw ePortal::Exception::DBI(-text => $_[0], -object => $_[1]);
        1;
    };


    # Cache connection
    if (defined $self->{dbh}{$nickname}) {
        return $self->{dbh}{$nickname} if $self->{dbh}{$nickname}->ping;
    }

    # Extra check connect data before connecting
    throw ePortal::Exception::DBI(-text => "DBI source for $nickname is not defined. Cannot connect to database.")
        if $dbi_source eq '';

    # Do connect. connect returns undef on error
    $self->{dbh}{$nickname} = DBI->connect( $dbi_source, $dbi_username, $dbi_password,
        {ShowErrorStatement => 1, RaiseError => 0, PrintError => 1, AutoCommit => 1});
    throw ePortal::Exception::DBI(-text => $DBI::errstr)
        unless $self->{dbh}{$nickname};

    $self->{dbh}{$nickname}{HandleError} = $ErrorHandler;
    return $self->{dbh}{$nickname};
}##DBConnect



############################################################################
sub statistics  {   #01/25/02 2:16
############################################################################
    my $self = shift;
    my $param = shift;
    my ($sql, @binds);

    if ($param eq 'users_registered') {
        $sql = 'SELECT count(*) from epUser';

    } elsif ($param eq 'users_active_today') {
        $sql = wantarray
            ? 'SELECT username from epUser WHERE last_login >= current_date ORDER BY username'
            : 'SELECT count(*) from epUser WHERE last_login >= current_date';

    } elsif ($param eq 'users_active_now') {
        $sql = wantarray
            ? 'SELECT username from epUser WHERE last_login >= date_sub(now(), interval 5 minute) ORDER BY username'
            : 'SELECT count(*) from epUser WHERE last_login >= date_sub(now(), interval 5 minute)';

    } elsif ($param eq 'sessions_count') {
        $sql = 'SELECT count(*) from sessions';

    } elsif ($param eq 'sessions_active_today') {
        $sql = 'SELECT count(*) from sessions WHERE ts >= current_date';

    } elsif ($param eq 'sessions_active_now') {
        $sql = 'SELECT count(*) from sessions WHERE ts >= date_sub(now(), interval 5 minute)';

    } elsif ($param eq 'pageview_count') {
        $sql = wantarray
            ? "SELECT distinct uid FROM PageView WHERE pvtype = 'user' ORDER BY uid"
            : "SELECT count(*) from PageView WHERE pvtype = 'user'";

    } elsif ($param eq 'notepad_users_count') {
        $sql = wantarray
            ?  "SELECT uid, count(*) as cnt FROM Notepad GROUP BY uid ORDER BY cnt desc"
            : "SELECT count(distinct uid) FROM Notepad";

    } elsif ($param eq 'notepad_count') {
        $sql = "SELECT count(*) FROM Notepad";

    } elsif ($param eq 'contact_users_count') {
        $sql = wantarray
            ? "SELECT uid, count(*) as cnt FROM Contact GROUP BY uid ORDER BY cnt DESC"
            : "SELECT count(distinct uid) FROM Contact";

    } elsif ($param eq 'contact_count') {
        $sql = "SELECT count(*) from Contact";

    } elsif ($param eq 'calendar_users_count') {
        $sql = wantarray
            ? "SELECT uid, count(*) AS cnt FROM Calendar GROUP BY uid ORDER BY cnt DESC"
            : "SELECT count(DISTINCT uid) FROM Calendar";

    } elsif ($param eq 'calendar_count') {
        $sql = "SELECT count(*) FROM Calendar";

    } elsif ($param eq 'todo_users_count') {
        $sql = wantarray
            ? "SELECT uid, count(*) AS cnt FROM ToDo GROUP BY uid ORDER BY cnt DESC"
            : "select count(distinct uid) from ToDo";

    } elsif ($param eq 'todo_count') {
        $sql = "select count(*) from ToDo";

    } elsif ($param eq 'msgitem_users_count') {
        $sql = wantarray
            ? "SELECT coalesce(uid, 'anonymous') as uid, count(*) AS cnt FROM MsgItem GROUP BY uid ORDER BY cnt DESC"
            : "SELECT count(distinct uid) FROM MsgItem";

    } elsif ($param eq 'msgitem_count') {
        $sql = "select count(*) from MsgItem";

    } else {
        return undef;
    }

    return wantarray
        ? @{$self->DBConnect->selectall_arrayref($sql,,@binds)}
        : scalar $self->DBConnect->selectrow_array($sql,,@binds)
}##statistics


############################################################################
sub r   {   #02/21/02 1:48
############################################################################
    return $HTML::Mason::Commands::r;
}##r

############################################################################
sub m   {   #02/21/02 1:49
############################################################################
    return $HTML::Mason::Commands::m;
}##m




=head2 send_email($receipient,$subject,$text)

Send an e-mail on behalf of ePortal server. send_email() make all character
set conversions needed for e-mail.

=cut

############################################################################
sub send_email  {   #01/12/02 12:28
############################################################################
    my $self = shift;
    my $receipient = shift;
    my $subject = shift;
    my $text = join('<br>', @_);

    Mail::Sendmail::sendmail(
        smtp => $self->smtp_server,
        From => '"ePortal server" <eportal@' . $self->mail_domain. '>',
        To => $receipient,
        Subject => $subject,
        Message => "<HTML><body>\n$text\n</body></html>",
        'X-Mailer' => "ePortal v$ePortal::Server::VERSION",
        'Content-type' => 'text/html; charset="windows-1251"',
        );
}##send_email


=head2 onDeleteUser

This is callback function. Do not call it directly. It calls once
onDeleteUser(username) for every application installed.

Parameters:

=over 4

=item * username

User name to delete.

=back

=cut

############################################################################
sub onDeleteUser    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $username = shift;

    foreach my $app_name ($self->ApplicationsConfigured) {
        $self->Application($app_name)->onDeleteUser($username);
    }
}##onDeleteUser


=head2 onDeleteGroup

This is callback function. Do not call it directly. It calls once
onDeleteGroup(groupname) for every application installed.

Parameters:

=over 4

=item * groupname

Group name to delete.

=back

=cut

############################################################################
sub onDeleteGroup    {   #11/19/02 2:14
############################################################################
    my $self = shift;
    my $groupname = shift;

    foreach ($self->ApplicationsConfigured) {
        my $app = $self->Application($_);
        $app->onDeleteGroup($groupname);
    }
}##onDeleteGroup


=head2 max_allowed_packet

Maximum allowed packet size for database. By default MySQL server has
limit to 1M packet size but this limit may be changed.

=cut

############################################################################
sub max_allowed_packet  {   #11/27/02 2:51
############################################################################
    my $self = shift;
    my $dbh = $self->DBConnect;
    my $sth = $dbh->prepare("show variables like 'max_allowed_packet'");
    $sth->execute;
    my $result = ($sth->fetchrow_array())[1];
    $sth->finish;
    if ( $result < 1024*1024 ) {
        logline('emerg', 'Cannot get max_allowed_packet variable');
        $result = 1024 * 1024;
    }
    return $result;
}##max_allowed_packet

1;

__END__



=head1 LOGIN PROCESS

User authorization and authentication is ticket based. The ticked is
created during login process and saved in user's cookie. The ticked is
validated on every request.

=head2 login.htm

It is main login point. The authentication thicket is created here. The 
ticked is stored in user cookie. Format of the ticked is:

 secret:username:remoteip:md5hash

Complete user validation procedure is done by C<CheckUserAccount()>



=head2 Quick validation.

Quick validation of a user is done in
C<ePortal::AuthCookieHandler::recognize_user()>. The user is checked with a 
cookie based ticked. The ticked is signed with MD5 checksum. If something 
is wrong then ticket is cancelled.

Quick validation process is done by C<CheckUserAccount(quick=>1)>


=head2 External users

ePortal may authenticate an user in external directory like LDAP. 
Currently only Novell Netware LDAP server is tested.






=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
