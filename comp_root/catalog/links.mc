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
%# Parameters:
%#    group=<id> display this group
%#
%#----------------------------------------------------------------------------

<&| /list.mc, obj => new ePortal::Catalog, 
          no_title => 1,
          submit => 1,
          restore_where => {
            state => 'ok',
            parent_id => $ARGS{group},
            skip_attributes => ['text'],
            order_by => 'priority,title',
            where => "recordtype not in('group')"
          } &>

 <&| /list.mc:row &>
  <& /list.mc:column_image, -width => '3%',
                src => $_->xacl_read eq 'everyone'
                            ? '/images/ePortal/item.gif'
                            : '/images/ePortal/private.gif' &>
  <&| /list.mc:column, id => 'title', url => '/catalog/'.$_->id &>
    <% $_->Title %>
  </&>

% if ($_->xacl_check_update) {
    <& /list.mc:column_edit, 
        url => href(($_->recordtype eq 'link' 
                    ? 'link_edit.htm'
                    : 'file_edit.htm'), objid => $_->id) &>
% } else {
    <& /list.mc:column, content => '&nbsp;' &>
% }


% if ($_->xacl_check_delete) {
    <& /list.mc:column_delete &>
% } else {
    <& /list.mc:column, content => '&nbsp;' &>
% }

 </&><!-- row -->

% if ( $_->Memo ) {
  <&| /list.mc:extra_row &>
  <& /htmlify.mc, class => 'memo', content => $_->Memo &>
  </&>
% }

 <& /list.mc:row_span, &>
  
 <&| /list.mc:nodata &>
  <div style="font-size: 8pt; color:red; text-indent: 20px;">
  <% img(src=> "/images/ePortal/item.gif") %>
  <% pick_lang(
      rus => "Нет ни одного ресурса в этом разделе.",
      eng => 'There is no resources in this group.' ) %>
  </div>
 </&>

</&><!-- end of list -->

