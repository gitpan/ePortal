%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.1 $
%# $Date: 2003/04/24 05:36:51 $
%# $Header: /home/cvsroot/ePortal/comp_root/message.mc,v 3.1 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------
% if ($ErrorMessage or $GoodMessage) {
  <!--UdmComment-->
	<table border=0 width="100%">
		<tr><td>
	<hr size=1 align=center width="80%">
		<center><span class="errormessage"><% $ErrorMessage %></span></center>
% 	if ($ErrorMessage and $GoodMessage) {
	<hr size=1 align=center width="80%">
%		}
		<center><span class="goodmessage"><% $GoodMessage %></span></center>
	<hr size=1 align=center width="80%">
	</td></tr>
	</table>
  <!--/UdmComment-->
% }

%#============================================================================
<%args>
$ErrorMessage => undef
$GoodMessage => undef
</%args>


%#============================================================================
<%init>
	# ��������� � ���������� ������.
	if ($session{ErrorMessage}) {
		$ErrorMessage .= '<br>' if ($ErrorMessage);
		$ErrorMessage .= $session{ErrorMessage};
		delete $session{ErrorMessage};
	}

	if ($session{GoodMessage}) {
		$GoodMessage .= '<br>' if ($GoodMessage);
		$GoodMessage .= $session{GoodMessage};
		delete $session{GoodMessage};
	}

  # ���� ��� ������� ��������� �� ����� ����������, ����� �� ������.
  if ($ErrorMessage eq '' and $GoodMessage eq '') {
    return undef;
  };
</%init>
