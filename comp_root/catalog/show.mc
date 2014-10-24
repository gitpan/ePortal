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
  my $item = $ARGS{item};

</%perl>

%#========================================================================
%# Textual information
%#
% if ($item->Text) {
  <p>
  <%perl>
  if ( $item->textType eq 'HTML' ) {
    $m->comp('/htmlify.mc', content => $item->Text, allowhtml => 1, class=> 's10');
  
  } elsif ( $item->textType eq 'pre' ) {
    $m->print(qq{\n<pre class="s10">\n});
    $m->print($item->Text);
    $m->print(qq{\n</pre>\n});
  
  } else {
    $m->comp('/htmlify.mc', content => $item->Text, allowphtml => 1, class=> 's10');
  }
  </%perl>
  </p>
% } 

%#========================================================================
%# Common information
%#
<p>
<& /item_caption.mc, title => pick_lang(rus => "����� ����������", eng => "Information") &>
  <p style="margin-left: 1cm;">
  <b><% pick_lang(rus => "��������", eng => "Name") %></b>: <% $item->Title %>
  <br><b><% pick_lang(rus => "�����", eng => "Author") %></b>: <& /fio.mc, username => $item->uid &>
  <br><b><% pick_lang(rus => "���� ���������", eng => "Time stamp") %></b>: <% $item->ts %>
% if ($item->xacl_check_update) {
  <br><% plink( pick_lang(rus => "������������� ������ ������", eng => "Edit this resource"),
        -href => href('/catalog/file_edit.htm', objid => $item->id) ) %>
% }
  </p>

%#========================================================================
%# Attachments
%#

% my $att = new ePortal::Attachment;
% $att->restore_where(obj => $item);
% if ($att->rows == 1) {
%  $att->restore_next;
  <p>
  <& /item_caption.mc, title => pick_lang(rus => "������������� ����", eng => "Attached file") &>
  <div style="margin-left: 1cm;">
  <br><b><% pick_lang(rus => "��� �����: ", eng => "File name: ") %></b>
      <% $att->Filename |h %>
  <br><b><% pick_lang(rus => "������ �����: ", eng => "File size: ") %></b>
      <% $att->Filesize %> <% pick_lang(rus => "����", eng => "bytes") %>
  <br><% plink(
      pick_lang(rus => "����������� ", eng => "View ") . $att->Filename,
      -href => href('/catalog/' . $item->id . '/' . Apache::Util::escape_uri($att->Filename))) %>
      <% plink(
      pick_lang(rus => "��������� ", eng => "Download ") . $att->Filename,
      -href => href('/catalog/' . $item->id . '/' . Apache::Util::escape_uri($att->Filename), todisk=>1)) %>
  </div>

% } elsif ($att->rows > 1) {
  <p>
  <& /item_caption.mc, title => pick_lang(rus => "��� ����� ������� �������", eng => "All files of this resource") &>
  <div style="margin-left: 1cm;">
  <&| /list.mc, obj => $att, -width => '60%', rows => 10, no_footer => 2,
        restore_where => { obj => $item, order_by => 'id' }, order_by => 'filename' &>
 
   <&| /list.mc:row &>
    <& /list.mc:column_image &>
    <& /list.mc:column, id => 'filename', 
          url => '/catalog/' . $item->id . '/' . Apache::Util::escape_uri($_->Filename),
          title => pick_lang(rus => "��� �����", eng => "File name") &>
    <& /list.mc:column, id => 'filesize', title => pick_lang(rus => "������ �����", eng => "File size"), -align => 'center' &>
    <&| /list.mc:column &>
      <% plink(pick_lang(rus => "���������", eng => "Download"), 
        -href => href('/catalog/' . $item->id . '/' . Apache::Util::escape_uri($_->Filename), todisk=>1)) %>
    </&>

% if ($item->xacl_check_update) {
     <& /list.mc:column_delete &>
% }

 </&><!-- row -->
</&><!-- list -->
</div>
% } # of of if att->rows


%#========================================================================
%# File upload
%#
% if ($item->xacl_check_update) {
  <p>
  <& /item_caption.mc, title => pick_lang(rus => '�������� ����', eng => "Attach a file") &>
  <p style="margin-left: 1cm;">
  <% CGI::start_multipart_form({-name => 'uploadForm', method => 'POST', action=>'/catalog/upload.htm'}) %>
  <% CGI::hidden({-name => 'objid', -value => $item->id}) %>
  <% CGI::filefield({-name => 'upload_file'}) %>
  <% CGI::submit(-name => 'submit', -value => pick_lang(rus => '���������', eng => "Upload")) %>
  </form>
  </p>
% }
