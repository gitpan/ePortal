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
  my $username = $ARGS{username};
  my $fio = $ePortal->DBConnect->selectrow_array(
    "SELECT fullname FROM epUser WHERE username=?", undef, $username);
  $fio ||= $username;
</%perl>
<% $fio %>
