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
%# $Header: /home/cvsroot/ePortal/comp_root/catalog/autohandler.mc,v 3.2 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<& /add_popup_menu.mc, "GroupMenu",
  $ePortal->isAdmin()
		? (
      pick_lang(rus => "Изменить", eng => "Edit") => '/catalog/group_edit.htm?objid=#id#',
      html => '<hr>',
      pick_lang(rus => "Создать ссылку в этом разделе", eng => "Create a link in group") => '/catalog/link_edit.htm?objid=0&parent_id=#id#',
#     pick_lang(rus => "Права доступа", eng => "Access control") => 'javascript:open_acl_window("#id#", "ePortal::Catalog");',
      html => '<hr>',
			pick_lang(rus => "Удалить", eng => "Delete") => '/delete.htm?objtype=ePortal::Catalog&objid=#id#',
		  )
		: (),
	&>


<& /add_popup_menu.mc, "LinkMenu",
    $ePortal->isAdmin()
			? (
        pick_lang(rus => "Изменить", eng => "Edit") => '/catalog/link_edit.htm?objid=#id#',
        html => '<hr>',
        pick_lang(rus => "Добавить ресурс", eng => "Add a resource") => '/catalog/link_edit.htm?objid=0&parent_id=#id#',
 #        pick_lang(rus => "Права доступа", eng => "Access control") => 'javascript:open_acl_window("#id#", "ePortal::Catalog");',
        html => '<hr>',
				pick_lang(rus => "Удалить", eng => "Delete") => '/delete.htm?objtype=ePortal::Catalog&objid=#id#',
			  )
			: (),
		&>

<% $m->call_next %>


%#=== @metags onStartRequest ====================================================
<%method onStartRequest><%perl>
	$gdata{Catalog_Admin} = $ePortal->isAdmin;
</%perl></%method>



%#=== @METAGS attr =========================================================
<%attr>
Title => {rus => "Каталог ресурсов", eng => "Resources catalogue"}
</%attr>
