#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# cstocs() code is from Convert::Cyrillic package of
# John Neystadt <john@neystadt.org>
# I duplicate it here because there is no PPM for it undef WinXX
#
# $Revision: 3.3 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Utils.pm,v 3.3 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::Utils - useful global wide functions.

=head1 SYNOPSIS

Some functions are very useful anywhere. They are collected here.

=head1 METHODS

=cut

package ePortal::Utils;
    our $VERSION = sprintf '%d.%03d', q$Revision: 3.3 $ =~ /: (\d+).(\d+)/;

    use Carp qw/croak/;
    use ePortal::Global;
    #use CGI qw/-nosticky -no_xhtml -no_debug/; # CGI used in ePortal::Apache
    CGI::autoEscape(0) if $CGI::VERSION;
    use Image::Size;
    use FileHandle();
    use Fcntl(':flock');
    #use Convert::Cyrillic ();
    use Params::Validate qw/:types/;
    use Error qw/:try/;
    use ePortal::Exception;

    require Exporter;
    our @EXPORT = qw/
                    &logline &pick_lang &cstocs
                    &empty_td &empty_tr &empty_table
                    &href &plink &img
                    &icon_access &icon_edit &icon_delete &icon_export &icon_tool
                    &filter_html
                    &filter_txt &filter_txt_title
                    &filter_auto_title
                    &date_to_sql
                    /;
    our @ISA = qw/Exporter/;



=head2 logline(loglevel,string,...)

Record the string in error log. There are a number of loglevels:

=over 4

=item * emerg

Emergencies - system is unusable: Object creation errors.

=item * alert

Action must be taken immediately.

=item * crit

Critical Conditions.

=item * error

Error conditions.

=item * warn

Warning conditions.

=item * notice

Normal but significant condition.

=item * info

Informational: Redirects.

=item * debug

Debug-level messages: ACL checking

=back

=cut

my %logline_levels = (
    emerg  => 8,
    alert  => 7,
    crit   => 6,
    error  => 5,
    warn   => 4, # here and above are errors and mistakes
    notice => 3, # here and below are informational levels
    info   => 2,
    debug  => 1
    );
############################################################################
sub logline(;@) {   #11/03/00 10:16
############################################################################
    Params::Validate::validate_pos( @_, {type => SCALAR}, (0) x (@_ - 1) );

    my $loglevel = shift;
    my $line = join('', @_);

    # If ePortal object is not ready just print to STDERR
    if (!ref($ePortal)) {
        print STDERR "$line\n";
        return;
    }

    # change charset if needed
    my $charset = ref($ePortal) ? $ePortal->log_charset: undef;
    if ($charset) {
        $line = cstocs('WIN',$charset, $line);
    }

    # check requested loglevel
    my $loglevel_num = $logline_levels{lc $loglevel};
    my $ePortal_loglevel = $logline_levels{$ePortal->debug};
    if ($loglevel_num < $ePortal_loglevel) {
        return;
    }

    # adjust log text
    $line = $ePortal->vhost . ": $line" . "\n";

    # log the text to file or STDERR
    my $filename = $ePortal->log_filename;
    if ( $filename =~ m|^/| ) {
        if ( ! open(F, ">>$filename")) {
            print STDERR "Cannot open log file $filename for write\n$line\n";
        } else {
            flock(F, LOCK_EX);
            seek(F,0,2);
            print F "$line";
            flock(F, LOCK_UN);
            close F;
        }
    } else {
        print STDERR "$line";
    }
}##logline


=head2 pick_lang(hash)

 pick_lang( eng => "text in english",
            rus => "text in russian");

Chooses and returns a text for a current ePortal language.

=cut

############################################################################
sub pick_lang   {   #02/12/01 11:17
############################################################################
    my ($message, %hash);

    if (scalar @_ >= 2) {
        %hash = @_;
        $message = \%hash;
    } else {
        $message = shift;
    }

    if (! defined $message) {
        return;

    } elsif (ref($message) eq 'HASH') {
        # get current language
        my $lang = $ePortal->language;

        # If not found in the message then get first
        if (! exists $message->{$lang}) {
            $lang = (keys %$message)[0];
        }

        return $message->{$lang};

    } else {
        return $message;
    }
}##pick_lang



=head2 href( uri, key =E<gt> value, ...)

Constructs full URL with optional parameters.

I<uri> is filename or URI to some file.

I<key-value> pairs may be repeated. I<value> may be array ref.

Returns a string like I<uri?key=value&key=value>

=cut

############################################################################
sub href    {   #06/29/01 11:22
############################################################################
    my ($file, @params) = @_;
    my $href;

    while(scalar @params) {
        my($key, $value) = (shift(@params), shift(@params));
        if (ref ($value) eq 'ARRAY') {
            foreach my $v (@$value) {
                $href .= '&' if $href;
                $href .= "$key=" . ePortal::Utils::escape($v);
            }
        } else {
            $href .= '&' if $href;
            $href .= "$key=" . ePortal::Utils::escape($value);
        }
    }

    return "$file?$href";
}##href


=head2 plink(text, parameters, ...)

Constructs HTML code to make anchor like [link] (text in square brackets)

I<text> is text to show as link.

Other I<parameters> are passed directly to CGI::a() function. Most used
are:

 -href => 'http://server/file.htm'
 -href => href('file.htm', param1 => value1)
 -class => "someclass"
 -target => "_top"
 -title => "floating title"

=cut

############################################################################
sub plink   {   #07/27/01 12:56
############################################################################
    my $text = shift;
    my %opt = @_;

    if (ref($text) eq 'HASH') {
        $text = pick_lang($text);
    }

    #$opt{'-onMouseOver'} = "javascript: this.style = 'background-color : navy;';";
    #$opt{'-onMouseOut'}  = "this.style = 'background-color : white;';";

    my $html = CGI::span(
        { -class => "smallfont" },
        '[' . CGI::a(\%opt, $text) . ']'
        );

    if (defined wantarray) {
        return $html;
    } else {
        $ePortal->m->print( $html );
    }
}##plink

=head2 empty_table( param =E<gt> value )

Constructs HTML code to create empty table 100% width. A background of the
table is filled with 1 pixel in size transparent picture. Parameters passed
as hash are:

I<height> table height in pixels

I<bgcolor> HTML compatible color value

I<black> adjust background picture and color values to make the table
completly black

Returns HTML string in scalar of array context. If used in void contxet
then $m-E<gt>out() is used to output the string immediately .

=cut

############################################################################
sub empty_table {   #07/27/01 3:49
############################################################################
    my %p = @_;

    my $image = $p{black} ?
        "/images/ePortal/1px-black.gif" :
        "/images/ePortal/1px-trans.gif";

    $p{bgcolor} ||= $p{black}? "#000000" : undef;

    my %table_params = (
        -border => 0,
        -width => "100%",
        -cellspacing => 0,
        -cellpadding => 0);
    $table_params{-bgcolor} = $p{bgcolor} if $p{bgcolor};
    $table_params{-class} = $p{class} if $p{class};

    my $html = CGI::table(\%table_params,
        CGI::Tr({},
            CGI::td({}, img( src => $image, height => $p{height} ))
        )
    );

    if (defined wantarray) {
        return $html;
    } else {
        $ePortal->m->print( $html );
    }
}##empty_table


=head2 empty_tr( param =E<gt> value )

Contructs HTML code for empty row of table. Parameters passed as hash are:

I<height> height in pixels

I<colspan> make a cell as colspan. Used in multicolumn tables

I<bgcolor> HTML compatible color value

I<black> adjust all parameters to make the row completely black

Returns HTML string in scalar of array context. If used in void contxet
then $m-E<gt>out() is used to output the string immediately .

=cut

############################################################################
sub empty_tr    {   #07/27/01 3:49
############################################################################
    my %p = @_;

    my $image = $p{black} ?
        "/images/ePortal/1px-black.gif" :
        "/images/ePortal/1px-trans.gif";

    $p{bgcolor} ||= $p{black}? "#000000" : undef;

    my (%tr_params, %td_params);
    $tr_params{-bgcolor} = $p{bgcolor} if $p{bgcolor};
    $tr_params{-class} = $p{class} if $p{class};
    $td_params{-colspan} = $p{colspan} if $p{colspan};

    my $html = CGI::Tr(\%tr_params,
            CGI::td(\%td_params, img( src => $image, height => $p{height} ))
    );

    if (defined wantarray) {
        return $html;
    } else {
        $ePortal->m->print( $html );
    }
}##empty_tr


=head2 empty_td( param =E<gt> value )

Contructs HTML code for empty cell of table. Parameters passed as hash are:

I<height> height in pixels

I<width> width in pixels

I<colspan> make a cell as coluln span.

I<bgcolor> HTML compatible color value

I<black> adjust all parameters to make the row completely black

Returns HTML string in scalar of array context. If used in void contxet
then $m-E<gt>out() is used to output the string immediately .

=cut

############################################################################
# Function: empty_td
# Description: creates empty HTML table's row
# Parameters: hash with keys:
#   height => in pixels
#   width =>
#   colspan =>
#   bgcolor => HTML color value
#   black => shuld be the table all in black?
#   class =>
# Returns:
#   HTML string
############################################################################
sub empty_td    {   #07/27/01 3:49
############################################################################
    my %p = @_;

    my $image = $p{black} ?
        "/images/ePortal/1px-black.gif" :
        "/images/ePortal/1px-trans.gif";

    $p{bgcolor} ||= $p{black}? "#000000" : undef;
    my $html = '<td';
    foreach (qw/ bgcolor colspan width height class/) {
        $html .= qq{ $_="$p{$_}"} if defined $p{$_};
    }
    $html .= '>' . img( src => $image, height => $p{height} ) . '</td>';

#   my (%td_params);
#   $td_params{-bgcolor} = $p{bgcolor} if $p{bgcolor};
#   $td_params{-colspan} = $p{colspan} if $p{colspan};
#   $td_params{-width} = $p{width} if $p{width};
#   $td_params{-height} = $p{height} if $p{height};
#   $td_params{-class} = $p{class} if $p{class};

#   my $html = CGI::td(\%td_params, img( src => $image, height => $p{height} ));

    if (defined wantarray) {
        return $html;
    } else {
        $ePortal->m->print( $html );
    }
}##empty_td


=head2 img( param =E<gt> value )

Contructs HTML code for image tag. Parameters passed as hash are:

I<src> required. URI to image.

I<width>, I<height> if not passed then Image::Size is used for calculation
at runtime. These attributes are calculated only once for each apache
child. They are cached for speed.

I<alt> alternative text for the image

I<id> ID of the image

Some parameters are used to construct Link from the image:

I<href>, I<target>, I<title>, I<onClick> - they are self-expanatory, passed
to CGI::a() function.

Returns HTML string in scalar of array context. If used in void contxet
then $m-E<gt>out() is used to output the string immediately .

=cut

############################################################################
our %IMG_CACHE;
sub img {   #07/27/01 4:00
############################################################################
    my %p = @_;

    $p{width} = 1 if ($p{width} == 0 and $p{height});
    $p{height} = 1 if ($p{height} == 0 and $p{width});

    #
    # if width or height is not specified try calculate it from the
    # picture and store in cache. Elsewhere use specified or cached values
    # Do it only under an server

    if (defined $ENV{MOD_PERL} or defined $ENV{SERVER_SOFTWARE} ) {
        if ($p{width} || $p{height}) {
            # nothing
        } elsif (!exists $IMG_CACHE{ $p{src} }) {
            my $lookup_uri = eval {$ePortal->r->lookup_uri($p{src}) if $p{src};};
            if ($lookup_uri) {
                $IMG_CACHE{ $p{src} } = [Image::Size::attr_imgsize($lookup_uri->filename)];
            } else {
                $IMG_CACHE{ $p{src} } = [];
            }
            ($p{width}, $p{height}) = (@{$IMG_CACHE{ $p{src} }})[1,3];
        } else {
            ($p{width}, $p{height}) = (@{$IMG_CACHE{ $p{src} }})[1,3];
        }
    }

    my $img = CGI::img({
        -src => $p{src},
        -border => 0,
        $p{id}     ?    (-id     => $p{id}) : (),
        $p{style}  ?    (-style  => $p{style}) : (),
        $p{align}  ?    (-align  => $p{align}) : (),
        defined $p{alt}    ?   (-alt     => $p{alt}) : (),
        defined $p{title}  ?    (-title  => $p{title}) : (),
        defined $p{hspace} ?    (-hspace => $p{hspace}) : (),
        $p{onMouseDown} ?   (-onMouseDown => $p{onMouseDown}) : (),
        $p{onMouseOver} ?   (-onMouseOver => $p{onMouseOver}) : (),
        $p{onMouseOut}  ?   (-onMouseOut => $p{onMouseOut}) : (),
        $p{width} || $p{height} ?
            (-width  => $p{width}, -height => $p{height}) : (),
        });

        #
        # There is 2 ways to show picture: as link and as image

    my $html;
    if ($p{href} or $p{onClick}) {
        $html  = CGI::a({
            -href => $p{href},
            $p{onClick}?    (-onClick => $p{onClick}) : (),
            $p{target} ?    (-target => $p{target}) : (),
            $p{title} ?     (-title => $p{title}) : (),
        }, $img);
    } else {
        $html = $img;
    }

    if (defined wantarray) {
        return $html;
    } else {
        $ePortal->m->print( $html );
    }
}##img


############################################################################
# Function: icon_tool
# Description:
# Parameters:
# Returns:
#
############################################################################
sub icon_tool   {   #06/14/02 9:52
############################################################################
    my $menuname = shift;
    my $objid = shift;
    my $objid2 = shift;

    return img(
            src => '/images/ePortal/pmenu.gif',
            onMouseOver => "javascript:this.src='/images/ePortal/pmenu_f.gif';",
            onMouseOut => "javascript:this.src='/images/ePortal/pmenu.gif';",
            style => 'cursor:hand;',
            alt => 'PopupMenu',
            title => pick_lang(
                rus => "Íàæìèòå ñþäà ÷òîáû ïîÿâèëîñü ìåíþ",
                eng => "Click here for menu"),
            onMouseDown => "show_popup_menu(event, '$menuname', '$objid', '$objid2');" );
}##icon_tool




############################################################################
# Function: icon_access
# Description: make HTML code for icon
# Parameters:
#   Object
# Returns:
#   HTML code
#
############################################################################
sub icon_access {   #09/11/01 12:55
############################################################################
    my $obj = shift;
    my %p = @_;

    return if not ref $obj;
    return if ! UNIVERSAL::isa($obj,'ePortal::ThePersistent::ACL'); # ACL not supported
    return if ! $obj->acl_check('a');       # Admin privilege

    my $objid = $obj->id;
    my $objtype = ref $obj;
    $objtype =~ s/::View\d\d$//;        # Remove ::View subclassing
    return if ($objid == 0 or $objtype eq '');

    #my $href = href("/acl.htm", objid => $objid, objtype => $objtype);

    return img( $p{dialog}? (src => "/images/ePortal/dlg_acl.png") : (src => "/images/ePortal/access.gif"),
        href => "javascript:open_acl_window('$objid', '$objtype');",
        title => pick_lang(rus => "Èçìåíèòü ïðàâà äîñòóïà", eng => "ACL editor"));
}##icon_access

############################################################################
# Function: icon_delete
# Description: make HTML code for icon
# Parameters:
#   Object
# Returns:
#   HTML code
#
############################################################################
sub icon_delete {   #09/11/01 3:34
############################################################################
    my $obj = shift;
    my %p = Params::Validate::validate(@_, {
        objtype => {optional => 1},
        objid   => {optional => 1},
        done    => {optional => 1},
    });

    return if not ref $obj;
    return if UNIVERSAL::can($obj,'acl_check') and !$obj->acl_check('w');

    my $objtype = $p{objtype};
    if (!$objtype) {
        $objtype = ref $obj;
        $objtype =~ s/::View\d\d$//;        # Remove ::View subclassing
    }

    my $objid = $p{objid};
    if (!$objid) {
        $objid = [$obj->_id()];
    }

    # get back url
#    if ( ! $p{done} ) {
#        my %args = $ePortal->m->request_args;
#        delete $args{objid}; delete $args{objtype};
#        $p{done} = href($ePortal->r->uri, %args);
#    }

    my $href = href("/delete.htm", objid => $objid, objtype => $objtype, 
        $p{done} ? (done => $p{done}) : ());

    my %opt;
    # TODO: JAVA script doesn't work properly
    %opt = ( href => $href );

    return img( $p{dialog} ? (src => "/images/ePortal/dlg_delete.png") : (src => "/images/ePortal/trash.gif"),
        title => pick_lang(rus => "Óäàëèòü", eng => "Delete"),
        %opt);
}##icon_delete

############################################################################
# Function: icon_edit
# Description: make HTML code for icon
# Parameters:
#   Object
#   link_text to make not icon but text href
# Returns:
#   HTML code
#
############################################################################
sub icon_edit   {   #09/11/01 3:40
############################################################################
    my $obj = shift;
    my %p = @_;

    return if not ref $obj;
    return if UNIVERSAL::can($obj,'acl_check') and !$obj->acl_check('w');

    my $objid = $obj->id;
    my $objtype = ref $obj;
    $objtype =~ s/::View\d\d$//;        # Remove ::View subclassing

    if (!  $p{url}) {
        my %url = (
            'ePortal::App::MsgForum::MsgForum'      => '/forum/forum_admin.htm',
            'ePortal::App::MsgForum::MsgItem'       => '/forum/compose.htm',
            );

        if (not $p{url} = $url{$objtype} ) {
            throw ePortal::Exception::Fatal(
                -text => "Edit method for $objtype is not known");
        }
    }

    # get back url
#    if ( ! $p{done} ) {
#        my %args = $ePortal->m->request_args;
#        delete $args{$_} foreach (qw/objid objtype done/);
#        $p{done} = href($ePortal->r->uri, %args);
#    }

    my $href = href( $p{url}, objid => $objid, 
            $p{done}? (done => $p{done}) : ());

    if ($p{text}) {
        return plink($p{text}, -href => $href);
    } else {
        return img( src => "/images/ePortal/setup.gif",
                href => $href,
                title => pick_lang(rus => "Ðåäàêòèðîâàòü", eng => "Edit") );
    }
}##icon_edit

###########################################################
# Function: icon_export
# Description: make HTML code for icon
# Parameters:
#   Object
# Returns:
#   HTML code
#
############################################################################
sub icon_export {   #09/11/01 3:40
############################################################################
    my $obj = shift;

    return if not ref $obj;
    return if not $obj->acl_check('a');

    my $objtype = ref $obj;
    $objtype =~ s/::View\d\d$//;        # Remove ::View subclassing

    return img( src => "/images/ePortal/export.gif",
        title => pick_lang(rus => "Ýêñïîðò îáúåêòà â ôàéë", eng => 'Export to file'),
        href => href("/export/export.htm", objid => $obj->id, objtype => $objtype));
}##icon_export




=head2 filter_html($content)

Filters a content to cut some HTML tags like E<lt>HTMLE<gt>

Accept as parameter:

B<any text> - filters this text

B</path/filename> - reads this file and filters it

B<$m> - calls C<fetch_next()> and filters the output

=cut

############################################################################
sub filter_html {   #12/17/01 12:36
############################################################################
    my $source = shift;
    my ($fh, $body) = ();

    if ($source =~ m|^/|) { # file
        unless (defined ($fh = new FileHandle($source, "r"))) {
            return pick_lang(rus => "Íå ìîãó îòêðûòü ôàéë $source", eng => "Cannot open file $source");
        }

        $body = join '', $fh->getlines;
        $fh->close;

    } elsif (UNIVERSAL::isa($source, 'HTML::Mason::Request')) {
        my $component = $m->fetch_next;
        $body = $m->scomp($component) if $component;

    } else {
        $body = $source;
    }

    $body =~ s|.*<body[^>]*>(.*)</body.*|$1|ios;
    $body =~ s|<script.*</script>||iosg;
    return $body;
}##filter_html


############################################################################
# Function: filter_html_title
# Description:
# Parameters:
# Returns:
#
############################################################################
sub filter_html_title   {   #02/21/02 11:14
############################################################################
    my $file_path = shift;
    my $fh;

    unless (defined($fh = new FileHandle($file_path, "r"))) {
        return pick_lang(rus => "Íå ìîãó îòêðûòü ôàéë", eng => "Cannot open file");
    }
    my @lines;
    while (my $line = $fh->getline) {
        $line =~ tr/\r\n//d;
        push @lines, $line;
        last if $line =~ m[<(body|/title)]oi;
    }
    $fh->close;

    $line = join '', @lines;
    my ($title) = ($line =~ m[<title[^>]*>(.*)</title]oi);
    return $title;
}##filter_html_title

############################################################################
sub filter_txt  {   #12/17/01 12:40
############################################################################
    my $file_path = shift;
    my ($fh, $title, @body, $line);

    unless (defined ($fh = new FileHandle($file_path, "r"))) {
        return pick_lang(rus => "Íå ìîãó îòêðûòü ôàéë $file_path", eng => "Cannot open file $file_path");
    }

    # skip optional empty lines from the top of file. Get the first line as file title
    while( defined ($title = $fh->getline)) {
        $title =~ tr/\r\n//d;
        last if $title;
    }

    # Get the rest of the file
    while( defined ($line = $fh->getline)) {
        $line =~ tr/\r\n//d;
        push @body, $line;
    }
    $fh->close;


    return '<b>' . $title . "</b><p>\n" . join( "\n<p>", @body) . "<p>\n";
}##filter_text


############################################################################
sub filter_txt_title    {   #02/21/02 11:07
############################################################################
    my $file_path = shift;
    my $fh;

    unless (defined ($fh = new FileHandle($file_path, "r"))) {
        return pick_lang(rus => "Íå ìîãó îòêðûòü ôàéë $file_path", eng => "Cannot open file $file_path");
    }
    my $line = $fh->getline;
    $fh->close;

    $line =~ tr/\r\n//d;
    return $line;
}##filter_txt_title

############################################################################
sub filter_auto_title   {   #02/21/02 10:42
############################################################################
    my $file_path = shift;
    my ($filename) = ($file_path =~ m|/([^/]+)$|o);
    my $title;

    if (-d $file_path) {
        foreach my $comp_name ('index.htm', 'autohandler.mc') {
            my $comp_path = $ePortal->r->uri . "$filename/$comp_name";
            if ($ePortal->m->comp_exists($comp_path)) {
                my $comp = $ePortal->m->fetch_comp($comp_path);
                if ($comp->attr_exists("Title")) {
                    $title = $comp->attr("Title");
                    $title = pick_lang($title) if (ref($title) eq 'HASH');
                    last;
                }
            }
        }

        if ($title eq '' and -f "$file_path/index.htm") {
            $title = filter_html_title("$file_path/index.htm");
        }

    } elsif ($filename =~ /\.txt$/oi) {
        $title = filter_txt_title($file_path);
    } elsif ($filename =~ /\.html?$/oi) {
        $title = filter_html_title($file_path);
    } elsif ($filename =~ /\.doc$/oi) {
        $title = "Microsoft Word file";
    } elsif ($filename =~ /\.xl(w|s)$/oi) {
        $title = "Microsoft Excel file";
    }

    return $title;
}##filter_auto_title


############################################################################
# Function: filter_auto
# Description:
# Parameters:
# Returns:
#
############################################################################
sub filter_auto {   #02/21/02 1:46
############################################################################
    my $file_path = shift;
    my ($filename) = ($file_path =~ m|/([^/]+)$|o);

    if ($filename =~ /\.txt$/oi) {
        return filter_txt($file_path);

    } elsif ($filename =~ /\.html?$/oi) {
        return filter_html($file_path);

    } else {
        unless (defined ($fh = new FileHandle($file_path, "r"))) {
            return pick_lang(rus => "Íå ìîãó îòêðûòü ôàéë $file_path", eng => "Cannot open file $file_path");
        }

        while( my $line = $fh->getline) {
            $ePortal->m->print( $line );
        }
        $fh->close;

    }
}##filter_auto


############################################################################
# Function: HTML::Mason::Request::call_next_filtered
# Description:
# Parameters:
# Returns:
#
############################################################################
sub HTML::Mason::Request::call_next_filtered    {   #02/21/02 1:46
############################################################################
    my ($self, @p) = @_;

    if (-f $ePortal->r->filename) {
        return ePortal::Utils::filter_auto($ePortal->r->filename);
    } else {
        return $self->call_next(@p);
    }
}##HTML::Mason::Request::call_next_filtered


############################################################################
sub escape  {   #03/18/02 10:49
############################################################################
    my $str = shift;
    if ($Apache::Util::VERSION) {
        $str = Apache::Util::escape_uri($str);
    } else {
        $str =~ s/\%/%25/ogs;   # Percent FIRST!
        $str =~ s/\?/%3F/ogs;
        $str =~ s/\&/%26/ogs;
        $str =~ s/ /%20/ogs;
    }
    return $str;
}##escape


############################################################################
# Function: date_to_sql
# Description: Convert date string to SQL ready format
# Parameters:
# Returns:
#
############################################################################
sub date_to_sql {   #05/06/02 10:59
############################################################################
    my $date = shift;

    if ($date eq '?') {
        return '?';
    } elsif (! $date) {
        return 'NULL';
    } else {
        return join ('', reverse (split '\.', $date));
    }
}##date_to_sql





############################################################################
# Function: cstocs
# Description: Convert a cyrillic charset to another charset
# Parameters:
#   Source charset
#   Destination charset
#   a string
# Returns:
#
############################################################################
my %tab;
$tab{"KOI8"}="áâ÷çäå³öúéêëìíîïðòóôõæèãþûý\377ùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ";
$tab{"DOS"}="€‚ƒ„…ð†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢£¤¥ñ¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï";
$tab{"ISO"}="°±²³´µ¡¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕñÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîï";
$tab{"WIN"}="ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþ\377";
$tab{"VOL"}="ABVGDE¨ÆZIJKLMNOPRSTUFXC×ØW~Y'ÝÞßabvgde¸æzijklmnoprstufxc÷øw~y'ýþ\377";
$tab{"MAC"}="€‚ƒ„…Ý†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸàáâãäåÞæçèéêëìíîïðñòóôõö÷øùúûüýþß";
#        1234567890123456789012345678901234567890123456789012345678901234567890
############################################################################
sub cstocs {
############################################################################
    my ($Src, $Dst, $Buf) = @_;
    $Src = uc ($Src); $Src .= '8' if $Src eq 'KOI';
    $Dst = uc ($Dst); $Dst .= '8' if $Dst eq 'KOI';

    if ($Src eq 'UTF8') {
        require Unicode::Map8;
        require Unicode::String;
        my $map = Unicode::Map8->new("cp1251");
        $Buf = $map->to8 (Unicode::String::utf8 ($Buf)->ucs2);
        $Src = 'WIN';
    }

    if ($Dst eq 'UTF8') {
        require Unicode::Map8;
        require Unicode::String;
        eval "\$Buf =~ tr/$tab{$Src}/$tab{'WIN'}/";
        my $map = Unicode::Map8->new("cp1251");
        $Buf = $map->tou ($Buf)->utf8;
    } elsif ($Src ne $Dst) {
        eval "\$Buf =~ tr/$tab{$Src}/$tab{$Dst}/";
    }

    if ($Dst eq 'VOL') {
        $Buf =~s/¨/YO/go; $Buf =~s/Æ/ZH/go; $Buf =~s/×/CH/go;
        $Buf =~s/Ø/SH/go; $Buf =~s/Ý/E\'/go; $Buf =~s/Þ/YU/go;
        $Buf =~s/ß/YA/go; $Buf =~s/¸/yo/go; $Buf =~s/æ/zh/go;
        $Buf =~s/÷/ch/go; $Buf =~s/ø/sh/go; $Buf =~s/ý/e\'/go;
        $Buf =~s/þ/yu/go; $Buf =~s/\377/ya/go;
    }
    $Buf;
}




1;

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
