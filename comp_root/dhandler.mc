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
%# $Header: /home/cvsroot/ePortal/comp_root/dhandler.mc,v 3.1 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------

<%perl>
	# I serve requests only for directories
  if (! -d $r->filename) {
#    logline('warn', "File not found: ", $m->dhandler_arg);
#    $m->comp("/redirect.mc",
#      location => href("/errors/error404.htm", url => $m->dhandler_arg));

    $m->comp('/errors/error404.htm');
    return;
#    throw ePortal::Exception::FileNotFound(-file => $r->filename);
#    return;
  }

	# Due to location of dhandler at component root it inherits only base
	# attributes by default. I need to find first autohandler from the top
	# and use it for attributes

	my @path_parts = split "/", $r->uri;
	$attrib_comp = undef;
	while(@path_parts) {
		my $pretendent = join("/", @path_parts)."/" . $m->interp->autohandler_name;
		if ( $m->comp_exists($pretendent)) {
			$attrib_comp = $m->fetch_comp($pretendent);
			last;
		}
		pop @path_parts;
	}

	if (! $attrib_comp ) {
		$attrib_comp = $m->fetch_comp("/autohandler.mc");
	}

	if ( ! $attrib_comp->attr('dir_enabled') ) {
    $m->comp("/redirect.mc",
      location => href("/errors/error404.htm", url => $m->dhandler_arg));
    return;
	}
</%perl>

<& /dir.mc,
	exclude => $attrib_comp->attr('dir_exclude'),
	nobackurl => $attrib_comp->attr('dir_nobackurl'),
	sortcode => $attrib_comp->attr('dir_sortcode'),
	description => $attrib_comp->attr('dir_description'),
	columns => $attrib_comp->attr('dir_columns'),
	include => $attrib_comp->attr('dir_include'),
	title => $attrib_comp->attr('dir_title'),
&>


%#=== @METAGS onStartRequest ====================================================
<%method onStartRequest><%perl>
  if (! -d $r->filename and ! -f $r->filename) {
    $m->comp('/errors/error404.htm');
    return '';  # do not redirect but stop further processing
  }
</%perl></%method>


%#=== @METAGS once =========================================================
<%once>
my $attrib_comp;
</%once>
