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
%# $Header: /home/cvsroot/ePortal/comp_root/pv/sections/catalog.mc,v 3.2 2003/04/24 05:36:52 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>
    my $section = $ARGS{section};
    my $catalog = new ePortal::Catalog;
    $catalog->restore_where(parent_id => undef, recordtype => 'group');
</%perl>

<table border=0 cellspacing=0 cellpadding=0 width="98%">
% while ($catalog->restore_next) {
    <tr><td class="sidemenu" nowrap>
        <a href="<% href("/catalog/index.htm", group => $catalog->id) %>"><% $catalog->Title %></a>
    </td></tr>
% }
</table>





%#=== @metags attr =========================================================
<%attr>
def_title => { eng => 'Resources catalogue', rus => 'Каталог ресурсов'},
def_width => 'N',
def_url => '/catalog/index.htm',
</%attr>
