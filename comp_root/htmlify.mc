%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#----------------------------------------------------------------------------
<%perl>
  my $content = $ARGS{content} || $m->content;
  my $allowhtml = $ARGS{allowhtml};         # allow pure html
  my $allowphtml = $ARGS{allowphtml};       # allow some of [xxx] tags
  my $allowsmiles = $ARGS{allowsmiles};     # allow smiles for MsgForum
  my $highlightreply = $ARGS{highlightreply};# highlight '>' quoted lines
                                             # also wrap content at 70st column
  my $class = $ARGS{class};                 # wrap content in <span class...>

  if ( $highlightreply ) {
    $allowphtml = 1;        # '>' highlight doing with [span] tag

    # Разбиваем на длинные строки
    my @lines = split('\n', $content );
    foreach my $line (@lines) {
      $Text::Wrap::columns = 70;
      $line = Text::Wrap::wrap('', '', $line);

      # Если строка начинается на >, то все последующие строки, которые
      # получились из-за переноса тоже добавляем символом >. У которых уже
      # есть такой символ - не трогаем
      if ($line =~ /^(>+)/o) {
          my $tag = $1;
          $line = join "\n", map({/^$tag/ ? $_ : "$tag$_"} split('\n', $line));
      }
    }
    $content = join "\n", @lines;
    $content =~ s{^(>.*)$}{\[span style="color:#990000;"\]$1\[/span\]}gm;
  }

  if ( ! $allowhtml ) {
    # remove all dangerous code
    $content =~ s/</&lt;/gso;
    $content =~ s/>/&gt;/gso;
  }

  if ( $allowphtml ) {
    # replace my own code
    $content =~ s/\[(span|a|img|font) ([^\]]+)\]/<$1 $2>/igs;
    $content =~ s/\[\/(span|a|img|font)\]/<\/$1>/igs;
    $content =~ s/\[(\/?)(p|br|b|i|u|ul|li|h1|h2|h3)\]/<$1$2>/igs;

    # replace hyperlinks with <a href...>
    $content =~ s{
        ([^"]?)
        (http|mailto|ftp):(\S+)
      }{$1<a href="$2:$3">$2:$3</a>}igsx;
  }

  # Some predefinec smiles
  $content =~ s/:-?\)/:smile:/go;
  $content =~ s/;-?\)/:wink:/go;
  $content =~ s/[:;]-?\(/:frown:/go;
  $content =~ s/:-[\\\/]/:smirk:/go;
  $content =~ s/:[oо]/:redface:/igo;
  $content =~ s/:(smile|wink|frown|smirk|redface):/<img src="\/images\/smiles\/$1.gif">/gs;

  if ( $allowsmiles ) {
    # other MsgForum smiles
    try {
      my $app = $ePortal->Application('MsgForum');
      my $smiletag = join '|', @ePortal::App::MsgForum::Smiles, @ePortal::App::MsgForum::Smiles2;
      $content =~ s/:($smiletag):/<img src="\/images\/MsgForum\/smiles\/$1.gif">/gs;
    } catch ePortal::Exception::ApplicationNotInstalled with {
      # just catch it here
    };  
  }

  # Add line breaks
  if ( ! $allowhtml ) {
    $content =~ tr/\r//d;
    $content =~ s/\n\n+/<p>/gs;
    $content =~ s/\n/\n<br>/gs;
    $content =~ s/<p>/\n<p>/gs;

  } else {  # Remove <html><head><body>
    $content =~ s{</?html>}{}igs;
    $content =~ s{</?body[^>]*>}{}igs;
    $content =~ s{<head.*</head>}{}igs;
  }  

  # Add class tag
  if ( $class ) {
    $content =~ s{<p>}{<p class="$class">}igs;
    $content = CGI::span({-class => $class}, $content);
  }

</%perl>
<% $content %>
