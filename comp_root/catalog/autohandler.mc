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
<& /add_popup_menu.mc, "GroupMenu",
  1 || $ePortal->isAdmin()
		? (
      pick_lang(rus => "Изменить", eng => "Edit") => '/catalog/group_edit.htm?objid=#id#',
      html => '<hr>',
      pick_lang(rus => "Создать ссылку в этом разделе", eng => "Create a link in group") => '/catalog/link_edit.htm?objid=0&parent_id=#id#',
      html => '<hr>',
			pick_lang(rus => "Удалить", eng => "Delete") => '/delete.htm?objtype=ePortal::Catalog&objid=#id#',
		  )
		: (),
	&>


<& /add_popup_menu.mc, "LinkMenu",
    1 || $ePortal->isAdmin()
			? (
        pick_lang(rus => "Изменить", eng => "Edit") => '/catalog/link_edit.htm?objid=#id#',
 #       html => '<hr>',
 #       pick_lang(rus => "Добавить ресурс", eng => "Add a resource") => '/catalog/link_edit.htm?objid=0&parent_id=#id#',
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
