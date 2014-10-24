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
#=== @metags Admin_mode ===================================
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
#=== @metags ePortal_config_parameters
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
#=== @metags Default_PageView ===================================
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
#=== @metags Any_PageSection ============================================
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
#=== @metags Any_user ============================================
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
#=== @metags Applications ==================================================
foreach my $appname ($ePortal->ApplicationsInstalled) {
  my $ap;
  try { $ap = $ePortal->Application($appname); 
      } otherwise {};
  if ( ! $ap ) {
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
#=== @metags CronJob_JobStatus ==================================================
#
{
  my $cj = new ePortal::CronJob;
  $cj->restore_all;
  while($cj->restore_next) {

    # Check for disabled
    if ( $cj->JobStatus eq 'disabled') {
      $something_wrong = 1;
      </%perl>
      <li><b><% pick_lang(
          rus => "������������� ������� " . $cj->Title . " ���������",
          eng => "Periodic job " . $cj->Title . " is disabled") %></b>
      <span class="memo">
        <% pick_lang(
            rus => "������ ������� �� ����� �����������",
            eng => "This job will never be executed") %>
      </span>
      <% plink({rus => "���������", eng => "Check it"}, -href => '/admin/CronJob_list.htm') %>
      <%perl>

    # Check for failed
    } elsif ( $cj->LastResult eq 'failed' ) {
      $something_wrong = 1;
      </%perl>
      <li><b><% pick_lang(
          rus => "������������� ������� " . $cj->Title . " ���������� � �������",
          eng => "Periodic job " . $cj->Title . " is failed") %></b>
      <span class="memo">
        <% pick_lang(
            rus => "������� ���� ��������� � �������",
            eng => "This job is failed to execute") %>
      </span>
      <% plink({rus => "���������", eng => "Check it"}, -href => '/admin/CronJob_list.htm') %>
      <%perl>
    }
  }
}


#
#=== @metags The_end ===================================================
#
if ( ! $something_wrong ) {
  </%perl>
  <% pick_lang(rus => "��������� ���...", eng => "No significant remarks...") %>
  <%perl>
}
</%perl></%method>
