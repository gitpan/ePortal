%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.3 $
%# $Date: 2003/04/24 05:36:52 $
%# $Header: /home/cvsroot/ePortal/comp_root/pv/create_session.mc,v 3.3 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>
  # pseudo persistent session
  %gdata = ();

  # Parse cookie and create persistent session
  my $cookie = new Apache::Cookie($r);
  my %cookies = $cookie->parse;

  foreach (keys %cookies) {
    logline('debug', "Cookie $_=$cookies{$_}");
  }

  # clear session hash
  %session = ();
  my $session_id = $cookies{ePortal} ? $cookies{ePortal}->value() : undef;
  $session{_session_id} = $session_id;

  # try to restore new session
  if ( $session_id ) {
    my $datacount = $dbh->selectrow_array("SELECT count(*) FROM sessions WHERE id=?", undef, $session_id);
    my $data = $dbh->selectrow_array("SELECT a_session FROM sessions WHERE id=?", undef, $session_id);
    if ( $datacount != 0 ) {
      %session = ( %{Storable::thaw($data)} );
    } else {
      $session{_new_session} = 1;
    }
  }

  # absolutely new session
  if ( ! $session_id ) {  # new user
    $session_id = substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time(). rand(). $$)), 0, 32);
    $session{_session_id} = $session_id;
    $session{_new_session} = 1;
  }

  if ( ! $cookies{ePortal} ) {
      my $cookie = new Apache::Cookie($r,
          -name=>'ePortal',
          -expires => '+3M',
          -value=>$session{_session_id},
          -path => '/',);
      $cookie->bake;
      my $address = $r->get_remote_host;
      logline('notice', "Sending cookie to client. TCP/IP=$address. ePortal=$session{_session_id}");
  }

  return $session{_session_id};
</%perl>
