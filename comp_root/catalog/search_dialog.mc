%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#----------------------------------------------------------------------------

<& /search_dialog.mc, title => pick_lang(rus => 'Поиск в каталоге',eng => 'Search in Catalog'),
    vertical => 1, show_all => 0, label => '',
    action => "/catalog/search.htm" &>
