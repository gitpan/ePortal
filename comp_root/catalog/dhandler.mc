%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#----------------------------------------------------------------------------
% if ($C->RecordType eq 'group') {
  <table width="100%" border=0>
  <tr><td>
  <& /catalog/group_ring.mc, group => $C->id &>
  <& /catalog/groups.mc, group => $C->id &>
  <& /catalog/links_ring.mc, group => $C->id &>
  <& /catalog/links.mc, group => $C->id &>
  </td><td width="10%">
    <& /catalog/admin.mc, group => $C->id &>
    <& /catalog/search_dialog.mc &>
    <% empty_table(height => 5) %>
    <& /catalog/mostpopular.mc &>
  </td></tr></table>

% } else {
  <& /catalog/group_ring.mc, group => $C->id &>
  <& show.mc, item => $C &>
% }

<%filter>
</%filter>

%#=== @metags onStartRequest ====================================================
<%method onStartRequest><& PARENT:onStartRequest, %ARGS &><%perl>
  # This request to catalog is not cacheable
  # THIS OPTION IS INCOMPATIBLE WITH IE 4.0 !!!!!!!!!!!!!!!!!!!!!
  #$r->no_cache(1);

  my $dh_args = $m->dhandler_arg;
  ($catid, $file) = split('/', $dh_args, 2);

  # A request to /catalog/num should be rewrited to /catalog/num/
  if ( $catid ne '' and $file eq '' and $ENV{REQUEST_URI} !~ m|/$| ) {
    throw ePortal::Exception::Abort(-text => $catid . '/');
  }

  $C = new ePortal::Catalog;
  my $last_modified = undef;

  throw ePortal::Exception::FileNotFound( -file => "/catalog/" . $m->dhandler_arg)
    if ! $C->restore($catid);
  
  $C->ClickTheLink;          # Increment number of clicks
  $last_modified = $C->LastModified;

  # The link requires us to redirect
  if ( $C->RecordType eq 'link' ) {
    throw ePortal::Exception::Abort(-text => $C->url);
  }

  # Special case. Request to resource with 1 file and without any text
  if ( $file eq '' and 
          $C->RecordType eq 'file' and 
          $C->Text eq '' and 
          $C->Attachments == 1 ) {
    my $att = new ePortal::Attachment;
    $att->restore_where(obj => $C);
    $att->restore_next;

    throw ePortal::Exception::Abort(-text => '/catalog/' . $catid . '/' . $att->Filename);
  }

  # Download a file as attachment
  if ( $file ) {
    my $att = new ePortal::Attachment;
    $att->restore_where(obj => $C, filename => $file);
    throw ePortal::Exception::FileNotFound(-file => '/catalog/' . $m->dhandler_arg)
      if ( ! $att->restore_next );

      # Determine mime type
    my $subr = $r->lookup_uri('/' . escape_uri($file));
    my $content_type = $subr ? $subr->content_type : undef;
    $content_type = "application/octet-stream" unless $content_type;
    logline('info', "Downloading file $file as ", $content_type);

    # Prepare HTTP headers
    $last_modified = $att->LastModified;
    $m->clear_buffer;
    $r->content_type($content_type);
    $r->header_out('Content-Disposition' => 
      ($ARGS{todisk} ? 'attachment' : 'inline') . 
      "; filename=$file");
    $r->header_out( "Content-Length" => $att->filesize );
    $r->set_last_modified($last_modified) if defined $last_modified;
    $r->send_http_header;
    throw ePortal::Exception::Abort if $r->header_only;

    # Send the content
    $att->get_first_chunk;
    while(my $buffer = $att->get_next_chunk) {
      last if $r->connection->aborted;
      $m->print($buffer);
      $m->flush_buffer;
    }
    throw ePortal::Exception::Abort;
  }

  $r->set_last_modified($last_modified);
</%perl></%method>



%#=== @METAGS Title ====================================================
<%method Title><%perl>
  if ( ref($C) and $C->check_id ) {
    return pick_lang(rus => "�������: ", eng => "Catalogue: ") . $C->Title;
  } else {
    return pick_lang(rus => "������� ��������", eng => "Resources catalogue");
  }  
</%perl></%method>


%#=== @METAGS once =========================================================
<%once>
my($C, $catid, $file, $other);
</%once>
