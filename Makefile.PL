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
# $Date: 2003/04/24 05:36:51 $
# $Header: /home/cvsroot/ePortal/Makefile.PL,v 3.5 2003/04/24 05:36:51 ras Exp $
#
#----------------------------------------------------------------------------

use strict;
$^W = 1;

use ExtUtils::Manifest;
use ExtUtils::MakeMaker qw( prompt WriteMakefile );
use Data::Dumper;

# ------------------------------------------------------------------------
#
our $HOME = '/home/ePortal';
for my $i(0 .. $#ARGV) {
    if ($ARGV[$i] =~ /HOME=(.*)/) {
        $HOME = $1;
        delete $ARGV[$i];
    }
}
our $target = shift @ARGV;

our %OPTIONS = (
    NAME        => 'ePortal',    
    AUTHOR      => 'Sergey Rusakov <rusakov_sa@users.sourceforge.net>',
    dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean       => { FILES => 'config.cache' },
    DIR => [],
#   INST_HTMLLIBDIR => 'comp_root/manual',
    PREREQ_PM       => {
        'CGI'                   => 2.81,
        'Data::Dumper'          => 0,
        'Date::Calc'            => 5.0,
        'DBD::mysql'            => 0,
        'DBI'                   => 1.28,
        'Digest::MD5'           => 2.13,
        'HTML::Mason'           => 1.16,
        'Image::Size'           => 2.99,
        'Mail::Sendmail'        => 0.78,
        'MD5'                   => 0,
        'mod_perl'              => 1.26,
        'Params::Validate'      => 0.24,
        'Storable'              => 0,
        'Text::Wrap'            => 0,
        'Error'                 => 0,
        }, # e.g., Module::Name => 0 or 1.1
);

our %KNOWN_TARGETS = (
    ePortal => {
        VERSION_FROM => 'lib/ePortal/Server.pm',
        ABSTRACT => 'Company wide WEB organizer (electronic portal)',
    },
    OffPhones => {
        VERSION_FROM => 'lib/ePortal/App/OffPhones.pm',
        ABSTRACT => 'ePortal application: Phone directory',
    },
    MsgForum => {
        VERSION_FROM => 'lib/ePortal/App/MsgForum.pm',
        ABSTRACT => 'ePortal application: Discussion forums',
    },
    CompInventory => {
        VERSION_FROM => 'lib/ePortal/App/CompInventory.pm',
        ABSTRACT => 'ePortal application: Computer inventory',
    },
    Diskoteka => {
        VERSION_FROM => 'lib/ePortal/App/Diskoteka.pm',
        ABSTRACT => 'ePortal application: Software archive',
    },
    Organizer => {
        VERSION_FROM => 'lib/ePortal/App/Organizer.pm',
        ABSTRACT => 'ePortal application: Personal Organizer',
    },
);


if (! $target or !exists $KNOWN_TARGETS{$target}) {
    foreach my $t (keys %KNOWN_TARGETS) {
        if (-f $KNOWN_TARGETS{$t}{VERSION_FROM}) {
            $target = $t;
            last;
        }
    }
}
unless ($target) {
    print STDERR "Target not found\n";
    exit;
}

# ------------------------------------------------------------------------
# Command line parsing complete
print "Using target: $target\n";
print "Using ePortal home dir: $HOME\n";

# ------------------------------------------------------------------------
# Are we running make in source tree?
# There should be all knows targets in the source tree
my $in_source_tree = 1;
foreach (keys %KNOWN_TARGETS ) {
    if (! -f $KNOWN_TARGETS{$_}{VERSION_FROM}) {
        $in_source_tree = 0;
    }
}

# ------------------------------------------------------------------------
# Prepare filelists
#
our $FILES = ExtUtils::Manifest::manifind();
our @MANIFEST = ();
load_manifest_files();

our @COMP_ROOT_FILES = ();
our @BIN_FILES = ();
our @SAMPLES_FILES = ();
our @IMAGES_FILES = ();
foreach (@MANIFEST) {
    push @COMP_ROOT_FILES, $_ if m|^comp_root/|;
    push @BIN_FILES, $_ if m|^bin/|;
    push @SAMPLES_FILES, $_ if m|^samples/|;
    push @IMAGES_FILES, $_ if m|^images/|;
}

# ------------------------------------------------------------------------
# Create Makefile
#
$OPTIONS{NAME} = "ePortal-$target" if $target ne 'ePortal';
foreach (keys %{ $KNOWN_TARGETS{$target} }) {
    $OPTIONS{$_} = $KNOWN_TARGETS{$target}{$_};
}
WriteMakefile( %OPTIONS);


# ------------------------------------------------------------------------
# If we are in source tree then rebuild MANIFEST.SKIP and MANIFEST
if ($in_source_tree == 1) { # All possible targets are present
                            # so we are in source tree
    print "Rebuilding MINIFEST\n";
    open(M, ">MANIFEST") or die $!;
    foreach (@MANIFEST) {
        print M "$_\n";
    }
    close M;
}



############################################################################
sub load_manifest_files {   #05/29/02 2:04
############################################################################
    @MANIFEST = ();

    FILE:
    foreach (sort keys %$FILES) {

        # Skip for all targets
        next if m|CVS|;
        next if m|^blib/|;
        next if m|^bundle|i;
        next if m|^docs|i;
        next if m|^web|i;
        next if m|^pm_to_blib|;

        next if m|config\.cache|;
        next if m|MANIFEST.SKIP|;
        next if m|mcheck.*\.pl|;
        next if m|tar\.gz$|;
        next if m|test\.|;
        next if m|\.BAK$|i;
        next if m|\.OLD$|i;
        next if m|\.tag$|i;
        next if m|^faq-rus\.pod|i;
        next if m|^gen_pods\.pl|i;
        next if m|^Makefile$|;
        next if m|^make_dist|;
        next if m|^README\.pod|i;
        next if m|^todo|i;
        next if m|^set_appl_version\.pl|i;
        next if m|^\.| or m|/\.|;       # names starting with .

        my $file = $_;

        # include files for All targets
        if (        $file =~ /^manifest$/i or
                    $file =~ /^makefile\.pl/i or
                    $file =~ /^readme\.html/i or
                    $file =~ /^readme$/i ) {
            push @MANIFEST, $file;
            next FILE;
        }

        # For applications: include all files with $target in path
        foreach my $t (keys %KNOWN_TARGETS) {
            next if $t eq 'ePortal';    # take it by default
            if ($file =~ m|[-_\./]$t[-_\./]|) {
                if ($t eq $target) {
                    push @MANIFEST, $_;
                }
                next FILE;
            }
        }

        # MsgForum files
        # Historicaly they are reside in forum dir
        if ($file =~ m|comp_root/forum/|) {
            if ($target eq 'MsgForum') { push @MANIFEST, $_ } else { next FILE }
        }
        if ($file =~ m|pv/sections/forum|) {
            if ($target eq 'MsgForum') { push @MANIFEST, $_ } else { next FILE }
        }

        # All Application files are included
        next FILE if $target ne 'ePortal';
        push @MANIFEST, $_;
    }
}##load_manifest_files


# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
package MY;

sub constants {
    my $self = shift;

    my $result = $self->SUPER::constants(@_);

    $result .= "\nHOME = $HOME\n\n";

    $result .= "COMP_ROOT_FILES = " .
        join(" \\\n\t", @COMP_ROOT_FILES) .
        "\n\n";

    $result .= "BIN_FILES = " .
        join(" \\\n\t", @BIN_FILES) .
        "\n\n";

    $result .= "SAMPLES_FILES = " .
        join(" \\\n\t", @SAMPLES_FILES) .
        "\n\n";

    $result .= "IMAGES_FILES = " .
        join(" \\\n\t", @IMAGES_FILES) .
        "\n\n";

    $result;
}


sub top_targets {
   my $self = shift;
   my $result = $self->SUPER::top_targets(@_);

   # remove htmlifypods from ALL: target
   $result =~ s/^(all\s.*)htmlifypods(.*)$/$1$2/m;

   $result;
}


sub dist {
    my $self = shift;
    my $result = $self->SUPER::dist(@_);

    # remove htmlifypods from ALL: target
    #$result .= "\n" . 'TO_UNIX = $(CHMOD) 0755 $(BIN_FILES)' . "\n";
    #$result =~ s/^(TO_UNIX\s*=).*$/$1 \$(CHMOD) 0755 \$(BIN_FILES)/m;

    $result;
}

sub install {
    my $self = shift;
    my $result = $self->SUPER::install(@_);

    # Add target to 'install ::'
    $result =~ s/^install\s+:+.*$/$& eportal_home_install/im;

    $result .= "\neportal_home_install ::\n";

    # --------------------------------------------------------------------
    # INSTALL with -MExtUtils::Install
    #
    $result .= "\t\@\$(MKPATH) \$(HOME)\n";
    $result .= "\t" . '$(PERL) "-I$(PERL_LIB)" -MExtUtils::Install \\' . "\n";
    $result .= "\t" . '-e "install({bin => \'$(HOME)/bin\', comp_root => \'$(HOME)/comp_root\', images => \'$(HOME)/images\', samples => \'$(HOME)/samples\'}, 1)"' . "\n";

    # --------------------------------------------------------------------
    # INSTALL with $(CP) files
    #
#   foreach my $file (@COMP_ROOT_FILES, @BIN_FILES, @SAMPLES_FILES, @IMAGES_FILES) {
#       my $targetdir = $file;
#       $targetdir =~ s|^(.*)/[^/]+|$1|;
#       $result .= "\t\@\$(MKPATH) \$(HOME)/$targetdir\n";
#       $result .= "\t\$(CP) $file \$(HOME)/$file\n";
#   }
#   foreach my $file (@BIN_FILES) {
#       $result .= "\t\@\$(CHMOD) 0755 \$(HOME)/$file\n";
#   }

    $result .= "\n";



    $result;
}


