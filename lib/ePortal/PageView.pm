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

=head1 NAME

ePortal::PageView - Custom home page of ePortal.

=head1 SYNOPSIS

There are 3 types of PageView:

=over 4

=item *

B<user> - personal home page of a registered user

=item *

B<default> - only one PageView may be default. This is default home page of
a site

=item *

B<template> - There may be many templates. They are used when user create
new personal home page.

=back

=head1 METHODS

=cut

package ePortal::PageView;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ExtendedACL/;

	use ePortal::Global;
	use ePortal::Utils;
	use ePortal::UserSection;
	use ePortal::PageSection;


############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{columnswidth} ||= {
            label => {rus => 'Ширина столбцов', eng => 'Columns width'},
            fieldtype => 'popup_menu',
            values => ['N:W', 'N:W:N'],
            labels => {
                    'N:W' => {rus => 'Узк:Шир', eng => 'Nar:Wid'},
                    'N:W:N' => {rus => 'Узк:Шир:Узк', eng => 'Nar:Wid:Nar'}},
            # N:W:N   Narrow:Wide
        };
    $p{Attributes}{title} ||= {
        label => { rus => 'Название', eng => 'Name'},
        default => pick_lang(rus => "Личная", eng => "Private"),
        };
    $p{Attributes}{pvtype} ||= {
        label => {rus => 'Тип страницы', eng => 'Type of page'},
        fieldtype => 'popup_menu',
        values => [ qw/ user default template /],
        labels => {
                user => {rus => 'Личная', eng => 'Personal'},
                default => {rus => 'По умолч.', eng => 'Default'},
                template => {rus => 'Шаблон', eng => 'Template'}},
        };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub insert	{	#02/05/01 11:36
############################################################################
	my $self = shift;
	my (@p) = @_;

	if ($self->columnswidth eq '') {
		$self->columnswidth('N:W');
	}
	if ($self->pvtype eq '') {
		$self->pvtype("user");
	}

	$self->SUPER::insert(@p);
}##insert


############################################################################
sub set_acl_default {   #10/04/01 4:25
############################################################################
	my $self = shift;

    $self->SUPER::set_acl_default;
    if ($self->pvtype eq 'default') {
        $self->xacl_read('everyone');
    } elsif ($self->pvtype eq 'user') {
        $self->xacl_read('owner');
    }
}##set_acl_default



=head2 restore(id)

Restore a PageView.

B<id> is 'default' - find unique default PageView

B<id> is Number - restore a PageView with this ID

Else use some magic to find desired PageView. This is the rules:

- Anonymous user always sees default PageView.

- If user is registered and has 'DefaultPageView' then restore it. If it
fails then restore default PageView. Once a day restore default PageView
for the user to see some global news ;-)

- Else or if something fails then restore default PageView.

This function returns 1 on success or 0 on error.

=cut

############################################################################
sub restore	{	#10/20/00 12:24
############################################################################
	my $self = shift;
	my $id = shift;

	if (! defined $id) {	# restore something default

		if ($ePortal->username eq '') {
			return $self->restore('default');

		} else {

			# Try to restore preferred PV
			my $selectedPV = $ePortal->UserConfig("DefaultPageView");
			if ($self->SUPER::restore($selectedPV)) {
				return 1;
			} else {
				return $self->restore('default');
			}
		}

	} elsif ($id eq 'default') {
		$self->restore_where(where => "pvtype=?", bind => ['default']);
  		return $self->restore_next();

	} elsif ($id =~ /^\d+$/o) {
		return $self->SUPER::restore($id);
	}
}##restore



=head2 restore_all_templates()

Does restore_where(pvtype = template).

=cut

############################################################################
sub restore_all_templates	{	#01/22/01 2:31
############################################################################
	my $self = shift;
	$self->restore_where(where => "pvtype=?", order_by => 'title', bind => ['template']);
}##restore_all_templates



=head2 restore_all_for_user(username)

Does restore_where(...) for all PageView available to user (both default
and user type)

B<username> is default to current user name

=cut

############################################################################
sub restore_all_for_user	{	#01/22/01 2:32
############################################################################
	my $self = shift;
	my $username = shift || $ePortal->username;

	$self->restore_where(
		where => "pvtype='default' or (pvtype='user' and uid=?)",
		order_by => 'pvtype, title',
		bind => [$username]);
}##restore_all_for_user


=head2 ColumnsCount()

Return a number of columns in the current PageView.

=cut

############################################################################
sub ColumnsCount	{	#12/13/00 4:25
############################################################################
	my $self = shift;

	my @C = split ':', $self->ColumnsWidth;
	return scalar @C;
}##ColumnsCount


=head2 ColumnsWidthPercent()

Returns array of numbers with width in percent of PageView's columns.
Narrow column counts as 1, wide column - as 2. For two-column PageView
(N:W) result would be (33,66).

I<Note>: The percent sign is not included after numbers.

=cut

############################################################################
sub ColumnsWidthPercent	{	#12/13/00 4:22
############################################################################
	my $self = shift;

	my @Columns = split ":", $self->ColumnsWidth;

	# Count total width of the view. Narrow column counts as 1, wide - 2
	my $total;
	foreach (@Columns) {
		$total += 1 if /N/;
		$total += 2 if /W/;
	}

	# Recalc widths in percent
	my @ColumnsWidth;
	foreach (@Columns) {
		use integer;
		push @ColumnsWidth, 100/$total if /N/;
		push @ColumnsWidth, 100/$total*2 if /W/;
	}

	return @ColumnsWidth;
}##ColumnsWidthPercent



=head2 AvailableSections(column_number)

Returns array (\@values, \%labels) with available sections for addition to
the column. References returned are ready to pass to CGI::popup_menu(...)

B<column_number> is number of desired column in PageView.

=cut

############################################################################
sub AvailableSections	{	#12/13/00 4:35
############################################################################
	my $self = shift;
	my $column = shift;

	my $W = (split ':', $self->ColumnsWidth)[$column-1];

	my $s = new ePortal::PageSection;
	my ($values, $labels) = $s->restore_all_hash("id","title", "width=?", "title", $W);

	return ($values, $labels);
}##AvailableSections


=head2 get_UserSection($column)

Does restore_where(for the column) on ePortal::UserSection object.

If $column is undef then all UserSection (for all columns) are selected.
This is the same as call to children().

Returns ePortal::UserSection object ready to restore_next().

=cut

############################################################################
sub get_UserSection	{	#12/14/00 2:03
############################################################################
	my $self = shift;
	my $column = shift;

	my $S = new ePortal::UserSection;
	if ($column) {
		$S->restore_where(where => 'colnum=? and pv_id=?', order_by => 'id', bind => [$column, $self->id]);
	} else {
		$S->restore_where(where => ' pv_id=?', order_by => 'id', bind => [$self->id]);
	}
	return $S;
}##get_UserSection


############################################################################
sub children	{	#10/25/00 2:55
############################################################################
	my $self = shift;
	return $self->get_UserSection;
}##children


############################################################################
sub xacl_check_insert   {   #05/17/01 2:40
############################################################################
	my $self = shift;

	# only registered users
	return 0 if $ePortal->username eq '';

	return 1;
}##acl_check_insert


=head2 CopyFrom($template_id)

Copy PageView object from denoted by $template_id to current one. The
pvtype attribute is changed to 'user'. Also copies all daughter UserSection
objects.

Returns: 1 on success.

=cut

############################################################################
sub CopyFrom	{	#02/05/01 2:48
############################################################################
	my $self = shift;
	my $template_id = shift;

	$self->clear;
	my $PVt = new ePortal::PageView;
    $PVt->restore_or_throw($template_id);

	if ($PVt->pvtype ne 'template') {
		logline('error', 'New PageView based on nontemplate PageView. user:'.$ePortal->username);
	}

	# Copy ALL data from original
	$self->data ($PVt->data);

	# Redefine some unique for new object attributes
	$self->id(undef);
    $self->uid( $ePortal->username );
	$self->pvtype( 'user' );
	return undef if not $self->insert;

	# Copy all child UserSections
	my $S = new ePortal::UserSection;
	for (1..3) {
		my $St = $PVt->get_UserSection($_);
		while( $St->restore_next) {
			$S->data( $St->data );
			$S->id(undef);
			$S->pv_id( $self->id );
			$S->insert;
		}
	}
	1;
}##CopyFrom


=head2 SetDefaultPageView($new_id)

This function is mean only for registered users. B<new_id> is stored in
user's configuration and used when next call to PageView->restore().

=cut

############################################################################
sub SetDefaultPageView	{	#02/12/01 12:18
############################################################################
	my $self = shift;
	my $new_id = shift;

	return if not $ePortal->username;

	my $pv = new ePortal::PageView;
	if ($pv->restore($new_id)) {
		$ePortal->UserConfig("DefaultPageView", $new_id);
		1;
	} else {
        throw ePortal::Exception(-text => pick_lang(
			rus => "Указанная домашняя страница не существует или не доступна",
            eng => "Home page not found"));
	}
}##SetDefaultPageView


############################################################################
# Function: value
# Description: Ala trigger. Adjust some attributes when any value changes
############################################################################
sub value	{	#10/04/01 4:34
############################################################################
	my $self = shift;
	my $attr = lc shift;

	if (@_) {	# Assing new value
		my $newvalue = shift;
		if ($attr eq 'pvtype') {
			if ($newvalue eq 'user') {
                $self->xacl_read('owner');
                $self->uid($ePortal->username);

			} elsif ($newvalue eq 'default') {
                $self->xacl_read('everyone');

			} elsif ($newvalue eq 'template') {
                $self->xacl_read('everyone');
			}
		}
		return $self->SUPER::value($attr, $newvalue);
	} else {
		return $self->SUPER::value($attr);
	}
}##value


=head2 handle_request()

Get and process URL parameters to add, remove, modify a section. Parameters
are:

B<ps> - PageSection ID

B<us> - UserSection ID

B<colnum> - column number

B<addsection> - if true then add new section I<ps> to column I<colnum>

B<removesection> - if true then remove section I<us>

B<min> - if true then minimize section I<us>

B<restore> - if true then restore section I<us> to normal size


=cut

############################################################################
sub handle_request	{	#10/11/01 9:50
############################################################################
	my $self = shift;
	my $m = $HTML::Mason::Commands::m;
    my %args = $m->request_args;

	# Adjust some arguments because dialog.mc send it with different names
	$args{us} = $args{objid} if exists $args{objid};
	$args{removesection} = 1 if exists $args{dlgb_x};
	$args{colnum} = 1 if not $args{colnum};

	# Only admin or PageView owner may modify it
    return unless $self->xacl_check_update;

	# Create support objects
	my $us = new ePortal::UserSection;
	if ($args{us} > 0) {
		$us->restore( $args{us} );
	}

	my $ps = new ePortal::PageSection;
	if ($args{ps} > 0) {
		$ps->restore( $args{ps} );
	}


	# Parse arguments
    if ($args{dlgb_min} and $us->check_id) {
		$us->minimized(1);
		$us->update;
		return "/index.htm";

    } elsif ($args{dlgb_max} and $us->check_id) {
		$us->minimized(0);
		$us->update;
		return "/index.htm";

    } elsif ($args{addsection} and $ps->check_id) {
		my $S = new ePortal::UserSection;
		$S->pv_id( $self->id );
		$S->colnum( $args{colnum});
		$S->ps_id( $ps->id );
		$S->insert;
		return "/index.htm";

    } elsif ($args{removesection} and $us->check_id) {
		$us->delete;
		return "/index.htm";

	} elsif ($args{deletepv}) {
		$self->delete;
		return "/index.htm";

	} elsif ($args{saveastemplate}) {
		$self->pvtype('template');
		$self->update;
		return "/index.htm";

	} elsif ($args{saveasdefault}) {
		# remove old template
		my $PD = new ePortal::PageView;
		$PD->restore('default');
		$PD->pvtype('user');
		$PD->update;

		$self->pvtype('default');
		$self->update;
		return "/index.htm";
	}

}##handle_request

############################################################################
# Function: delete
############################################################################
sub delete	{	#10/15/01 11:32
############################################################################
	my $self = shift;

    my $dbh = $self->dbh();
	$dbh->do("DELETE FROM UserSection WHERE pv_id=?", undef, $self->id);

	$self->SUPER::delete();
}##delete


############################################################################
# Некоторые функции для задания константных значений
# Description: Цвет заголовка секции и ее рамки
############################################################################
sub CaptionColor		{	return '#CCCCFF'; }
sub MaxPersonalPages 	{	return 5	}

############################################################################
sub xacl_check_update   {   #04/16/03 4:12
############################################################################
    my $self = shift;
    return 1 if $ePortal->isAdmin;
    return 1 if $self->pvtype eq 'user' and $self->uid eq $ePortal->username;
    return 0;
}##xacl_check_update


1;

__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

