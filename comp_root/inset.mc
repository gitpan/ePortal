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
%# Arguments:
%#
%#   page => ID of inset. Default is $ENV{SCRIPT_NAME}
%#
%#   number => number of inset on the page.
%#
%#----------------------------------------------------------------------------
<%perl>
	$ARGS{number} = 1 unless $ARGS{number};
	$ARGS{page} = $ENV{SCRIPT_NAME} unless $ARGS{page};

	my $inset_id = "inset$ARGS{number}_$ARGS{page}";
	if ($ePortal->isAdmin) {
    $m->print( img(
      src => "/images/icons/text.gif",
			href => href("/inset_edit.htm", number => $ARGS{number}, page=>$ARGS{page}),
			title => pick_lang(
				rus => "Нажмите сюда, чтобы изменить кусок HTML в этом месте",
				eng => "Click here to insert HTML code right here"))
		);
	}

	my $inset = $ePortal->Config($inset_id);
</%perl><% $inset %>

