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
  <table border=0 cellspacing=0 cellpadding=2 width="99%" align="center">
<%perl>
  my $group = $ARGS{group};
  my $COLUMNS = 3;                # Number of columns per page

  # Prefetch all groups
	my $catalog = new ePortal::Catalog;
  $catalog->restore_where(parent_id => $group, recordtype => "group", skip_attributes => [qw/text/]);

  # Generate HTML code for each group 
  my $restore_next;
  my $row;
  while($catalog->rows) {
    my $row_bgcolor = $row++ % 2 == 0? '#FFFFFF' : '#eeeeee';
    $m->out("<tr bgcolor=\"$row_bgcolor\">");
    foreach my $column (1 .. 3) {
      $restore_next = $catalog->restore_next;
      last if ! $restore_next and $column == 1;
      $m->print('<td width="33%">');
      $m->comp('SELF:group_item', G => $catalog);
      $m->print('</td>');
    }
    $m->print('</tr>');
    last if ! $restore_next;
  }
</%perl>
</table>
<p>

%#=== @metags group_item ====================================================
<%method group_item><%perl>
  my $G = $ARGS{G};

  # Empty cell if not group
  if ( ! $G->check_id ) {
    $m->print('&nbsp;');
    return;
  }

</%perl>
% if ($G->xacl_read ne 'everyone') {
    <% img(src=> '/images/ePortal/private.gif') %>
% }  

<b><a class="s9" 
      href="/catalog/<% $G->id %>" 
      title="<% $G->memo |h%>"><% $G->title |h%></a></b>


% my $records = $G->Records;
% if ($records) {
  <span class="memo">(<% $records %>)</span>
% }

% if ($G->xacl_check_update) {
  <% icon_tool("GroupMenu", $G->id) %>
% }

<br>
  <%perl>
  my $subgroups = new ePortal::Catalog;
  $subgroups->restore_where(parent_id => $G->id, recordtype => 'group');
  my $subgroups_found = 0;
  foreach (1..3) {
    last if ! $subgroups->restore_next;
    $subgroups_found ++;
    </%perl>
    <a class="s8" href="/catalog/<% $subgroups->id %>"><% $subgroups->Title |h%></a>,
% }
% if ($subgroups_found) { $m->print('...') }
</%method>
