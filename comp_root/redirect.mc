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
%# $Header: /home/cvsroot/ePortal/comp_root/redirect.mc,v 3.1 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------
<%perl>

	# Add optional server:port and full path
	if ($location !~ m|^/| and $location !~ m|://|) {
		my $redir_path = ($ENV{SCRIPT_NAME} =~ m|^(.*)/|)[0];		# current script_path
		$location = "$redir_path/$location";
	}
	if ($location !~ m|://|) {
		my $redir_server = "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}";						# host:port notation
		$location = "$redir_server$location";
	}

	logline("info", "Redirect from $ENV{SCRIPT_NAME} to $location");

	# The next two lines are necessary to stop Apache from re-reading POSTed data.
# $m->clear_buffer;
#  $r->method('GET');
#  $r->headers_in->unset('Content-length');

#  $r->content_type('text/html');
#  $r->header_out(Location => $location);

#  $m->abort(302);  # HTTP_MOVED_TEMPORARILY

    $m->redirect($location);
	return undef;
</%perl>

<%args>
$location => "/index.htm"
</%args>
