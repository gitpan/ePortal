#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.6 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Apache.pm,v 3.6 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::Apache - ePortal Intergation with Apache WEB server.

=head1 SYNOPSIS

ePortal is designed to work closely with Apache WEB server.

See at C<samples/httpd.conf> for Apache configuration examples.

=head1 METHODS

=cut

BEGIN {
    $| = 1;
}

package ePortal::Apache;
    require 5.6.0;
    our $VERSION = sprintf '%d.%03d', q$Revision: 3.6 $ =~ /: (\d+).(\d+)/;

    # --------------------------------------------------------------------
    # HTML and CGI stuff
    # --------------------------------------------------------------------
    use CGI qw/ -no_xhtml -no_debug -no_undef_params/;
    CGI->compile(':all');
    CGI::autoEscape(undef);

    # --------------------------------------------------------------------
    # Packages of ePortal itself
    # --------------------------------------------------------------------
    use ePortal::AuthCookieHandler;
    use ePortal::Global;
    use ePortal::Utils;
    use ePortal::Server;

    # Packages for use under Apache
    use ePortal::Dual::Login;
    use ePortal::Dual::Search;
    use ePortal::Dual::SimpleSearch;
    use ePortal::HTML::Calendar;
    use ePortal::HTML::Dialog;
    use ePortal::HTML::List;
    use ePortal::HTML::Tree;

    # --------------------------------------------------------------------
    # Other Perl modules used in some components of ePortal

    # --------------------------------------------------------------------
    # System modules.
    #
    use HTML::Mason;
    use HTML::Mason::ApacheHandler;
    use Apache;
    use Apache::Request;
    use Apache::Constants qw/OK DECLINED/;


{   # --------------------------------------------------------------------
    # Modules used in native Mason components. Load them in
    # HTML::Mason::Commands in order to use right namespace
    #
    package HTML::Mason::Commands;
    use Carp;                           # import carp, warn
                                        #
    use ePortal::Global;                # import global variables
    use ePortal::Utils;                 # import global functions (logline)
    use ePortal::Exception;
    use Error qw/:try/;

    use Apache::Util qw/escape_html escape_uri/;    # Apache is faster then CGI
    use Apache::Cookie;
    1;
}


# ------------------------------------------------------------------------
# Main entrance
#
#
sub handler
{
    my $r = shift;
    my $result = undef;
    return DECLINED unless ($r->is_main);


    # ----------------------------------------------------------------
    # I serve only some types of MIME
    #
    if ($r->content_type
            && $r->content_type !~ m|^text/|io
            && $r->content_type ne 'application/x-javascript'
            && $r->content_type ne 'httpd/unix-directory'
    ) {
        logline('debug', 'Request denied: ' . $r->uri . ' served as ' . $r->content_type);
        return DECLINED;
    }

    return HTML::Mason::ApacheHandler->handler($r);
}   ## end of handler




1;


__END__


=head1 SEE ALSO

L<ePortal::Server class|ePortal::Server>

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

