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
    our $VERSION = '4.1';

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
    use Digest::MD5;
    use List::Util qw//;
    use URI;

    # Exception handling and parameters validating modules
    use Error qw/:try/;
    use ePortal::Exception;
    use Params::Validate qw/:types/;

    # ePortal's packages
    use ePortal::Auth::LDAP;
    use ePortal::Attachment;
    use ePortal::Catalog;
    use ePortal::CronJob;
    use ePortal::epGroup;
    use ePortal::epUser;
    use ePortal::Exception;
    use ePortal::PageView;
    use ePortal::PopupEvent;

    # ThePersistent packages
    use ePortal::ThePersistent::Dual;
    use ePortal::ThePersistent::Session;
    use ePortal::ThePersistent::ExtendedACL;
    use ePortal::ThePersistent::UserConfig;
    use ePortal::ThePersistent::UserConfig;
    use ePortal::ThePersistent::Utils;
    use ePortal::ThePersistent::Tools qw/table_exists/; # table exists


    # Some usefull read only internal variables
    use ePortal::MethodMaker( read_only => [qw/ user config_file/]);

    # Main configuration parameters
    my @MAIN_CONFIG_PARAMETERS = (qw/ dbi_source dbi_username dbi_password admin_mode /);
    eval 'use ePortal::MethodMaker( read_only => [@MAIN_CONFIG_PARAMETERS] );';

    my @GENERAL_CONFIG_PARAMETERS = (qw/
            admin debug log_filename log_charset disk_charset
            vhost comp_root applications storage_version
            days_keep_sessions language refresh_interval date_field_style
            smtp_server www_server mail_domain
            ldap_server ldap_base ldap_binddn ldap_bindpw ldap_charset
            ldap_uid_attr ldap_fullname_attr ldap_title_attr
            ldap_ou_attr ldap_group_attr ldap_groupdesc_attr
            /);
    eval 'use ePortal::MethodMaker( read_only => [@GENERAL_CONFIG_PARAMETERS] );';

    # True if the module loaded under Apache HTTP server
    our $RUNNING_UNDER_APACHE = $ENV{MOD_PERL};
    our $MAX_GROUP_NAME_LENGTH = 60;    # maximum length of LDAP DN for group name
    our $STORAGE_VERSION = 11;

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
        username => 'internal',
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
#   skip_applications=1  do not create application objects
# Returns:
#
############################################################################
sub initialize  {   #03/21/03 3:51
############################################################################
    my ($self, %p) = @_;

    $self->DBConnect;
    throw ePortal::Exception::DatabaseNotConfigured
        if ! table_exists($self->DBConnect, 'UserConfig');

    $self->config_load;
    throw ePortal::Exception::DatabaseNotConfigured
        if $self->storage_version != $STORAGE_VERSION;

    # Precreate some objects
    $self->{user} = new ePortal::epUser;
}##initialize

############################################################################
sub config_load {   #03/17/03 3:38
############################################################################
    my $self = shift;

    # Try load config hash
    my $c = $self->Config('config');
    if ( ref($c) eq 'HASH' ) {
        foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
            $self->{$par} = $c->{$par};
        }

    } else {    # Old style 'row per parameter' config
        foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
            $self->{$par} = $self->Config($par);
        }
    }

    # Initialize some of the parameters to empty values
    $self->{admin} = [] if ref($self->{admin}) ne 'ARRAY';
    $self->{applications} = {} if ref($self->{applications}) ne 'HASH';
}##config_load


############################################################################
sub config_save {   #03/17/03 3:38
############################################################################
    my $self = shift;

    my $c = {};

    # Load configuration parameters
    foreach my $par (@GENERAL_CONFIG_PARAMETERS) {
        $c->{$par} = $self->{$par};
    }
    $self->Config('config', $c);
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
        throw ePortal::Exception::Fatal( -text => 'Apache::Request object \$r is not available.')
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



=head2 Application()

 $app = $ePortal->Application('appname');

Returns ePortal::Application object or undef if no such object exists.

Returns $ePortal itself for application called 'ePortal'.

throws Exception::ApplicationNotInstalled if the application is
not installed.

=cut


############################################################################
sub Application {   #04/26/02 12:47
############################################################################
    my $self = shift;
    my $app_name = shift;
    my %p = @_;

    return $self if $app_name eq 'ePortal';
    return $self->{_application_object}{$app_name} if exists $self->{_application_object}{$app_name};

    eval "use ePortal::App::$app_name;";
    if ( $@ ) {
        logline ('emerg', "Cannot load Application module [$app_name]: $@");
        throw ePortal::Exception::ApplicationNotInstalled(-app => $app_name); 
    } 

    my $app = "ePortal::App::$app_name"->new();
    logline('info', "Created Application object $app_name");

    throw ePortal::Exception::DatabaseNotConfigured(-app => $app_name)
        if $app->storage_version != $ePortal::Server::STORAGE_VERSION and 
           ! $p{skip_storage_version_check} ;

    $self->{_application_object}{$app_name} = $app;

    return $app;
}##Application






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
sub username    {   #06/19/2003 4:46
############################################################################
    my $self = shift;

    if (@_ and !$self->admin_mode) {
        my $newusername = shift;
        my ($un, $reason) = $self->CheckUserAccount( user => $self->{user},
                                username => $newusername, quick => 1 );

        $self->{username} = $un;
    }

    return $self->{username};
}##username




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
    $self->_CheckUserAccount_restore(\%p);

    if ($p{quick}) {    # quick check
        $self->_CheckUserAccount_require_restored(\%p);
        $self->_CheckUserAccount_disabled(\%p);

    } else { # Complete check WITH PASSWORD
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

    my @last_checked = $p->{user}->attribute('last_checked')->array;
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

    try {
        $p->{auth_ldap} = new ePortal::Auth::LDAP($p->{username});
    } catch ePortal::Exception::Fatal with {
        my $E = shift;
        logline('error', "LDAP error: $E");
        $p->{reason} = 'system_error';
    };
}##_CheckUserAccount_ldap_connect


############################################################################
sub _CheckUserAccount_ldap_search {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    $p->{reason} = 'bad_user' if ! $p->{auth_ldap}->check_account;
}##_CheckUserAccount_ldap_search


############################################################################
sub _CheckUserAccount_ldap_password{   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    $p->{reason} = 'bad_password' if ! $p->{auth_ldap}->check_password($p->{password});
}##_CheckUserAccount_ldap_password


############################################################################
sub _CheckUserAccount_ldap_refresh_info {   #10/31/02 2:54
############################################################################
    my ($self, $p) = @_;
    return if $p->{reason};

    # General information about the user
    $p->{user}->last_checked('now');
    $p->{user}->UserName(   $p->{username} );
    $p->{user}->DN(         $p->{auth_ldap}->dn);
    $p->{user}->FullName(   $p->{auth_ldap}->full_name );
    $p->{user}->Title(      $p->{auth_ldap}->title );
    $p->{user}->Department( $p->{auth_ldap}->department );
    $p->{user}->ext_user( 1 );
    $p->{user}->Enabled( 1 );

    my $res;
    if ( $p->{user_exists} ) {
        $res = $p->{user}->update;
    } else {
        $res = $p->{user}->insert;

        # For new users refresh group membership immediately
        my $G = new ePortal::epGroup;
        foreach my $g ($p->{auth_ldap}->membership) {
            if ($G->restore($g)) {
                $p->{user}->add_groups($g);
            }    
        }    
    }

    $p->{user_exists} = 1;
    if (!$res) {
        $p->{reason} = 'system_error';
    }

}##_CheckUserAccount_ldap_refresh_info






=head2 cleanup_request()

Cleans all internal variables and caches after request is completed.

=cut

############################################################################
sub cleanup_request {   #12/26/00 3:18
############################################################################
    my $self = shift;

    # Clear ThePersistent cache
    ePortal::ThePersistent::Cached::ClearCache();
    #my ($hits, $total, $ratio) = ePortal::ThePersistent::Cached::Statistics();
    #logline ('info', "Cache hits: $hits, total: $total, ratio: $ratio");

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

    return $self->{_isadmin}
        if defined $self->{_isadmin};   # cache results.

    return 1 if $self->admin_mode;      # Admin mode on

    my $u = $self->username;            # anonymous cannot be admin
    return undef unless $u;

    return 1 if $u eq 'internal';       # Special internal account
                                        # Command line utilities

    # iterate list of usernames in admin list
    $self->{_isadmin} = 1
        if List::Util::first {$u eq $_} @{ $self->admin };

    return $self->{_isadmin};
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
    eval {
    $self->{dbh}{$nickname} = DBI->connect( $dbi_source, $dbi_username, $dbi_password,
        {ShowErrorStatement => 1, RaiseError => 0, PrintError => 1, AutoCommit => 1});
    };
    throw ePortal::Exception::DBI(-text => $DBI::errstr || $@)
        if (! $self->{dbh}{$nickname}) or $@;

    $self->{dbh}{$nickname}{HandleError} = $ErrorHandler;
    return $self->{dbh}{$nickname};
}##DBConnect


############################################################################
sub r   {   #02/21/02 1:48
############################################################################
    return $HTML::Mason::Commands::r;
}##r

############################################################################
sub m   {   #02/21/02 1:49
############################################################################
    return $HTML::Mason::Commands::m;
    # HTML::Mason::Request->instance
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
    my $text = join("\n", @_);

    my $boundary = '=ePortal-boundary';
    Mail::Sendmail::sendmail(
        smtp => $self->smtp_server,
        From => '"ePortal server" <eportal@' . $self->mail_domain. '>',
        To => $receipient,
        Subject => $subject,
        Message => "This is MIME letter\n\n\n".
                    "--$boundary\n".
                    "Content-Type: text/html; charset=windows-1251\n".
                    "Content-Transfer-Encoding: 8bit\n\n".
                    "<HTML><body>\n$text\n</body></html>\n\n".
                    "--$boundary--\n",
        'X-Mailer' => "ePortal v$ePortal::Server::VERSION",
        #'Content-type' => 'text/html; charset="windows-1251"',
        'Content-type' => join("\n",
                    'multipart/related;',
                    '  boundary="' . $boundary . '";',
                    '  type=text/html'),
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

    foreach my $app_name ($self->ApplicationsInstalled) {
        try {
        $self->Application($app_name)->onDeleteUser($username);
        };
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

    foreach ($self->ApplicationsInstalled) {
        try {
        my $app = $self->Application($_);
        $app->onDeleteGroup($groupname);
        };
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
