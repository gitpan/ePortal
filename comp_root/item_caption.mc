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
%# $Header: /home/cvsroot/ePortal/comp_root/item_caption.mc,v 3.1 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------
<div align="<% $align %>">
<table border="0" cellspacing="0" cellpadding="0" bgcolor="#FFFFFF">
<tr>
  <% empty_td(width=>5) %>
<td bgcolor="#e6e4e9" valign="top" width="5" align="right">
  <% img(src => "/images/ePortal/cur_lt.gif", align=>'top', hspace => 0, alt => '') %>
</td>
<td bgcolor="#e6e4e9" valign="top" nowrap align="left">
    <span style="font-size:9pt;font-weight:bold; color:#800000;text-decoration:none;">
    ::&nbsp;<% $title %>&nbsp;
    </span>
</td>
<td bgcolor="#e6e4e9" valign="top" width="5" align="left">
  <% img(src => "/images/ePortal/cur_rt.gif", align=>'top', hspace => 0, alt => '') %>
</td>
<% empty_td(width=>5) %>
<td class="memo">&nbsp;<% $extra %></td>
</tr>
</table>

% if ($underline) {
<table width="<% $width %>" border="0" cellspacing="0" cellpadding="0">
<tr>
  <% empty_td(width=>5) %>
  <td height="2"  bgcolor="#e6e4e9"><% img(src => "/images/ePortal/cur_2x2.gif", alt => '') %></td>
</tr>
</table>
% }
</div>
%#=== @METAGS args =========================================================
<%args>
$title
$width => '99%'
$underline => 1
$align => 'left'
$extra => undef
</%args>
