%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# Parameters:
%#  group - starting group ID
%#
%#----------------------------------------------------------------------------
<%perl>
  my $current_group = $ARGS{group};
  my $HTML;
  my $G = new ePortal::Catalog;
  my $group_memo = undef;
  my $xacl_check_insert = undef;

  while( $current_group and $G->restore($current_group) ) {
    if ( $current_group == $ARGS{group} ) { # First group object. Last (rightmost) item in the ring
      $HTML = '<b>' . CGI::a({-href => "/catalog/" . ($G->Nickname? $G->Nickname : $G->id)}, $G->Title) . '</b>';
      $group_memo = $G->Memo;
      $xacl_check_insert = $G->xacl_check_insert;

    } else {                                # second or more item
      $HTML = CGI::a({-href => "/catalog/" . ($G->Nickname? $G->Nickname : $G->id)}, $G->Title)
            . "&nbsp;&gt;&nbsp;" . $HTML;
    }

    last if $current_group == $G->parent_id;
    $current_group = $G->parent_id;
  }

  if ($ARGS{group}) {  # if some subgroups present
    $HTML = CGI::a({-href => "/catalog/index.htm"}, "Начало каталога") . "&nbsp;&gt;&nbsp;" . $HTML;
  } else {
    $HTML = '<b>' . pick_lang(
          rus => "Разделы каталога",
          eng => "Catalog groups") . '</b>';
  }

  # output HTML
</%perl>

<table border=0 bgcolor="#FFEEEE" width="100%"><tr>
  <td align="left"><% $HTML %></td>
</tr>
</table>
% if ($group_memo) {
  <& /htmlify.mc, content => $group_memo, allowhtml => 1, class => 'memo' &>
% }


