#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.2 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Dual/SimpleSearch.pm,v 3.2 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

package ePortal::Dual::SimpleSearch;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.2 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Session/;

	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang
	use ePortal::HTML::Dialog;

	my $attributes = {
        # ID added internally by ePortal::ThePersistent::Session
		text => {
					label => {rus => 'Текст для поиска', eng => 'Text to search'},
					dtype => 'Varchar',
					size => 18, },
	};

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
    $self->SUPER::initialize(Attributes => $attributes);

	$self->{dialog} = new ePortal::HTML::Dialog(
		title => pick_lang(rus => "Поиск", eng => 'Search'),
		obj => $self,
        width=>"95%",
		method=>"GET");

}##initialize



############################################################################
sub handle_request	{	#05/07/02 4:38
############################################################################
	my $self = shift;
	$self->{dialog}->handle_request(obj => $self);
}##handle_request



############################################################################
sub draw_dialog	{	#11/22/01 12:23
############################################################################
	my $self = shift;

	my @out;
	my $m = $HTML::Mason::Commands::m;
	my $d = $self->{dialog};

	push @out, $d->dialog_start();

	push @out, $d->field("text", vertical => 1, -align => "right");
    push @out, $d->field("page", hidden => 1, value => "1");
	push @out, $d->buttons( ok_label => pick_lang(rus => "Искать!", eng => "Search!"), cancel_button => 0);

    push @out, $d->row("<hr>" .
		plink( {rus => "Показать все", eng => 'Show all'},
            -href => href($ENV{SCRIPT_NAME}, text => undef, page => 1, dlgb_ok => 1)),
			-align => "center");

	push @out, $d->dialog_end;

    # Clear internal data. Avoid memory leaks
    $self->{dialog} = undef;
    undef $d;

	# Return resulting HTML or output it directly to client
    defined wantarray ? join("\n", @out) : $m->print( join("\n", @out) );
}##draw_dialog

1;

