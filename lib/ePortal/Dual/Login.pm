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
# $Header: /home/cvsroot/ePortal/lib/ePortal/Dual/Login.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

package ePortal::Dual::Login;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Dual/;

	use ePortal::Global;


############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;

    $self->SUPER::initialize(Attributes => {
        username => {
                    label => {rus => 'Ваше имя', eng => 'Login name'},
                    order => 3,
                    dtype => 'VarChar',
                    size => 10,
                    maxlength => 32,
        },
        password => {
                    label => {rus => 'Пароль', eng => 'Password'},
                    dtype => 'Varchar',
                    size => 10,
                    maxlength => 32,
                    fieldtype => 'password',
        },
        savepassword => {
                    label => {rus => "Запомнить пароль", eng => 'Remember me'},
                    dtype => 'YesNo',
                    default => 1,
        },
    });
}##initialize



1;

__END__

