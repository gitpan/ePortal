#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.3 $
# $Date: 2003/04/24 05:36:51 $
# $Header: /home/cvsroot/ePortal/bin/cron.daily/ePortal_expire_sessions.pl,v 3.3 2003/04/24 05:36:51 ras Exp $
#
#----------------------------------------------------------------------------
#
# Expire old information from sessions database of core ePortal
#
# ------------------------------------------------------------------------

our $VERSION = sprintf '%d.%03d', q$Revision: 3.3 $ =~ /: (\d+).(\d+)/;
use ePortal::CommandLine;
use ePortal::ThePersistent::Tools;
use ePortal::Global;
use ePortal::Utils;
use ePortal::Catalog;

my $cmd = new ePortal::CommandLine(
        filename => 'ePortal_expire_sessions.pl',
        description => "Expire old information from database",
    );
$ePortal->initialize();
my $ep_dbh = $ePortal->DBConnect();
my($LAST_RUN, $THIS_RUN) = $cmd->LastThisRun();

# ------------------------------------------------------------------------
# Expire old sessions
#

if ($ePortal->days_keep_sessions == 0) {
    $cmd->print("Session expiration is disabled.");

} else {
    my $result = 0 + $ep_dbh->do("DELETE
            FROM sessions
            WHERE ts < date_sub(now(), interval ? day)",
            undef, $ePortal->days_keep_sessions);
    $cmd->print("Old user's sessions exiped: $result");
}



# ------------------------------------------------------------------------
# Compress Statistics data
COMPRESS_STATISTICS: {
    # calculate first of month $MAX_MONTH_SHOW ago
    my $first_of_month = $ep_dbh->selectrow_array(
            "SELECT date_format(
            date_sub(curdate(), interval $ePortal::Catalog::MAX_MONTH_SHOW month),
            '%Y.%m.01')");
    if ($first_of_month !~ /\d\d\d\d\.\d\d\.\d\d/) {
        $cmd->print("Compress statistics: expect date but got $first_of_month. $DBI::errstr");
        last COMPRESS_STATISTICS;
    }

    # remove statistics that is older than $first_of_month
    my $records_removed = $ep_dbh->do("DELETE from Statistics WHERE date < ?", undef, $first_of_month);
    if (!$records_removed) {
        $cmd->print("DBI error: $DBI::errstr");
        last COMPRESS_STATISTICS;
    }
    $records_removed += 0;

    # GROUP BY all statistics that is older then MAX_DATES_SHOW days
    # and add it to the first day of month
    my $st = new ePortal::ThePersistent::Support(
        SQL => "SELECT catalog_id, visitor, date, hits,
                    date_format(date, '%Y.%m.01') as first_of_month
                FROM Statistics",
        Where => "dayofmonth(date) != 1 AND date < date_sub(current_date(), interval ? day)",
        Bind => [$ePortal::Catalog::MAX_DATES_SHOW],
        Attributes => { date => {dtype => 'Varchar'} }, # This will return Date in MySQL ready format
        );

    my $records_coalesced = 0;
    $st->restore_all();
    while($st->restore_next) {
        $records_coalesced ++;

        # Is there a records for 1st of month?
        my $check_first = $ep_dbh->selectrow_array("SELECT ts FROM Statistics
                WHERE catalog_id=? AND visitor=? AND date=?", undef,
                $st->catalog_id, $st->visitor, $st->first_of_month);

        if ($check_first ne '') {   # record exists, use UPDATE
            $ep_dbh->do("UPDATE Statistics SET hits = hits + ?
                    WHERE catalog_id=? AND visitor=? AND date=?", undef,
                    $st->hits, $st->catalog_id, $st->visitor, $st->first_of_month);
        } else {    # no such record, use INSERT
            $ep_dbh->do("INSERT INTO Statistics (catalog_id, visitor, date, hits)
                    VALUES(?,?,?,?)", undef,
                    $st->catalog_id, $st->visitor, $st->first_of_month, $st->hits);
        }

        #remove old record
        $ep_dbh->do("DELETE FROM Statistics
                WHERE catalog_id=? AND visitor=? AND date=?", undef,
                $st->catalog_id, $st->visitor, $st->date);
    }

    $cmd->print("Statistics cleaned: $records_removed removed, $records_coalesced coalesced");
}##//COMPRESS_STATISTICS

$ep_dbh->disconnect;
exit 0;

