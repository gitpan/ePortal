#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.3 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/AuthCookieHandler.pm,v 3.3 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

package ePortal::AuthCookieHandler;
	use strict;
	use Apache;
	use Apache::Constants qw(:common);
    use Apache::Cookie();
	use MD5;
	use ePortal::Server;

	our $VERSION = sprintf '%d.%03d', q$Revision: 3.3 $ =~ /: (\d+).(\d+)/;


############################################################################
# Check validity of cookie
sub authen_ses_key ($$$) {
############################################################################
    my $self = shift;
    my $r = shift;

    my($username, $remoteip, $md5hash) = split(/:/, shift);
    return undef if ($username eq '') or ($md5hash eq '');

	my $actualremoteip = $r->get_remote_host;
	my $result;

	my $mymd5 = MD5->hexhash('13', $username, $remoteip);
	if ( $mymd5 ne $md5hash) {
        $r->log_error("authen_ses_key: MD5 check sum bad: $username, $actualremoteip\n");

        #ePortal::Server::SendAuthCookie(undef, $r, undef);
		return undef;
	}

	# Проверка адреса клиента
	if ($actualremoteip ne $remoteip) {
        $r->log_error("authen_ses_key: stored ip address $remoteip is different from original $actualremoteip\n");
        #ePortal::Server::SendAuthCookie(undef, $r, undef);
		return undef;
	}

	return $username;
}



############################################################################
# Recognize a user by ePortal_auth cookie
#
sub recognize_user ($$) {
############################################################################
  my ($self, $r) = @_;

  my $cookie = new Apache::Cookie($r);
  my %cookies = $cookie->parse;
  my $cookie_value = $cookies{ePortal_auth} ? $cookies{ePortal_auth}->value() : undef;
  return unless $cookie;

  if (my ($user) = $self->authen_ses_key($r, $cookie_value)) {
    $r->connection->user($user);
  }
  return OK;
}

1;
