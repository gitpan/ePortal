#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::PageSection - definition for a section of PageView.

=head1 SYNOPSIS

ePortal::PageSection used to store information about available sections for
PageView.

=head1 METHODS

=cut

package ePortal::PageSection;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ExtendedACL/;

	use ePortal::Global;
	use ePortal::Utils;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{params} ||= {
        label => {rus => 'Параметры секции', eng => 'Section parameters'},
        size => 60,
        # description => 'There may be a few sections with one template',
        };
    $p{Attributes}{width} ||= {
        label => {rus => 'Ширина секции', eng => 'Section width'},
        fieldtype => 'popup_menu',
        values => [ qw/N W/ ],
        labels => {
            N => {rus => 'узкая', eng => 'narrow'},
            W => {rus => 'широкая', eng => 'wide'},
        },
        };
    $p{Attributes}{url} ||= {
        label => {rus => 'URL для заголовка', eng => 'URL for section title'},
        size => 60,
        #description => 'URL for section caption',
        };
    $p{Attributes}{component} ||= {
        label => {rus => 'Файл компоненты', eng => 'Component file name'},
        fieldtype => 'popup_menu',
        values => \&ComponentNames,
        #description => 'filename of mason component',
        };
    $p{Attributes}{memo} ||= {};

    $self->SUPER::initialize(%p);
}##initialize




=head2 ComponentNames()

Returns arrayref of filenames of available components in PageView's
sections directory (default is /pv/sections/*.mc)

=cut

############################################################################
sub ComponentNames	{	#10/09/01 11:25
############################################################################
	my $self = shift;
    my @files = $ePortal->m->interp->resolver->glob_path('/pv/sections/*.mc');
    foreach (@files) {
        $_ =~ s|^.*/||g;    # remove dir path
    }

	return [ sort @files ];
}##ComponentNames


=head2 LoadDefaults($component_filename)

Loads default values for all attributes of the section from on-disk mason
component when creating new PageSection. Default values specified as mason
attributes

 <%attr>
 def_title => "Component title"
 def_width => "W"
 def_params => "default parameters"
 def_url => "http://www.server/
 def_memo => "this is some memo of the section"
 </%attr>

=cut

############################################################################
sub LoadDefaults	{	#10/09/01 2:08
############################################################################
	my $self = shift;
	my $comp_file = shift;

    my $m = $ePortal->m;
    $self->component( $comp_file );

	return unless $m->comp_exists("/pv/sections/$comp_file");
	my $c = $m->fetch_comp("/pv/sections/$comp_file");

	foreach (qw/title width params url memo/) {
        if ( $c->attr_exists("def_$_")) {
            my $v = $c->attr("def_$_");
            $v = pick_lang($v) if ref($v) eq 'HASH';
            $self->value($_, $v );
        }
	}
}##LoadDefaults


=head2 content($section)

Loads specific Mason component and produces HTML content for a section.

B<section> is ePortal::UserSection object. The function need it because it
may keep some settings in SetupInfo private attribute.

Returns HTML text

=cut

############################################################################
sub content	{	#10/12/01 2:33
############################################################################
	my $self = shift;
	my $section = shift;

	my $m = $HTML::Mason::Commands::m;
	my $content;

	my $component_file = "/pv/sections/" . $self->component;
	if (! $m->comp_exists( $component_file)) {
        logline('error', "PageView section file $component_file not exists");
#       $content = pick_lang(
#           rus => "Компонент $component_file не найден",
#           eng => "Cannot load $component_file");
#        return $content;
        return;
	}

	my $comp = $m->fetch_comp( $component_file);
	$content = $m->scomp( $component_file, section => $section );
	return $content;
}##content


=head2 Setupable()

Check is the section has setup method? Availability of setup method
checking via section's component. The component must have a method "Setup".

Returns: Boolean

=cut

############################################################################
sub Setupable	{	#10/12/01 2:40
############################################################################
	my $self = shift;
    my $m = $ePortal->m;
	my $component_file = "/pv/sections/" . $self->component;

    return 0 if not $self->check_id;
	return 0 if not $m->comp_exists( $component_file);

	my $comp = $m->fetch_comp( $component_file);
	return $comp->method_exists("Setup");
}##Setupable


=head2 delete()

Overloaded function. Also deletes linked UserSection objects.

=cut

############################################################################
sub delete	{	#10/15/01 11:32
############################################################################
	my $self = shift;

    my $dbh = $self->dbh();
	$dbh->do("DELETE FROM UserSection WHERE ps_id=?", undef, $self->id);

	$self->SUPER::delete();
}##delete

############################################################################
sub xacl_check_insert   {   #04/17/03 11:18
############################################################################
    my $self = shift;
    return $ePortal->isAdmin;
}##xacl_check_insert

sub xacl_check_update { $ePortal->isAdmin; }

1;


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
