%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#----------------------------------------------------------------------------
<%perl>
  my $group = $ARGS{group};
  my $G = new ePortal::Catalog;
  $G->restore($group);

  my $manageable = $ePortal->isAdmin || $G->xacl_check_update || $G->xacl_check_children;
  return if ! $manageable;
</%perl>
<&| /dialog.mc, width => '100%',
      title => pick_lang(rus => "Управление каталогом", eng => "Manage catalogue") &>
<b><% pick_lang(rus => "Добавление в каталог", eng => "Catalogue additions") %></b>
<ul>
  <li><a href="<% href('/catalog/group_edit.htm', parent_id => $group) %>"><% 
      pick_lang(rus => "Добавить раздел", eng => "Add group") %>
  <li><a href="<% href('/catalog/link_edit.htm', parent_id => $group, recordtype => 'link') %>"><% 
      pick_lang(rus => "Добавить ссылку", eng => "Add link") %>
  <li><a href="<% href('/catalog/file_edit.htm', parent_id => $group, recordtype => 'file') %>"><% 
      pick_lang(rus => "Добавить ресурс", eng => "Add resource") %>
</ul>
</&>
<% empty_table(height => 5) %>

