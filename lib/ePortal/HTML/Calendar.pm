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

ePortal::HTML::Calendar - Calendar dialog box.

=head1 SYNOPSIS

This module is used to make a dialog with a monthly calendar.

 % $Calendar = new ePortal::HTML::Calendar;
 % $Calendar->url_all('self');
 ...
 <% $Calendar->draw %>

=head1 METHODS

=cut

package ePortal::HTML::Calendar;
    our $VERSION = '4.2';

	use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang, CGI
	use Carp;
	use Date::Calc();
	use ePortal::HTML::Dialog;


=head2 new(date)

Object contructor. B<date> is passed to C<set_date>. Calendar's date may be
got from session hash or URL. The date source may be checked with
C<date_source()> member function.

A value of B<self> means that date was initialized by Calendar.pm itself,
B<session> means that date was restored from user's session hash, B<url> -
from browsers's request.

=cut

############################################################################
sub new	{	#09/07/01 2:04
############################################################################
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my @p = @_;

	my $self = {
		date => [0,0,0],
		url => [],
		date_source => 'self',
		};
	bless $self, $class;

	$self->set_date( @p || 'now');

	# restore my date from session store
#   $self->{session_hash} = 'calendar_' . $ePortal->r->uri;
#   if (ref($session{ $self->{session_hash} }) eq 'ARRAY') {
#       $self->set_date( $session{ $self->{session_hash} } );
#       $self->{date_source} = 'session';
#   }

	# Adjust my date from URL
    my %args = $ePortal->m->request_args;           # this is %ARGS
	if ($args{cal_date}) {
		$self->set_date( $args{cal_date} );
		$self->{date_source} = 'url';

	} elsif ($args{cal_pmon}) {
		$self->set_date('cal_pmon');
		$self->{date_source} = 'url';

	} elsif ($args{cal_nmon}) {
		$self->set_date('cal_nmon');
		$self->{date_source} = 'url';

  	} elsif ($args{cal_day}) {
    	$self->{date}->[2] = $args{cal_day};
		$self->{date_source} = 'url';
  	}

	# validate
	my $date_valid = eval { Date::Calc::check_date( @{$self->{date}}) };
	if (! $date_valid or $@) {
		$self->set_date('now');
	}

    $C = $self unless defined $C;
	return $self;
}##new



=head2 self_url(cal_param, value)

Constructs self referencing URL removing all myself specific parameters.
New parameters should be passed to this function to make them added to URL.

Returns URL with parameters.

=cut

############################################################################
sub self_url	{	#02/14/02 4:52
############################################################################
    my ($self, %opt_args) = (@_);

    my %args = $ePortal->m->request_args;
	delete $args{$_} foreach (qw/cal_pmon cal_nmon cal_day cal_date/);

	return href($ePortal->r->uri, %args, %opt_args);
}##self_url




=head2 url($day_number,$url)

Sets an URL for particular day in the current month view. If $url eq
B<'self'> than self-refence URL will be contructed without parameters loss.

=cut

############################################################################
sub url	{	#01/31/02 1:35
############################################################################
    my ($self, $day, $url) = (@_);

	return if $day <=0 or $day > 31;

    my $adate = sprintf "%02d.%02d.%04d", $day, $self->{date}->[1], $self->{date}->[0];
	if ($url eq 'self') {
        #$url = $self->self_url(cal_day => $day);
        $url = $self->self_url(cal_date => $adate);
	}
	$url =~ s/\%date\%/$adate/;

	$self->{url}->[$day] = $url;
}##url


=head2 url_all($url)

Sets an url for each day in calendar. $url parameter is passed to C<url()>
method. See it for details

=cut

############################################################################
sub url_all	{	#01/31/02 1:37
############################################################################
    my ($self, $url) = (@_);

	for (1..31) {
		$self->url( $_, $url );
	}
}##url_all



=head2 date_source()

Returns a sting which points to a source of the date

B<self> - self initialized date (today)

B<session> - restored from user's session hash

B<url> - adjusted from URL

=cut

############################################################################
sub date_source	{	#02/01/02 9:42
############################################################################
    my ($self, @p) = (@_);
	return $self->{date_source};
}##date_source


=head2 draw()

Draws the calendar. Returns an HTML in array context and outputs HTML via
$m in scalar context.

=cut

############################################################################
sub draw	{	#12/17/01 3:15
############################################################################
    my ($self, @p) = (@_);

	my @out;
	my @date = @{ $self->{date} };
  	my $days = Date::Calc::Days_in_Month(@date[0,1]);
    #my %args = $m->request_args;
	#delete $args{$_} foreach (qw/cal_pmon cal_nmon cal_day cal_date/);

	# Counter, which counts days of month
  	my $counter = 2 - Date::Calc::Day_of_Week(@date[0,1],1);
	$counter = 1 if ($counter <= -6);

    my @month_array = @{ pick_lang(
                rus => [ qw/none январь февраль март апрель
                    май июнь июль август
					сентябрь октябрь ноябрь декабрь/],
				eng => [ qw/none january february march april may
					june july august september oktober november december/] ) };

	# outer table
	push @out, '<table border=1 cellspacing=1 CELLPADDING=0 bgcolor=green bordercolor="green">';
	push @out, '<tr><td>';

	# inner table
	push @out, '<table width=150 border=1 cellspacing=0 cellpadding=0 bgcolor=white>';

	# month name and month navigator
    my $next_month_date = join('.', reverse(Date::Calc::Add_Delta_YMD( @{$self->{date}}, 0,1,0)));
    my $prev_month_date = join('.', reverse(Date::Calc::Add_Delta_YMD( @{$self->{date}}, 0,-1,0)));

    push @out, CGI::Tr({},
        CGI::td({-align => "center", -class => "calendar"},
            CGI::a({-href => $self->self_url(cal_date => $prev_month_date)}, '&lt;&lt;&lt;' )),
        CGI::td({-align => "center", -class => "calendar", -colspan => 5, -nowrap => 1},
			CGI::b( $month_array[$date[1]] . ' ' . $date[0] )),
        CGI::td({-align => "center", -class => "calendar"},
            CGI::a({-href => $self->self_url(cal_date => $next_month_date)}, '&gt;&gt;&gt;' ))
	);

	# day of week name
	push @out, CGI::Tr( {-bgcolor => "#9CFF9C"},
        map
			{ CGI::td({-align => "center", -width => 20, -class => "calendar"}, CGI::b($_))}
			( @{
				pick_lang( rus => [qw/П В С Ч П С В/], eng => [qw/M T W T F S S/])
			})
	);

	# day of month rows

	for my $row(1..6) {
		last if ($counter > $days);
		my $row_content;

		for my $col (1..7) {
			my $cell_content;
			my $bgcolor;
			if ($counter == $date[2]) { $bgcolor = '#aaFFaa' }
			elsif ($col >= 6) { $bgcolor = '#FFeeFF' }
			elsif ($self->{url}->[$counter]) { $bgcolor = '#FFFFFF' }
			else { $bgcolor = '#eeeeee' }

			if (($counter <=0) or ($counter > $days)) {
				$cell_content = '&nbsp;';
			} elsif ($self->{url}->[$counter]) {
				$cell_content = CGI::a({ -href => $self->{url}->[$counter]}, CGI::b($counter));
			} else {
				$cell_content = $counter;
			}
			$row_content .= CGI::td({-bgcolor => $bgcolor}, $cell_content);
			$counter++;
		}   # for columns
		push @out, CGI::Tr({ -align => "center"}, $row_content);
	}     # for rows

	# calendar footer
	push @out, CGI::Tr({}, CGI::td({ -colspan => 7, -class => "calendar", -align=>"center"},
		CGI::b(pick_lang( rus => 'Сегодня:', eng => 'Today:')),
		CGI::a({-href => $self->self_url(cal_day => 'now')}, sprintf "%02d.%02d.%04d", reverse Date::Calc::Today())
		));
	push @out, '</table></td></tr></table>';

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##draw


=head2 date()

Returns a date selected. It returns an array (YYYY,MM,DD) in array context
and nicely formatted date 'DD.MM.YYYY' in scalar context.

=cut

############################################################################
sub date	{	#01/30/02 4:24
############################################################################
    my ($self, @p) = (@_);

	return wantarray
		? @{$self->{date}}
		: sprintf("%02d.%02d.%04d", reverse @{$self->{date}});
}##date


=head2 set_date(date)

Adjust the calendar to the date. Parameter may be:

B<'now'> or B<'today'> - set the date to today

B<'cal_nmon'>,B<'next'> or B<'cal_pmon'>,B<'prev'> - adjust to next or prev month

B<[YYYY,MM,DD]> - array ref to (YYYY,MM,DD)

B<(YYYY,MM,DD)> - array of (YYYY,MM,DD)

B<'DD.MM.YYYY'> - date as string

=cut

############################################################################
sub set_date	{	#01/30/02 4:27
############################################################################
    my ($self, @p) = (@_);

	if ($p[0] eq 'now' or $p[0] eq 'today') {
		$self->{date} = [Date::Calc::Today()];

	} elsif (ref($p[0]) eq 'ARRAY') {
		my @dummy = @{$p[0]};	# recreate an array
		$self->{date} = [@dummy];

	} elsif (scalar(@p) > 1) {
		$self->{date} = [@p];

	} elsif ($p[0] eq 'cal_nmon' or $p[0] eq 'next') {
		$self->{date} = [ Date::Calc::Add_Delta_YMD( @{$self->{date}}, 0,1,0)];

	} elsif ($p[0] eq 'cal_pmon' or $p[0] eq 'prev') {
		$self->{date} = [ Date::Calc::Add_Delta_YMD( @{$self->{date}}, 0,-1,0)];

	} elsif ($p[0] =~ /(\d+)\.(\d+)\.(\d+)/) {
		$self->{date} = [$3, $2, $1];
	}

	# store the date in session
#   $session{ $self->{session_hash} } = $self->{date};

	$self->date;
}##set_date

1;


__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

