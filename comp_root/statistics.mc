%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.2 $
%# $Date: 2003/04/24 05:36:51 $
%# $Header: /home/cvsroot/ePortal/comp_root/statistics.mc,v 3.2 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------

<%perl>
my $ctlg = new ePortal::Catalog;
$ctlg->HitTheLink($id);

if ( $image ) {
  $m->print( img(src => '/images/ePortal/statistics.gif',
    title => pick_lang(rus => "Статистика ресурса:", eng => "Rsource statistics:") .
      "\n" . pick_lang(rus => "Всего обращений:", eng => "Hits total:") . $ctlg->Hits .
      "\n" . pick_lang(rus => "Обращений сегодня:", eng => "Hits today:") . $ctlg->HitsToday .
      "\n" . pick_lang(rus => "Визиторов сегодня:", eng => "Visitors today:") . $ctlg->VisitorsToday,
    href => href('/catalog/statistics.htm', id => $id),
      ));
}
</%perl>

%#=== @METAGS args =========================================================
<%args>
$id
$image => 1
</%args>
