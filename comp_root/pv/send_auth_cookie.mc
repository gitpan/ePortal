%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.1 $
%# $Date: 2003/04/24 05:36:52 $
%# $Header: /home/cvsroot/ePortal/comp_root/pv/send_auth_cookie.mc,v 3.1 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>
    my $username = $ARGS{username};
    my $savepassword = $ARGS{savepassword};

    my $cookie;

    if (defined $username) {
        my $remoteip = $r->get_remote_host;
        my $md5hash = MD5->hexhash('13', $username, $remoteip);
        my $ticket = join(":", $username, $remoteip, $md5hash );

        $cookie = new Apache::Cookie( $r, -name => 'ePortal_auth',
                $savepassword ? (-expires => '+1M') : (),
                -value => $ticket, -path => '/',);
    } else {
        $cookie = new Apache::Cookie($r, -name=>'ePortal_auth',
            -expires => 'Mon, 21-May-1971 00:00:00 GMT',
            -value => "", -path => '/',);
    }
    $cookie->bake;
    return undef;
</%perl>
