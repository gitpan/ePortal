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
# $Header: /home/cvsroot/ePortal/lib/ePortal/Dual/ImportDialog.pm,v 3.1 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

package ePortal::Dual::ImportDialog;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.1 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Dual/;

	use ePortal::Global;
	use ePortal::HTML::Dialog;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;

    $self->SUPER::initialize(Attributes => {
        filename => {
                    label => {rus => 'Имя файла', eng => 'File name'},
                    order => 3,
                    fieldtype => 'upload',
        },
        emptystorage => {
                    label => {rus => 'Предварительно удалить все данные', eng => 'Delete data before import'},
                    dtype => 'YesNo',
        },
    });
}##initialize


1;

__END__

