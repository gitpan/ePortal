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
# $Header: /home/cvsroot/ePortal/bin/ePortal.pl,v 3.5 2003/04/24 05:36:51 ras Exp $
#
#----------------------------------------------------------------------------
#
# Description: Command line utility to check database connection and
# database structure of ePortal storage.
#

our $VERSION = sprintf '%d.%03d', q$Revision: 3.5 $ =~ /: (\d+).(\d+)/;
use ePortal::CommandLine;
use ePortal::ThePersistent::Tools;
use ePortal::Global;
use ePortal::Utils;

# ------------------------------------------------------------------------
# Read command line parameters

my $cmd = new ePortal::CommandLine(
        filename => 'ePortal.pl',
        description => "Create and check database structure for ePortal",
        options => { 'data' => 1 },
    );

unless ($cmd->{opt_quiet}) {
    print "\n\nUsing config file: ", $ePortal->config_file, "\n";
    print "DBI source: ", $ePortal->dbi_source, "\n";
    print "DBI user: ", $ePortal->dbi_username, "\n";
    print "DBI password: ", $ePortal->dbi_password ? 'x' x length($ePortal->dbi_password) : undef, "\n";
    print "\n";
    print "Press <Enter> to continue";
    <STDIN>;
}
$dbh = $ePortal->DBConnect;

our ($current_storage_version);



# ------------------------------------------------------------------------
# @metags 09.UserConfig
STEP09: {
    print "table UserConfig\n";
    if (! table_exists($dbh, 'UserConfig')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `UserConfig` (
                `username` varchar(64) NOT NULL default '',
                `userkey` varchar(255) NOT NULL default '',
                `val` text,
            PRIMARY KEY  (`username`,`userkey`)
        )
        });
        print "\tcreated\n";
    }
}


# ------------------------------------------------------------------------
# @metags 21.sessions
STEP21: {
    print "table sessions\n";
    if (! table_exists($dbh, 'sessions')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `sessions` (
            `id` varchar(32) NOT NULL default '',
            `a_session` text,
            `ts` timestamp(14) NOT NULL,
            PRIMARY KEY  (`id`)
            )
        });

        print "\tcreated\n";
    }
}




# ------------------------------------------------------------------------
#  @metags 22.PopupEvent
{
    print "table PopupEvent\n";
    if (! table_exists($dbh, 'PopupEvent')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `PopupEvent` (
            `id` int(11) NOT NULL auto_increment,
            `username` varchar(64) default NULL,
            `event_time` datetime default NULL,
            `instance` varchar(64) default NULL,
            `originator` varchar(80) default NULL,
            `memo` text,
            PRIMARY KEY  (`id`)
            )
        });
        print "\tcreated\n";
    }
    if (! index_exists($dbh, 'PopupEvent', 'username')) {
        DO_SQL($dbh, qq{ alter table PopupEvent ADD INDEX username (username) });
        print "\tindex created\n";
    }
    # 3.0
    if (column_type($dbh, 'PopupEvent', 'id') !~ /auto_inc/) {
        DO_SQL($dbh, "ALTER TABLE PopupEvent MODIFY id int(11) not null auto_increment");
        print "\tcolumn id upgraded\n";
    }
}

# ------------------------------------------------------------------------
# @metags 23.epUser
{
    print "table epUser\n";
    if (! table_exists($dbh, 'epUser')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `epUser` (
            `id` int(11) NOT NULL auto_increment,
            `username` varchar(64) NOT NULL default 'no name',
            `ext_user` decimal(2,0) NOT NULL default '0',
            `enabled` decimal(2,0) NOT NULL default '0',
            `title` varchar(255) default NULL,
            `department` varchar(255) default NULL,
            `last_checked` date default NULL,
            `password` varchar(255) default NULL,
            `fullname` varchar(255) default NULL,
            `last_login` datetime default NULL,
            `email` varchar(255) default NULL,
            PRIMARY KEY  (`id`)
            )
        });
        print "\tcreated\n";
    }
    if (! index_exists($dbh, 'epUser', 'username')) {
        DO_SQL($dbh, "alter table epUser ADD UNIQUE INDEX username (username)");
        print "\tindex created: username\n";
    }
    if (! column_exists($dbh, 'epUser', 'dn')) {
        DO_SQL($dbh, qq{alter table epUser ADD `dn` varchar(64)  AFTER `username` });
        print "\tadded column dn\n";
    }
    # 3.0
    if (column_type($dbh, 'epUser', 'id') !~ /auto_inc/) {
        DO_SQL($dbh, "ALTER TABLE epUser MODIFY id int(11) not null auto_increment");
        print "\tcolumn id upgraded\n";
    }
}

# ------------------------------------------------------------------------
# @metags 23.epGroup
{
    print "table epGroup\n";
    if (! table_exists($dbh, 'epGroup')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `epGroup` (
            `id` int(11) not null auto_increment,
            `groupname` varchar(64) default NULL,
            `groupdesc` varchar(255) default NULL,
            PRIMARY KEY  (`id`)
            )
        });
        print "\tcreated\n";
    }
    if (! index_exists($dbh, 'epGroup', 'groupname')) {
        DO_SQL($dbh, qq{ alter table epGroup ADD UNIQUE INDEX groupname(groupname) });
        print "\tindex created\n";
    }
    if (! column_exists($dbh, 'epGroup', 'ext_group')) {
        DO_SQL($dbh, qq{ alter table epGroup ADD ext_group decimal(2,0) NOT NULL default '0' });
        print "\tadded column ext_group\n";
    }
    # 3.0
    if (column_type($dbh, 'epGroup', 'id') !~ /auto_inc/) {
        DO_SQL($dbh, "ALTER TABLE epGroup MODIFY id int(11) not null auto_increment");
        print "\tcolumn id upgraded\n";
    }
}


# ------------------------------------------------------------------------
# @metags 23.epUsrGrp
{
    print "table epUsrGrp\n";
    if (! table_exists($dbh, 'epUsrGrp')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `epUsrGrp` (
            `username` varchar(64) NOT NULL default '',
            `groupname` varchar(64) NOT NULL default '',
            PRIMARY KEY  (`username`,`groupname`)
            )
        });
        print "\tcreated\n";
    }
} # end of STEP_USERS_GROUPS


# ------------------------------------------------------------------------
# @metags 24.PageView
{
    print "table PageView\n";
    if (! table_exists($dbh, 'PageView')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `PageView` (
            `id` int(11) not null auto_increment,
            `title` varchar(255) default NULL,
            `columnswidth` varchar(255) default NULL,
            `pvtype` varchar(255) default NULL,
            `uid` varchar(64) default NULL,
            xacl_read varchar(64) default NULL,
            PRIMARY KEY  (`id`)
            )
        });
        print "\tcreated\n";
    }
    if (! index_exists($dbh, 'PageView', 'pvtype')) {
        DO_SQL($dbh, qq{ alter table PageView ADD INDEX pvtype (pvtype,uid) });
        print "\tindex created\n";
    }
    # 3.0
    if (column_type($dbh, 'PageView', 'id') !~ /auto_inc/) {
        DO_SQL($dbh, "ALTER TABLE PageView MODIFY id int(11) not null auto_increment");
        print "\tcolumn id upgraded\n";
    }
    # 3.0 Remove old ACL fields
    foreach my $field (qw/gid_r gid_w gid_a all_r all_reg all_a all_w gid/) {
        if ( column_exists($dbh, 'PageView', $field)) {
            DO_SQL($dbh, "ALTER TABLE PageView DROP COLUMN `$field`");
            print "\tdropped column $field\n";
        }
    }
    # 3.0 
    if (! column_exists($dbh, 'PageView', 'xacl_read')) {
        DO_SQL($dbh, "ALTER TABLE PageView ADD COLUMN xacl_read varchar(64) default NULL");
        DO_SQL($dbh, "UPDATE PageView SET xacl_read='owner' WHERE pvtype='user'");
        DO_SQL($dbh, "UPDATE PageView SET xacl_read='everyone' WHERE pvtype='default'");
        DO_SQL($dbh, "UPDATE PageView SET xacl_read='everyone' WHERE pvtype='template'");

        print "\tcreated column xacl_read\n";
    }
}


# ------------------------------------------------------------------------
# @metags 24.PageSection
{
    my $result;
    print "table PageSection\n";
    if (! table_exists($dbh, 'PageSection')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `PageSection` (
            `id` int(11) not null auto_increment,
            `params` varchar(255) default NULL,
            `title` varchar(255) default NULL,
            `width` varchar(255) default NULL,
            `mandatory` decimal(2,0) NOT NULL default '0',
            `component` varchar(255) default NULL,
            `memo` varchar(255) default NULL,
            `url` varchar(255) default NULL,
            `uid` varchar(64) default NULL,
            xacl_read varchar(64) default NULL,
            PRIMARY KEY  (`id`)
            )
        });
        print "\tcreated\n";
    }
    # 3.0
    if (column_type($dbh, 'PageSection', 'id') !~ /auto_inc/) {
        DO_SQL($dbh, "ALTER TABLE PageSection MODIFY id int(11) not null auto_increment");
        print "\tcolumn id upgraded\n";
    }

    # 3.0 Remove old ACL fields
    foreach my $field (qw/gid_r gid_w gid_a all_r all_reg all_a all_w gid/) {
        if ( column_exists($dbh, 'PageSection', $field)) {
            DO_SQL($dbh, "ALTER TABLE PageSection DROP COLUMN `$field`");
            print "\tdropped column $field\n";
        }
    }
    # 3.0 
    if (! column_exists($dbh, 'PageSection', 'xacl_read')) {
        DO_SQL($dbh, "ALTER TABLE PageSection ADD COLUMN xacl_read varchar(64) default NULL");
        print "\tcreated column xacl_read\n";
    }
}



# ------------------------------------------------------------------------
# @metags 24.UserSection
{
    print "table UserSection\n";
    if (! table_exists($dbh, 'UserSection')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `UserSection` (
            `id` int(11) not null auto_increment,
            `minimized` decimal(2,0) NOT NULL default '0',
            `pv_id` int(11) default NULL,
            `ps_id` int(11) default NULL,
            `colnum` int(11) NOT NULL default '1',
            `setupinfo` text,
            PRIMARY KEY  (`id`)
            )
        });
        print "\tcreated\n";
    }
    if (! index_exists($dbh, 'UserSection', 'pv_id')) {
        DO_SQL($dbh, qq{
            alter table UserSection
            ADD INDEX pv_id(pv_id, colnum)
        });
        print "\tindex created\n";
    }
    # 3.0
    if (column_type($dbh, 'UserSection', 'id') !~ /auto_inc/) {
        DO_SQL($dbh, "ALTER TABLE UserSection MODIFY id int(11) not null auto_increment");
        print "\tcolumn id upgraded\n";
    }
    # 3.0
    foreach my $column (qw/pv_id ps_id colnum/) {
        if (column_type($dbh, 'UserSection', $column) !~ /int\(11\)/) {
            DO_SQL($dbh, "ALTER TABLE UserSection MODIFY $column int(11) default NULL");
            print "\tcolumn $column upgraded\n";
        }
    }
}

# @metags Catalog
    print "table Catalog\n";
    if (! table_exists($dbh, 'Catalog')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `Catalog` (
              `id` int(11) NOT NULL auto_increment,
              `RecordType` enum('link','group','text','textHTML','textpara','textline','file') NOT NULL default 'group',
              `Parent_id` int(11) default NULL,
              `Title` varchar(255) NOT NULL default '',
              `Nickname` varchar(255) default NULL,
              `URL` varchar(255) default NULL,
              `Priority` tinyint(4) NOT NULL default '5',
              `Clicks` int(11) default NULL,
              `Hits` int(11) default NULL,
              `Memo` varchar(255) default NULL,
              `uid` varchar(64) default NULL,
              `ts` timestamp(14) NOT NULL,
              `filename` varchar(255) default NULL,
              `xacl_read` varchar(64) default NULL,
              `xacl_write` varchar(64) default NULL,
              `xacl_admin` varchar(64) default NULL,
              `text` mediumblob,
              PRIMARY KEY  (`id`),
              KEY `RecordType` (`RecordType`,`Parent_id`,`Priority`)
            )
        });
        print "\tcreated\n";
    }

    if (! column_exists($dbh, 'Catalog', 'Hits')) {
        DO_SQL($dbh, qq{ alter table Catalog ADD Hits int(11) NOT NULL default '0' });
        print "\tadded column Hits\n";
    }

    # Upgrade from ACL to ExtendedACL
    if (column_exists($dbh, 'Catalog', 'all_r') and
        ! column_exists($dbh, 'Catalog', 'xacl_read')) {

        foreach my $field (qw/xacl_read xacl_write xacl_admin/) {
            if (! column_exists($dbh, 'Catalog', $field)) {
                DO_SQL($dbh, qq{
                    ALTER TABLE Catalog ADD COLUMN `$field` varchar(64) default NULL
                });
                print "\tcreated column $field\n";
            }
        }

        DO_SQL($dbh, "UPDATE Catalog SET xacl_read='everyone' WHERE all_r=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_read='registered' WHERE all_reg=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_read=CONCAT('gid:', gid) WHERE gid_r=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_read='owner' WHERE xacl_read is null");

        DO_SQL($dbh, "UPDATE Catalog SET xacl_write='everyone' WHERE all_w=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_write=CONCAT('gid:', gid) WHERE gid_w=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_write='owner' WHERE xacl_write is null");

        DO_SQL($dbh, "UPDATE Catalog SET xacl_admin='everyone' WHERE all_a=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_admin=CONCAT('gid:', gid) WHERE gid_a=1");
        DO_SQL($dbh, "UPDATE Catalog SET xacl_admin='owner' WHERE xacl_admin is null");

        print "\tupgraded to ExtendedACL\n";
    }

    # Remove old ACL fields
    foreach my $field (qw/gid_r gid_w gid_a all_r all_reg all_a all_w gid/) {
        if ( column_exists($dbh, 'Catalog', $field)) {
            DO_SQL($dbh, qq{
                ALTER TABLE Catalog DROP COLUMN `$field`
            });
            print "\tdropped column $field\n";
        }
    }

#
# @metags Statistics
#
    print "table Statistics\n";
    if (! table_exists($dbh, 'Statistics')) {
        DO_SQL($dbh, qq{
            CREATE TABLE `Statistics` (
             `catalog_id` int(11) NOT NULL default '0',
             `visitor` varchar(64) NOT NULL default '',
             `date` date NOT NULL default '0000-00-00',
             `hits` int(11) NOT NULL default '0',
             `ts` timestamp(14) NOT NULL,
             KEY `catalog_id` (`catalog_id`,`date`,`visitor`)
            )
        });
        print "\tcreated\n";
    }
    if (! column_exists($dbh, 'Statistics', 'ts')) {
        DO_SQL($dbh, qq{ alter table Statistics ADD ts timestamp(14) NOT NULL });
        print "\tadded column ts\n";
    }

# @metags 98.Tables_to_delete
    DO_SQL($dbh, "DROP TABLE IF EXISTS Menu");        # removed in 2.11
    DO_SQL($dbh, "DROP TABLE IF EXISTS MenuLink");    # removed in 2.11
    DO_SQL($dbh, "DROP TABLE IF EXISTS MenuSection"); # removed in 2.11
    #DO_SQL($dbh, "DROP TABLE IF EXISTS SystemACL");   # removed in 3.0
    #DO_SQL($dbh, "DROP TABLE IF EXISTS DBISource");   # removed in 3.0
    #DO_SQL($dbh, "DROP TABLE IF EXISTS sequence");    # removed in 3.0

# ------------------------------------------------------------------------
# @metags 99.Save_upgraded_storage_version
STEP99: {
    $current_storage_version = $ePortal->Config("StorageVersion_ePortal") * 1;
    $current_storage_version = 'undefined' unless $current_storage_version;
    $ePortal->Config("StorageVersion_ePortal", $VERSION);

    print "\nStorage was checked last time by ePortal.pl v.$current_storage_version\n";
    print "Current version of ePortal.pl v.$VERSION. Saved.\n";
}

exit 0;
