%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.1 $
%# $Date: 2003/04/24 05:36:51 $
%# $Header: /home/cvsroot/ePortal/comp_root/admin/autohandler.mc,v 3.1 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------

<& /message.mc &>
<% $m->call_next %>


%#----------------------------------------------------------------------------
<%attr>
Title => {rus => "Раздел администратора", eng => "Administrators page"}
require_admin => 1
</%attr>

