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
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Global.pm,v 3.3 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

package ePortal::Global;

	our $VERSION = sprintf '%d.%03d', q$Revision: 3.3 $ =~ /: (\d+).(\d+)/;
    our @EXPORT = qw/$ePortal $dbh %session %gdata /;

	# --------------------------------------------------------------------
	# Symbols to export
	#
	require Exporter;
	our @ISA = qw/Exporter/;

   	# --------------------------------------------------------------------
	# Global variables
	#
    our $ePortal;
	our $dbh;
	our %session;
	our %gdata;


1;


package ePortal::FieldDomain;
	our %enabled = (
		enabled => {
				label => {rus => 'Вкл/выкл', eng => 'Enabled'},
				dtype => 'YesNo',
                default => 1,
		},
    );

	our %ts = (
		ts => {
				label => {
                        rus => 'Последнее изменение',
						eng => 'Time stamp'},
				dtype => 'DateTime',
				order => 6,
		}
	);

	our %title = (
		title => {
					label => {rus => 'Наименование', eng => 'Name'},
					size  => 40,
					order => 3,
					maxlength => 255,
					dtype => 'VarChar',
		},
	);

	our %author = (
		author => {
					label => {rus => 'Автор документа', eng => 'Author'},
					size  => 64,
					order => 3,
					maxlength => 255,
					dtype => 'VarChar',
		},
	);

	our %nickname = (
		nickname => {
					label => {rus => 'Короткое имя', eng => 'Nickname'},
                    size  => 20,
					order => 4,
					dtype => 'VarChar',
		},
	);

    our %priority = (
        priority => {
                    label => {rus => 'Приоритет', eng => 'Priority'},
                    dtype => 'Number',
                    maxlength => 4,
                    fieldtype => 'popup_menu',
                    values => [ 1 .. 9 ],
                    labels => {
                        1 => { rus => '1-Высокий', eng => '1-High'},
                        2 => '2',
                        3 => '3',
                        4 => '4',
                        5 => {rus => '5-Средний', eng => '5-Medium'},
                        6 => '6',
                        7 => '7',
                        8 => '8',
                        9 => {rus => '9-Низкий', eng => '9-Low'},
                    },
                    default => 5,
        }
    );


1;
__END__


=head1 NAME

ePortal::Global.pm - Global variables for entire ePortal.



=head1 SYNOPSIS

This package exports some global variables. Use this package everywhere
when you need these variables.



=head2 $ePortal

Global object blessed to ePortal::Server. This is main engine.




=head2 %ePortal_servers

Cache of created servers. User in Apache environment for hosting more than
one virtual server.




=head2 $dbh

Global database handle

=head2 %session

This is tied hash to Apache::Session


=head2 %gdata

This is temporary hash object. It exists only during apache request
processing.




=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
