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
% my $Layout = $m->request_comp->attr('Layout');
% if ($Layout eq 'Normal') {
  <& navigator.mc &>
% }
<& /message.mc &>
<% $m->call_next %>


%#----------------------------------------------------------------------------
<%attr>
Title => {rus => "Раздел администратора", eng => "Administrators page"}
require_admin => 1
</%attr>


%#=== @METAGS dialog_dbi_fields ====================================================
<%method dialog_dbi_fields>
<& /dialog.mc:field, name => 'dbi_source_type' &>

<&| /dialog.mc:cell, -align => 'center' &>
  <br>
  <% pick_lang(rus => "Специальный источник данных", eng => "Custom database connect") %>
</&>

<& /dialog.mc:field, name => 'dbi_source' &>
<& /dialog.mc:field, name => 'dbi_username' &>
<& /dialog.mc:field, name => 'dbi_password' &>

<&| /dialog.mc:cell, -align => 'center' &>
 <hr>
</&>
</%method>



%#=== @metags setup_onStartRequest ====================================================
<%method setup_onStartRequest><%perl>
  my $obj = $ARGS{obj};

  # Handle Dialog events
  my $result = try {
    $m->comp('/dialog.mc:handle_request', objid => 1, obj=> $obj);

  } catch ePortal::Exception::DataNotValid with {
    my $E = shift;
    $session{ErrorMessage} = $E->text;

  } catch ePortal::Exception::DBI with {
    my $E = shift;
    $session{ErrorMessage} = pick_lang(rus => "Не могу подключиться к БД", eng => "Cannot connect to database") . "\n<!-- DB error\n" . $E->text . "-->\n";
  };

  return $result;
</%perl></%method>



%#=== @METAGS custom_dbi_memo ====================================================
<%method custom_dbi_memo>
<% img(src => '/images/icons/warning.gif') %>
<&| SELF:rus &>
<span class="memo">
  Если вы решили переместить таблицы приложения в другую базу данных,
  необходимо вручную выполнить <a href="/admin/ePortal_database.htm">
  Проверку структуры БД</a> для создания отсутствующих таблиц.
</span>
</&>
<&| SELF:eng &>
<span class="memo">
  Be shure to <a href="/admin/ePortal_database.htm">
  Check database tables</a> if you decided use custom DBI source.
</span>
</&>
</%method>
