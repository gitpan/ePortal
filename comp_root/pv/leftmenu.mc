%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.2 $
%# $Date: 2003/04/24 05:36:52 $
%# $Header: /home/cvsroot/ePortal/comp_root/pv/leftmenu.mc,v 3.2 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
%# Do not put any spacing here!!!
<%perl>
	my $MenuItems = shift @_;
	my @VisibleMenu;
	my $valid = 1;

  foreach my $menu  (@$MenuItems) {
		if ($menu->[0] eq 'require-none') {
			$valid = 1;
			next;
    }
		if ($menu->[0] eq 'require-true') {
			$valid = $menu->[1];
			next;
    }
    if ($menu->[0] eq 'require-user') {
			if ($ePortal->username eq '') {
				$valid = 0;
			} else {
				$valid = $ePortal->username =~ /^$menu->[1]/i ? 1: 0;
			}
			next;
    }
    if ($menu->[0] eq 'require-group') {
			if ($ePortal->username eq '') {
				$valid = 0;
			} else {
				$valid = $ePortal->user->group_member( $menu->[1] );
			}
			next;
    }
    next unless $valid;
		push @VisibleMenu, $menu;
	}
	return if scalar(@VisibleMenu) == 0;
</%perl>

<table width="120" border=0 cellspacing=0 cellpadding=0>
%  foreach my $menu  (@VisibleMenu) {
%				if ($menu->[0] =~ /^---/) {
					<% empty_tr( bgcolor => "black", height => 1, black => 1 ) %>
%				} elsif ($menu->[0] eq '') {
					<% empty_tr( height => $menu->[1] || 10 ) %>
%				} elsif ($menu->[0] eq 'img') {
					<tr>
						<td><% img( src => $menu->[1] ) %></td>
					</tr>
%				} elsif ($menu->[0] eq 'html') {
					<tr>
						<td><% $menu->[1] %></td>
					</tr>
%				} else {
		 			<tr><td class="sidemenu" nowrap>
            <% img(src => "/images/ePortal/item.gif") %>
						<a href="<% $menu->[1] %>"><% $menu->[0] %></a>
					</td></tr>
%				}

%     } # end of foreach @$MenuItems

			<% empty_tr( height=> 5 ) %>
		</table>

