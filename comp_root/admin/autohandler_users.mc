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
%# $Header: /home/cvsroot/ePortal/comp_root/admin/autohandler_users.mc,v 3.1 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------
%# Common menu for users editor
%# If a $list has an attached DUAL object then it will draw dual's dialog
%# on menu
%#

<% $m->call_next %>

%#=== @METAGS MenuItems ====================================================
<%method MenuItems><%perl>
	return [
		@{$m->comp("PARENT:MenuItems")},
		[pick_lang(rus => "Пользователи", eng => "Users"),  "users_list.htm"],
		[pick_lang(rus => "Группы",eng => "Groups"),        "groups_list.htm"],
		["" => ""],
		[pick_lang(rus => "Новый пользователь",eng => "New user"),   "users_edit.htm?objid=0"],
		[pick_lang(rus => "Новая группа",eng => "New group"),        "groups_edit.htm?objid=0"],
		["" => ""],
		];

</%perl></%method>

