%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.1 $
%# $Date: 2003/04/24 05:36:52 $
%# $Header: /home/cvsroot/ePortal/comp_root/manual/autohandler.mc,v 3.1 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------

% if ($r->uri =~ /index.htm$/) {
	<% $m->call_next %>

% } else {
	<p align="right">
	<% plink(pick_lang(rus => "К оглавлению", eng => "Table of contents"), -href => "index.htm") %>
	</p>
	<p>

  <% $m->call_next_filtered() %>

	<p align="right">
	<% plink(pick_lang(rus => "К оглавлению", eng => "Table of contents"), -href => "index.htm") %>
	</p>
% }


%#=== @metags attr =========================================================
<%attr>
Title => {rus => "Руководство по ePortal", eng => "ePortal manual"}
</%attr>
