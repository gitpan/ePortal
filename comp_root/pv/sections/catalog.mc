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
<%perl>
    my $section = $ARGS{section};
    my $catalog = new ePortal::Catalog;
    $catalog->restore_where(parent_id => undef, recordtype => 'group');
</%perl>

<table border=0 cellspacing=0 cellpadding=0 width="98%">
% while ($catalog->restore_next) {
    <tr><td class="sidemenu" nowrap>
        <a href="<% '/catalog/' . $catalog->id %>"><% $catalog->Title %></a>
    </td></tr>
% }
</table>





%#=== @metags attr =========================================================
<%attr>
def_title => { eng => 'Resources catalogue', rus => 'Каталог ресурсов'},
def_width => 'N',
def_url => '/catalog/index.htm',
</%attr>
