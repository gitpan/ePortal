%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 1.3 $
%# $Date: 2003/04/24 05:36:52 $
%# $Header: /home/cvsroot/ePortal/comp_root/pv/admin_section.mc,v 1.3 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>
  # only admin may see it
  return if ! $ePortal->isAdmin;

  # prepare Dialog
  my $dlg = new ePortal::HTML::Dialog( width => "99%", formname => undef,
      title => pick_lang(rus => "������ ��������������", eng => "Administrator's section"),
      title_url => '/admin/index.htm',
  );
  
</%perl>
<% $dlg->dialog_start %>
<% $dlg->row( $m->comp('SELF:dialog_content') ) %>
<% $dlg->dialog_end %>
<p>


%#=== @metags dialog_content ====================================================
<%method dialog_content><%perl>
my $something_wrong;

#
#=== Admin mode ===================================
#
if ($ePortal->admin_mode) {
  $something_wrong=1;
  </%perl>
  <li><b><% pick_lang(rus => "������� ����� ��������������", eng => "Admin mode is on") %></b>
  <span class="memo">
    <% pick_lang(
        rus => "����� ������������ �������� ���������������! ", 
        eng => "Any user is administrator") %>
  </span>
  <%perl>
}

#
#=== ePortal config parameters
#
if ( !$ePortal->www_server or ! $ePortal->smtp_server or ! $ePortal->mail_domain) {
  $something_wrong=1;
  </%perl>
  <li><b><% pick_lang(
      rus => "������ ��������������� �� ���������", 
      eng => "The server is not configured completely") %></b>
  <span class="memo">
    <% pick_lang(
        rus => "��������� ������� ������� �� ����� ��������", 
        eng => "Some functionality is disabled") %>
  </span>
  <% plink({rus => "���������", eng => "Correct it"}, -href => '/admin/ePortal_setup.htm') %>
  <%perl>
}

#
#=== Default PageView ===================================
#
my $pv = new ePortal::PageView;
if ( ! $pv->restore('default') ) {
  $something_wrong=1;
  </%perl>
  <li><b><% pick_lang(
      rus => "�� ������� �������� �������� ��� ����", 
      eng => "Default home page is not exists") %></b>
  <span class="memo">
    <% pick_lang(
        rus => "���������� ����� ���� �� ���� �������� �������� ��� ���� �������������", 
        eng => "At least one home page should exists") %>
  </span>
  <% plink({rus => "���������", eng => "Correct it"}, -href => '/pv/pv_edit.htm?ok_url=/index.htm') %>
  <%perl>
}

#
#=== Any PageSection ============================================
# 
my $ps = new ePortal::PageSection;
$ps->restore_all;
if ( ! $ps->restore_next ) {
  $something_wrong=1;
  </%perl>
  <li><b><% pick_lang(
      rus => "��� �� ������ ������� ��� �������� ��������", 
      eng => "No home page sections registered") %></b>
  <span class="memo">
    <% pick_lang(
        rus => "� ������� ������ ����������� ��� �������� ��������", 
        eng => "With the help of sections the home page is cunstructed") %>
  </span>
  <% plink({rus => "���������", eng => "Correct it"}, -href => '/pv/ps_list.htm') %>
  <%perl>
}

#
#=== Any user ============================================
# 
my $u = new ePortal::epUser;
$u->restore_where(where => "username <> 'admin'");
if ( ! $u->restore_next ) {
  $something_wrong=1;
  </%perl>
  <li><b><% pick_lang(
      rus => "�� ���������������� �� ������ �������� ������������", 
      eng => "No users registered yet") %></b>
  <span class="memo">
    <% pick_lang(
        rus => "����� �� ������ ������������������ �� �������", 
        eng => "Nobody can login to server") %>
  </span>
  <% plink({rus => "���������", eng => "Correct it"}, -href => '/admin/users_list.htm') %>
  <%perl>
}

#
#=== Catalog ============================================
# 
my $c = new ePortal::Catalog;
$c->restore_all;
if ( ! $c->restore_next ) {
  $something_wrong=1;
  </%perl>
  <li><b><% pick_lang(
      rus => "� �������� ��� �� ����� ������", 
      eng => "Catalogue is empty") %></b>
  <span class="memo">
    <% pick_lang(
        rus => "������� �������� ��������� ������ �������� ������ �������", 
        eng => "Catalogues is a collection of your resources") %>
  </span>
  <% plink({rus => "���������", eng => "Correct it"}, -href => '/catalog/index.htm') %>
  <%perl>
}

#
#=== Applicatioons ==================================================
foreach my $appname ($ePortal->ApplicationsInstalled) {
  if ( ! $ePortal->Application($appname) ) {
    $something_wrong=1;
    </%perl>
    <li><b><% pick_lang(
        rus => "���������� $appname �� ���������", 
        eng => "Applications $appname is not configured") %></b>
    <span class="memo">
      <% pick_lang(
          rus => "������ ���������� �� ����� ��������� ���������������", 
          eng => "This application will not work") %>
    </span>
    <% plink({rus => "���������", eng => "Correct it"}, -href => '/admin/index.htm') %>
    <%perl>
  }
}

#
#=== The end ===================================================
#
if ( ! $something_wrong ) {
  </%perl>
  <% pick_lang(rus => "��������� ���...", eng => "No remarks...") %>
  <%perl>
}
</%perl></%method>
