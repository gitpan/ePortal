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
%# "Include file" section
%#-----------------------------------------------------------------------------

<% $text %>

%#=== @metags init =========================================================
<%init>
	my $section = $ARGS{section};
	my $file = $section->params;
	my $text;

	if (! $m->comp_exists($file)) {
		$text = pick_lang( rus => "Файл $file не существует",
				eng => "File $file doesn't exists");
 	} else {
 		$text = eval { $m->scomp($file); };
 		if ($@) {
			warn $@;
			$text = pick_lang( rus => "Ошибка при чтении файла $file",
					eng => "Error while reading file $file");
		}
  }


</%init>


%#=== @metags attr =========================================================
<%attr>
def_title => { eng => "Include file", rus => "Включение файла"}
def_params => "filename.htm"
</%attr>




%#=== @METAGS Help ====================================================
<%method Help>

<b>Section parameter</b>: File to include (path relative to component root)
</%method>
