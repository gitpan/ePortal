%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------

% if ($r->uri =~ /index.htm$/) {
	<% $m->call_next %>

% } else {
	<p align="right">
	<% plink(pick_lang(rus => "� ����������", eng => "Table of contents"), -href => "index.htm") %>
	</p>
	<p>

  <% $m->call_next_filtered() %>

	<p align="right">
	<% plink(pick_lang(rus => "� ����������", eng => "Table of contents"), -href => "index.htm") %>
	</p>
% }


%#=== @metags attr =========================================================
<%attr>
Title => {rus => "����������� �� ePortal", eng => "ePortal manual"}
</%attr>
