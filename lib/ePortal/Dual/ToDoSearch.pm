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
# $Header: /home/cvsroot/ePortal/lib/ePortal/Dual/ToDoSearch.pm,v 3.2 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# The main ThePersistent class without ACL checking. All system tables
# without ACL should grow from this class
# ------------------------------------------------------------------------

package ePortal::Dual::ToDoSearch;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.2 $ =~ /: (\d+).(\d+)/;
	use base qw/ePortal::ThePersistent::Dual/;

	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang
	use ePortal::HTML::Dialog;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;

    $self->SUPER::initialize(Attributes => {
        status => {
                    label => {rus => 'Статус', eng => 'Status'},
                    dtype => 'VarChar',
                    fieldtype => 'popup_menu',
                    values => [ '', 'done', 'undone'],
                    labels => {
                            '' =>     {rus => 'Все', eng => 'All'},
                            done =>   {rus => 'закончен', eng => 'done'},
                            undone => {rus => 'в работе', eng => 'active'},
                    },
        },
        text => {
                    label => { rus => 'Любой текст', eng => 'Any text'},
                    dtype => 'Varchar',
                    size => 18,
        },
    });

    $self->{dialog} = new ePortal::HTML::Dialog(
            obj => $self,
            title => pick_lang(rus => "Поиск", eng => 'Search'),
            width=>"95%", method=>"GET");
}##initialize


############################################################################
sub handle_request  {   #05/07/02 4:38
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

	push @out, $d->dialog_start;

	push @out, $d->field("text", vertical => 1, -align => "left");
	push @out, $d->field("status", vertical => 1, -align => "left");
    push @out, $d->field("page", hidden => 1, value => "1");
	push @out, $d->buttons( ok_label => pick_lang(rus => "Искать!", eng => 'Search!'), cancel_button => 0);

	push @out, $d->row("<hr>");
    push @out, $d->row(
		plink( {rus => "Показать все", eng => 'Show all'},
			-href => href($ENV{SCRIPT_NAME}, page => 1,
                    status => undef,
                    text => undef)),
			-align => "center");

	push @out, $d->dialog_end;

    # Clear internal data. Avoid memory leaks
    $self->{dialog} = undef;
    undef $d;

	# Return resulting HTML or output it directly to client
    defined wantarray ? join("\n", @out) : $m->print( join("\n", @out) );
}##draw_dialog

1;

__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
