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

BEGIN {
    # Auto flush for command line
    $| = 1;

    # to use an command line utility in source tree
    push @INC, '../lib' if (-d '../lib') and ! grep {$_ eq '../lib'} @INC;
}



package ePortal::CommandLine;
    our $VERSION = '4.2';

    use Getopt::Long qw//;
    use HTML::Mason;

    use ePortal::Utils;
    use ePortal::Global;
    use ePortal::ThePersistent::Tools;
    use ePortal::Server;

    use Params::Validate qw/:types/;
    use Error qw/:try/;
    use ePortal::Exception;

############################################################################
sub new {   #12/26/00 3:34
############################################################################
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %p = Params::Validate::validate_with(
        params => \@_,
        spec => {
                # Used additional options. See GetOptions for naming details
                # example: { 'mail' => 1, 'data' => 1 }
            options => {type => HASHREF, optional => 1},
                # The internal name of application if applicable
            application => {type => SCALAR, optional => 1},
                # just file name without description
            filename => {type => SCALAR},
                # Short description of the script
            description => {type => SCALAR},
        });

    # --------------------------------------------------------------------
    my $self = { %p,
        opt_config => undef,
        opt_help   => undef,
        opt_quiet  => undef,
        opt_mail   => 1,
        opt_data   => 1,
        vhost    => undef,
     };
    bless $self, $class;

    $self->GetOptions();
    $self->{server} = try {
        new ePortal::Server( config_file => $self->{opt_config});
    } otherwise {
        my $E = shift;
        print STDERR "Cannot create Server object:\n$E\n";
        exit 1;
    };

    return $self;
}##new

############################################################################
sub GetOptions  {   #11/29/02 11:02
############################################################################
    my $self = shift;

    # default common options
    my %options = ();
    $options{'help|h!'} = \$self->{opt_help};
    $options{'config|c=s'} = \$self->{opt_config};
    $options{'quiet|q!'} = \$self->{opt_quiet};

    $options{'mail!'} = \$self->{opt_mail} if $self->{options}{mail};
    $options{'data!'} = \$self->{opt_data} if $self->{options}{data};

    # get options
    Getopt::Long::GetOptions( %options );

    # parse some common and mandatory options
    if ($self->{opt_help} ) {
        $self->PrintHelp('verbose');
        exit(1);
    } else {
        $self->PrintHelp() unless $self->{opt_quiet};
    }

}##GetOptions


############################################################################
sub PrintHelp   {   #12/26/02 10:28
############################################################################
    my $self = shift;
    my $verbose = shift;

    print
        "\nePortal command line utility v.$main::VERSION\n",
        "Copyright (c) 2001-2002 Sergey Rusakov <rusakov_sa\@users.sourceforge.net>\n\n",
        $self->{filename}, ' - ', $self->{description}, "\n\n";

    return if ! $verbose;

    print $self->{filename}, " [options]\n\n",
        "\tOptions:\n",
        "\t --help             This help screen\n",
        "\t --quiet            Be quiet if possible\n",
        "\t --config=filename  Use this config file\n";
    print
        "\t --nodata           Do not insert any default data into database\n"
        if $self->{options}{data};
    print
        "\t --nomail           Do not send any mail\n"
        if $self->{options}{mail};
    print
        "\n\n";
}##PrintHelp



############################################################################
sub CreateApplication   {   #12/12/02 9:47
############################################################################
    my $self = shift;
    my $ApplicationName = shift || $self->{application};

    my $app = try {
        $ePortal->Application( $ApplicationName );
    } otherwise {
        logline('emerg',
            "Cannot create application object: $ApplicationName\n",
            "Application probably is not installed");
        exit(2);
    };

    return $app;
}##CreateApplication

############################################################################
# Function: LastThisRun
sub LastThisRun {   #12/13/02 9:31
############################################################################
    my $self = shift;

    $self->CreateServer() if not ref($ePortal);

    my $LAST_RUN = $ePortal->Config('last_run_' . $self->{filename});
    my $THIS_RUN = $ePortal->DBConnect->selectrow_array('select now()');
    $ePortal->Config('last_run_' . $self->{filename}, $THIS_RUN);

    return ($LAST_RUN, $THIS_RUN);
}##LastThisRun




# ------------------------------------------------------------------------
# This function is used in crontab command line utilities.
# Database creation scripts use native print
############################################################################
sub print   {   #01/08/03 3:22
############################################################################
    my $self = shift;

    CORE::print @_, "\n" unless $self->{opt_quiet};
}##print


############################################################################
# Function: run_template
# Description: Run Mason template and return HTML result
#
############################################################################
sub run_template    {   #04/29/03 2:52
############################################################################
    my ($self, $template_name, %p) = @_;

    throw ePortal::Exception::Fatal(-text => 'comp_root parameter is unknown. Cannot run template')
        if ! $self->{server}->comp_root;

    # create new HTML::Mason::Interp object
    $self->{outbuf} = undef;
    if (! $self->{interp} ) {
        $self->{interp} = HTML::Mason::Interp->new
            (comp_root  => $self->{server}->comp_root,
             autohandler_name => 'autohandler.mc',
             allow_globals => [qw/$ePortal/],
             out_method => \$self->{outbuf}
            );
    }

my @files = $self->{interp}->resolver->glob_path('/cmdline/*.mc');
print join "\n", @files;
exit;

    $self->{interp}->exec("/templates/$template_name", %p);

    return $self->{outbuf};
}##run_template

1;
