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
%# $Header: /home/cvsroot/ePortal/comp_root/pv/topmenubar.mc,v 3.2 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>
  my $setup_url = '<b>&middot;</b>';
  if ( $ePortal->isAdmin ) {
    $setup_url = img(src => '/images/ePortal/setup.gif', href => '/admin/topmenu.htm',
      title => pick_lang(rus => "Настройка верхней строки меню", eng => "Setup top menu bar") );
  }
</%perl>
<table width="100%" cellpadding=0 cellspacing=0 border=0 bgcolor="#6C7198">
	<tr><td class="topmenu">
    &nbsp;<% $setup_url %>&nbsp;
			<a class="topmenu" target="_top" href="/index.htm"><% pick_lang( rus=>"В начало", eng=>"Home") %></a>
		&nbsp;<b>&middot;</b>&nbsp;

%	foreach my $i (1..3) {
%		my ($tName, $tURL) = ($ePortal->Config("TopMenuItemName$i"), $ePortal->Config("TopMenuItemURL$i"));
%		if ($tName and $tURL) {
			<a class="topmenu" target="_top" href="<% $tURL %>"><% $tName %></a>
			&nbsp;<b>&middot;</b>&nbsp;
% } }

    <a class="topmenu" target="_top" href="/catalog/index.htm"><% pick_lang(rus=>"Каталог", eng => "Catalogue") %></a>
		&nbsp;<b>&middot;</b>&nbsp;
	</td>

	<td align="right" class="topmenu">
		&nbsp;<b>&middot;</b>&nbsp;
%		if ( $ePortal->username ) {
			<a target="_top" href="/logout.htm" class="topmenu"><% pick_lang(rus=>"Разрегистрироваться", eng => "Logout") %></a>
%		} else {
			<a target="_top" href="/login.htm" class="topmenu"><% pick_lang(rus=>"Регистрация", eng => "Login") %></a>
%		}
		&nbsp;<b>&middot;</b>&nbsp;
	</td>
	</tr>
</table>
