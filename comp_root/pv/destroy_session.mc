%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.2 $
%# $Date: 2003/04/24 05:36:52 $
%# $Header: /home/cvsroot/ePortal/comp_root/pv/destroy_session.mc,v 3.2 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>
  my $new_session = $session{_new_session};
  my $session_id = $session{_session_id};
  foreach (keys %session) {
    delete $session{$_} if /^_/o;
  }

  # if something to save
  if ( scalar %session ) {
    my $data = Storable::nfreeze(\%session);
    if ( $new_session ) {
      $dbh->do("INSERT into sessions (id,a_session) VALUES(?,?)", undef,
        $session_id, $data);
    } else {
      $dbh->do("UPDATE sessions SET a_session=? WHERE id=?", undef,
        $data, $session_id);
    }

  } else {  # nothing to save.
    $dbh->do("DELETE FROM sessions where id=?", undef, $session_id)
      if ! $new_session;
  }

  %session = ();
  %gdata = ();
</%perl>
