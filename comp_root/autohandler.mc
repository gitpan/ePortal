%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%# $Revision: 3.7 $
%# $Date: 2003/04/24 05:36:51 $
%# $Header: /home/cvsroot/ePortal/comp_root/autohandler.mc,v 3.7 2003/04/24 05:36:51 ras Exp $
%#
%#----------------------------------------------------------------------------
%# $Layout:
%#    Normal - normal window
%#    Dialog - Dialog window
%#    MenuItems - normal with menu on the left
%#    Popup - popup window
%#    Empty - No widgets (for Errors, Exports)
%#    Nothing - Absolutely not output in autohandler
<%init>

  #
  # Prepare for page construction.
  #

  my $call_next_content;
  my ($location, $Title, $MenuItems);
  my $Layout = 'Normal';
  try {
    # Create ePortal Server object
    $ePortal = new ePortal::Server();
    $ePortal->initialize();

    # test database connection
    $dbh = $ePortal->DBConnect();

    # create persistent Session hash
    $m->scomp("/pv/create_session.mc");
    $ePortal->handle_request($r);

    # Application handling
#    my $appname = $m->request_comp->attr('Application');
#    $ePortal->Application($appname, throw => 1) if $appname; # will throw

    # onStartRequest method
    $location = $m->comp('SELF:onStartRequest', %ARGS);

    $Layout = $m->request_comp->attr("Layout");

    # Title
    $Title = $m->comp("SELF:Title", %ARGS);
    $Title = pick_lang($Title) if ref($Title) eq 'HASH';

    # MenuItems
    $MenuItems = $m->comp("SELF:MenuItems", %ARGS);
    $MenuItems = $m->scomp("/pv/leftmenu.mc", $MenuItems);
    $Layout = 'MenuItems' if ($Layout eq 'Normal') and $MenuItems;

    # Access control
    my $require_user  = $m->request_comp->attr("require_user");
    my $require_group = $m->request_comp->attr("require_group");
    my $require_admin = $m->request_comp->attr("require_admin");
    my $require_sysacl = $m->request_comp->attr("require_sysacl");
    my $require_registered = $require_user || $require_group ||
      $require_admin || $require_sysacl || $m->request_comp->attr("require_registered");

    if ( $require_registered and ! $ePortal->username) {
      throw ePortal::Exception::ACL(-operation => 'require_registered');
    }
    if ($require_user) {
      $require_user = [$require_user] if ref($require_user) ne 'ARRAY';
      my $username = $ePortal->username;
      throw ePortal::Exception::ACL(-operation => 'require_user')
        if ! grep { $_ eq $username } @$require_user;

    } elsif ($require_group) {
      $require_group = [$require_group] if ref($require_group) ne 'ARRAY';
      throw ePortal::Exception::ACL(-operation => 'require_group')
        if ! grep { $ePortal->user->group_member($_) } @$require_group;

    } elsif ($require_admin) {
      throw ePortal::Exception::ACL(-operation => 'require_admin')
        unless $ePortal->isAdmin;

    } elsif (ref($require_sysacl) eq 'ARRAY') {
      throw ePortal::Exception::ACL(-operation => 'require_sysacl')
        unless $ePortal->sysacl_check(@$require_sysacl);
    }


  #===========================================================================
  } catch ePortal::Exception::ACL with {
  #===========================================================================
    my $E = shift;
    logline('error', ref($E), ': '. $E);
    $call_next_content = $m->scomp('/pv/show_exception_acl.mc', E => $E);
    $Layout = 'Empty';

  #===========================================================================
  } catch ePortal::Exception::Fatal with {
  #===========================================================================
    my $E = shift;
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E") . 
      "\n<!-- " . $E->stacktrace . "-->\n";
    $Layout = 'Empty';

  #===========================================================================
  } catch ePortal::Exception::DBI with {
  #===========================================================================
    my $E = shift;
    $Layout = 'Empty';
    $call_next_content = $m->scomp('/message.mc',
        ErrorMessage => pick_lang(
          rus => "Ошибка сервера баз данных",
          eng => "SQL server error")) .
          "\n<!-- $E  -->\n" .
          "\n<!-- ".$E->stacktrace."  -->\n";

  #===========================================================================
  } catch ePortal::Exception::DataNotValid with {
  #===========================================================================
    my $E = shift;
    logline('info', ref($E), ': '. $E);
    $session{ErrorMessage} = '' . $E;
    $location = undef;

  #===========================================================================
  } catch ePortal::Exception::ObjectNotFound with {
  #===========================================================================
    my $E = shift;
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");
    $location = undef;

  #===========================================================================
  } catch ePortal::Exception::ApplicationNotInstalled with {
  #===========================================================================
    my $E = shift;
    logline('critical', ref($E), ': '. $E);
    $Layout = 'Empty';
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "Application $E is not installed");

  #===========================================================================
  } catch ePortal::Exception::FileNotFound with {
  #===========================================================================
    my $E = shift;
    logline('warn', ref($E), ': '. $E->file);
    $Layout = 'Empty';
    $m->clear_buffer;
    $r->status(404);
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "File ".$E->file." not found");

  #===========================================================================
  } catch ePortal::Exception with {
  #===========================================================================
    my $E = shift;
    logline('info', ref($E), ': '. $E);
    $Layout = 'Normal';
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } otherwise {
    my $E = shift;
    logline('emerg', 'General exception: ', ref($E), $E);
    if ( UNIVERSAL::can($E, 'rethrow') ) {
      warn "rethrowing";
      $E->rethrow;
    } else {
      die $E;
    }
  };


  # $location may be empty but defined, and defined and not empty
  if (defined $location) {
    if ($location) {
      $m->scomp('SELF:cleanup_request');
      $m->comp("/redirect.mc", location => $location);
    }
    return;
  }

  # Everything after that is HTML!
  $r->content_type("text/html");
</%init>
%#============================================================================
%# START OF HTML
%#============================================================================
% if ($Layout ne 'Nothing') {
<!doctype html public "-//w3c//dtd html 4.0 transitional//en">
<html>
<head>
  <meta name="Author" content="'S.Rusakov' <rusakov_sa@users.sourceforge.net>">
  <meta name="keywords" content="ePortal, WEB portal, organizer, personal organizer, ежедневник, портал">
  <meta name="copyright" content="Copyright (c) 2001-2002 Sergey Rusakov">
  <meta name="Description" content="<% pick_lang(rus => "Домашняя страница ePortal", eng => "Home page of ePortal") %>">
  <title><% $Title %></title>
  <link rel="STYLESHEET" type="text/css" href="/styles/default.css">
  <script language="JavaScript" src="/common.js"></script>
  <& SELF:HTMLhead, %ARGS &>
</head>
<body bgcolor="#FFFFFF" leftmargin="0" rightmargin="0" topmargin="0" bottommargin="0" marginwidth="0" marginheight="0">
%} # end of ($Layout ne 'Nothing')

%#
%# =========== SCREEN BEGIN ==================================================
%#

% if (grep { $Layout eq $_} (qw/Normal Dialog MenuItems/)) {
  <!--UdmComment-->
  <& /pv/topmenubar.mc &>
  <& /pv/topappbar.mc, title => $Title &>
  <!--/UdmComment-->
%}

% if ($Layout eq 'MenuItems') {
<table width="100%" border=0 cellspacing=0 cellpadding=0><tr>
  <td width="120" valign="top"><% $MenuItems %></td>
  <% empty_td( black => 1, width => 1 ) %>
  <% empty_td( width => 5 ) %>
  <td width="95%" valign="top">
% }

% if ($Layout ne 'Nothing') {
  <& /message.mc &>
% }

<%perl>
  $m->flush_buffer;
  try {
    $m->call_next if $call_next_content eq '';

  #===========================================================================
  } catch ePortal::Exception::ACL with {
  #===========================================================================
    my $E = shift;
    $call_next_content = $m->scomp('/pv/show_exception_acl.mc', E => $E);

  #===========================================================================
  } catch ePortal::Exception::DBI with {
  #===========================================================================
    my $E = shift;
    $call_next_content = $m->scomp('/message.mc',
        ErrorMessage => pick_lang(
          rus => "Не могу подключиться к серверу баз данных",
          eng => "Cannot connect to database server")) .
          "\n<!-- $E  -->\n" .
          "\n<!-- ".$E->stacktrace."  -->\n";

  #===========================================================================
  } catch ePortal::Exception::DataNotValid with {
  #===========================================================================
    my $E = shift;
    logline('info', ref($E), ': '. $E);
    $session{ErrorMessage} = '' . $E;

  #===========================================================================
  } catch ePortal::Exception::ApplicationNotInstalled with {
  #===========================================================================
    my $E = shift;
    logline('critical', ref($E), ': '. $E);
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "Application $E is not installed");

  #===========================================================================
  } catch ePortal::Exception::FileNotFound with {
    my $E = shift;
    logline('warn', ref($E), ': '. $E->file);
    $Layout = 'Empty';
    $r->status(404);
    $m->clear_buffer;
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "File ".$E->file." not found");

  #===========================================================================
  } catch ePortal::Exception::ObjectNotFound with {
  #===========================================================================
    my $E = shift;
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } catch ePortal::Exception with {
  #===========================================================================
    my $E = shift;
    logline('info', ref($E), ': '. $E);
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "$E");

  #===========================================================================
  } otherwise {
    my $E = shift;

      # compilation error goes here
    logline('error', 'General exception: ', "$E");
    $call_next_content = $m->scomp('/message.mc', ErrorMessage => "System error. See error_log for details.");
    if ( UNIVERSAL::can($E, 'rethrow') ) {
      $E->rethrow;
    } else {
      die $E;
    }
  };

</%perl>
<% $call_next_content %>

%#============================================================================
%# AFTER THE call_next
%#============================================================================
% if ($Layout eq 'MenuItems') {
</td></tr></table>
% }

% if (grep { $Layout eq $_} (qw/Normal Dialog MenuItems/)) {
 <% empty_table( black => 1, height => 1 ) %>
 <& SELF:Footer &>
%}

%#============================================================================
%# END OF SCREEN
%#============================================================================
% if ($ePortal->username and grep { $Layout eq $_} (qw/Normal MenuItems/)) {
<Iframe Name="Alerter_IFrame" scrolling="no" src="/frame_alerter.htm" width="0" height="0" align="right" border="0" noresize>
</Iframe>
% }

% if ($Layout ne 'Nothing') {
</body>
</html>
% }
<!-- Layout: <% $Layout %> -->
%#============================================================================
%# CLEANUP BLOCK
%#============================================================================
<& SELF:cleanup_request &>

%#
%# =========== SCREEN END ====================================================
%#



%#=== @METAGS attr ===========================================================
<%attr>
Title       => "ePortal v.$ePortal::Server::VERSION. Home page"
Layout      => 'Normal'
Application => 'ePortal'

dir_enabled => 1
dir_nobackurl => 1
dir_sortcode => undef
dir_description => \&ePortal::Utils::filter_auto_title
dir_columns => [qw/icon name size modified description/]
dir_include => []
dir_exclude => []
dir_title => 'default'

require_registered => undef
require_user => undef
require_group => undef
require_admin => undef
require_sysacl => undef
</%attr>




%#=== @METAGS methods_prototypes =============================================
<%method HTMLhead></%method>
<%method MenuItems><%perl> return []; </%perl></%method>
<%method onStartRequest></%method>
<%method Title><%perl>return $m->request_comp->attr("Title");</%perl></%method>


%#=== @metags Footer ====================================================
<%method Footer>
<span class="copyright">
ePortal v<% $ePortal::Server::VERSION %> &copy; 2000-2001 S.Rusakov
<br>
<& /inset.mc, page => "/autohandler.mc", number => 9 &>
</span>

</%method>


%#=== @METAGS cleanup_request ====================================================
<%method cleanup_request><%perl>
  $ePortal->cleanup_request($r);
  $m->scomp('/pv/destroy_session.mc');
  $ePortal = undef;

  $dbh->disconnect if ref($dbh);
  $dbh = undef;
</%perl></%method>
