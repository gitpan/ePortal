#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.4 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/Catalog.pm,v 3.4 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------


package ePortal::Catalog;
    our $VERSION = sprintf '%d.%03d', q$Revision: 3.4 $ =~ /: (\d+).(\d+)/;
    use base qw/ePortal::ThePersistent::ExtendedACL/;

    use ePortal::Utils;
    use ePortal::Global;
    use Params::Validate qw/:types/;

    # --------------------------------------------------------------------
    # Catalog setup section
    #

    our $SECONDS_BETWEEN_HITS = 5;  # Ignore hits from one cvisitor within this period
    our $MAX_DATES_SHOW = 4;        # A number of distinct dates to keep
    our $MAX_MONTH_SHOW = 2;        # A number of distinct months to keep statistics


    # Declare $attributes as our so link_edit_type.htm may use it
    our $attributes = {
        id => {     type => 'ID',           # ID, Pe (default)
                    dtype => 'Number',      # Data type (Varchar as default)
                    auto_increment => 1,
        },
        recordtype => {
                    label => {rus => 'Тип ресурса', eng => 'Resource type'},
                    dtype => 'VarChar',
                    maxlength => 64,
                    fieldtype => 'popup_menu',
                    values => ['link', 'group', 'text', 'textHTML', 'textpara', 'file'],
                    labels => {
                        link  => {rus => 'Ссылка', eng => 'Link'},
                        group => {rus => 'Группа ресурсов', eng => 'Group of resources'},
                        text  => {rus => 'Текст как есть', eng => 'Preformatted text'},
                        textHTML  => {rus => 'Текст HTML', eng => 'HTML text'},
                        textpara  => {rus => 'Текст по параграфам', eng => 'Text with paragraphs'},
                        textline  => {rus => 'Строка это параграф', eng => 'A line is paragraph'},
                        file  => {rus => 'Файл', eng => 'File'},
                    },
        },
        parent_id => {
                    label => {rus => "Входит в состав", eng => "A part of"},
                    dtype => 'Number',
                    maxlength => 11,
                    fieldtype => 'popup_menu',
                    popup_menu => sub {
                        my $self = shift;
                        my (@values, %labels);
                        my $tab = '&nbsp' x 2;

                        # Walk through parents up to top object
                        my $current_parent = $self->parent_id;
                        my $obj = new ePortal::Catalog;
                        while($obj->restore($current_parent)) {
                            unshift @values, $obj->id;
                            $labels{ $obj->id } = $obj->Title;
                            $current_parent = $obj->parent_id;
                        }

                        # do indentation
                        my $level = 1;
                        foreach (@values) {
                            $labels{$_} = $tab x $level++ . $labels{$_};
                        }

                        # load siblings of me and siblings of parent
                        my @parents_to_load;
                        push(@parents_to_load, $values[$#values]);      # this is ID of my parent (siblings of me)
                        push(@parents_to_load, $values[$#values-1]) if $#values >= 0; # siblings of parent
                        push(@parents_to_load, $values[$#values-2]) if $#values >= 1;
                        push(@parents_to_load, 0) if $#values <= 1;     # top level containers

                        foreach my $p (@parents_to_load) {
                            my $obj = new ePortal::Catalog;
                            $obj->restore_where(parent_id => $p, recordtype => 'group');
                            ITEM: while($obj->restore_next) {
                                next ITEM if $obj->id == $self->id;
                                foreach (@values) { next ITEM if $obj->id == $_; }
                                push @values, $obj->id;
                                $labels{ $obj->id } = $tab x $level . $obj->Title;
                            }
                            $level --;
                        }

                        # Top level
                        unshift @values, 0;
                        $labels{0} = pick_lang(rus => "-Начало каталога-", eng => "-Top of catalogue-");

                        return (\@values, \%labels);
                    },
        },
        %ePortal::FieldDomain::priority,
        %ePortal::FieldDomain::title,
        %ePortal::FieldDomain::nickname,
        url => {
                    label => {rus => "Адрес URL", eng => "URL address"},
                    dtype => 'Varchar',
                    size => 64,
        },
        %ePortal::FieldDomain::ts,
        memo => {
                label => {rus => "Описание", eng => "Description"},
                dtype => 'Varchar',
                maxlength => 255,
                fieldtype => 'textarea',
        },
        clicks => {
                label => {rus => "Переходов", eng => "Clicks"},
                dtype => 'Number',
                maxlength => 11,
                default => 0,
        },
        hits => {
                label => {rus => "Обращений", eng => "Hits"},
                dtype => 'Number',
                maxlength => 11,
                default => 0,
        },
        text  => {
                label => {rus => 'Текст ресурса', eng => 'Text of resource'},
                dtype => 'VarChar',
                maxlength => 16777215,
                fieldtype => 'textarea',
                rows => 20,
        },
        filename => {
                label => { rus => 'Загружен файл', eng => 'Uploaded file'},
                dtype => 'Varchar',
                #fieldtype => 'upload',
        },
        upload_file => {
                type => 'Transient',
                label => { rus => 'Загрузить файл', eng => 'Upload a file'},
                dtype => 'Varchar',
                fieldtype => 'upload',
        },
    };

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my $self = shift;

    $self->SUPER::initialize(Attributes => $attributes,
        XACL_Attributes => {
            xacl_write => pick_lang(rus => "Доступ по записи", eng => "Write access"),
            xacl_admin => pick_lang(rus => "Изменение прав", eng => "Change ACL"),
        });
}##initialize

############################################################################
sub xacl_check_insert   {   #04/01/03 3:01
############################################################################
    my $self = shift;

    my $parent = $self->parent;
    if (!$parent) {
        return $ePortal->isAdmin;   # only Admin may create top level 
                                    # Catalog objects
    } else {    
        return $self->SUPER::xacl_check_insert;
    }
}##xacl_check_insert


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    if ($self->RecordType eq 'file') {
        $self->Title( $self->Filename ) unless $self->Title;
    }

    # Check title
    unless ( $self->title ) {
        return pick_lang(rus => "Не указано наименование", eng => 'No name');
    }

    # Check Parent_id
    $self->parent_id(undef) if $self->parent_id == 0;
    if (defined $self->parent_id) {
        my $dummy = new ePortal::Catalog;
        unless($dummy->restore( $self->parent_id )) {
            return "Parent not found";
        }
    }

    # Check URL for existance
    if ($self->RecordType eq 'link' and ! $self->URL) {
        return pick_lang(rus => "Не указан URL для ресурса", eng => "No URL given");
    }

    if ($self->RecordType eq 'text' and ! $self->Text) {
        return pick_lang(rus => "Текст ресурса пуст", eng => "Resource text is empty");
    }

    undef;
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # parent_id cannot be 0, it may be NULL
    $p{parent_id} = undef if exists $p{parent_id} and $p{parent_id} == 0;

    # default ORDER BY clause
    $p{order_by} = 'recordtype,priority,title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::Catalog;
    if ($C->restore($self->parent_id)) {
        return $C;
    } else {
        return undef;
    }
}##parent



############################################################################
sub children    {   #06/17/02 11:11
############################################################################
    my $self = shift;
    my $C = new ePortal::Catalog;
    $C->restore_where(parent_id => $self->id);
    return $C;
}##children


############################################################################
# Function: Records
# Description: How many records are in this group
# Parameters:
# Returns:
#
############################################################################
sub Records {   #06/19/02 10:47
############################################################################
    my $self = shift;

    return undef unless $self->RecordType eq 'group';

    my $C = new ePortal::Catalog;
    my $count = $C->restore_where(
            count_rows => 1,
            parent_id => $self->id, where => "recordtype != 'group'"  );

#    my $count=0;
#    my $children = $self->children;
#    while($children->restore_next) {
#        $count ++ if $children->RecordType eq 'link';
#    }
    return $count;
}##Records


############################################################################
# Function: value
# Description:
# Parameters:
# Returns:
#
############################################################################
sub value   {   #06/19/02 10:59
############################################################################
    my($self, $attribute, @data) = @_;

    $attribute = lc($attribute);  ### attributes are case insensitive ###

    if ($attribute eq 'parent_id') {
        if (@data and $data[0] == 0) {
            $data[0] = undef;
        }
    }

    $self->SUPER::value($attribute, @data);
}##value



############################################################################
# Function: ClickTheLink
# Description: User clicks a link
# Parameters: ID of Catalog 'link' object
# Returns: new location URL
#
############################################################################
sub ClickTheLink    {   #07/09/02 9:14
############################################################################
    my $self = shift;
    my $go = shift;

    return undef if (! $self->restore($go) );

    # I have to do it manualy to avoid ACL denial
    my $dbh = $self->_get_dbh;
    # replace null to 0
    $dbh->do("UPDATE Catalog SET clicks=0 WHERE clicks is null AND id=?", undef, $self->id);
    # increment counter
    $dbh->do("UPDATE Catalog SET clicks=clicks+1 WHERE id=?", undef, $self->id);

    if ($self->RecordType eq 'group') {
        return href('/catalog/index.htm', group => $self->id);

    } elsif ($self->RecordType eq 'file') {
        return href('/catalog/download.htm/'.$self->Filename, link => $self->id);

    } elsif ($self->RecordType eq 'link') {
        return $self->URL;

    } elsif ($self->RecordType =~ /^text/) {
        return href('/catalog/showtext.htm', link => $self->id);
    }

    return undef;
}##ClickTheLink



############################################################################
# Function: HitTheLink
# Description: Count hits for the link
############################################################################
sub HitTheLink  {   #12/24/02 1:56
############################################################################
    my $self = shift;
    my $CatalogID = shift;

    # Two ways:
    # 1. The Catalog object is restored
    # 2. I get Catalog ID to restore
    my $valid = undef;
    if (defined($CatalogID)) {
        $valid = $self->restore($CatalogID);
    } else {
        $valid = $self->check_id();
    }
    if (! $valid) {
        logline('error', "HitTheLink: catalog object is not found $CatalogID");
        return;
    }

    # I do it with natural SQL for speed reason
    my $dbh = $self->_get_dbh;
    my $visitor = eval { $ePortal->r->connection->remote_ip } . ':' . $ePortal->username;

    # Count hits only if SECONDS_BETWEEN_HITS secs past
    my $seconds_past = $dbh->selectrow_array("SELECT unix_timestamp() - unix_timestamp(ts)
            FROM Statistics WHERE catalog_id=? AND date=curdate() AND visitor=?",
            undef, $self->id, $visitor);

    if (! defined($seconds_past)) { # record not found
        $dbh->do("INSERT INTO Statistics (catalog_id, visitor, hits, date)
                                   VALUES(?, ?, 1, curdate())", undef,
                                   $self->id, $visitor);
    } elsif ($seconds_past > $SECONDS_BETWEEN_HITS) {   # Add hit
        $dbh->do("UPDATE Statistics SET hits=hits+1 WHERE catalog_id=? AND date=curdate() AND visitor=?",
            undef, $self->id, $visitor);
    } else {    # Do not add hit, change timestamp
        $dbh->do("UPDATE Statistics SET hits=hits WHERE catalog_id=? AND date=curdate() AND visitor=?",
            undef, $self->id, $visitor);
        return;
    }

    # Count Hits in Catalog object
    $dbh->do("UPDATE Catalog SET Hits=Hits+1 WHERE id=?", undef, $self->id);

}##HitTheLink

############################################################################
sub HitsToday   {   #12/24/02 2:27
############################################################################
    my $self = shift;
    return ($self->_get_dbh->selectrow_array(
        "SELECT sum(hits) from Statistics WHERE catalog_id=? AND date=curdate()",
        undef, $self->id))[0];
}##HitsToday

############################################################################
sub VisitorsTotal   {   #12/24/02 2:27
############################################################################
    my $self = shift;
    return ($self->_get_dbh->selectrow_array(
        "SELECT count(distinct visitor) from Statistics WHERE catalog_id=?",
        undef, $self->id))[0];
}##HitsToday

############################################################################
sub VisitorsToday   {   #12/24/02 2:27
############################################################################
    my $self = shift;
    return ($self->_get_dbh->selectrow_array(
        "SELECT count(distinct visitor) from Statistics WHERE catalog_id=? AND date=curdate()",
        undef, $self->id))[0];
}##HitsToday

############################################################################
# Function: htmlSave
# Description:
# Parameters:
# Returns:
#
############################################################################
sub htmlSave    {   #08/16/02 9:28
############################################################################
    my $self = shift;
    my %ARGS = @_;

    if ($ARGS{recordtype} eq 'file') {
        my $upload = $ePortal->r->upload;
        if ( $upload ) {
            # Get filename
            my $filename = $upload->filename;
            $filename =~ s|.*[/\\]||;       # remove trailing slash

            if ($upload->size > $ePortal->max_allowed_packet) {  # 1Meg MySQL soft limit
                throw ePortal::Exception::DataNotValid(
                        -text => pick_lang(rus => "Файл слишком большой", eng => "File too big"),
                        -object => $self);
            }

            # Get the file
            my $fh = $upload->fh;
            my $buffer = undef;
            while(my $line = <$fh>) {
                $buffer .= $line;
            }

            if ($filename and $buffer) {
                $self->Filename($filename);
                $self->Text($buffer);
            }
        }

        # Remove 'file' parameter. We managed it
        delete $ARGS{upload_file};
        delete $ARGS{text};
    }

    $self->SUPER::htmlSave(%ARGS);
}##htmlSave


############################################################################
# Function: ClearStatistics
# Description: Clear all statistics
#  This is statis function not method
############################################################################
sub ClearStatistics {   #12/25/02 2:51
############################################################################
    my $self = shift;
    my $dbh = $ePortal->DBConnect();

    $dbh->do("TRUNCATE TABLE Statistics");
    $dbh->do("UPDATE Catalog SET Hits=0, Clicks=0");
}##ClearStatistics


############################################################################
# Add a catalog item
sub AddCatalogItem  {   #12/15/02 3:44
############################################################################
    my $self = shift;
    my (%p) = Params::Validate::validate_with(
        params => \@_,
        spec => {
            nickname   => {type => SCALAR},
            title      => {type => SCALAR},
            recordtype => {type => SCALAR, default => 'link'},
            parent_id  => {type => SCALAR, optional => 1},
            url        => {type => SCALAR, optional => 1},
            memo       => {type => SCALAR, optional => 1},
            all_r      => {type => BOOLEAN, default => 1},
            all_reg    => {type => BOOLEAN, default => 0},
            priority   => {type => SCALAR, default => 5},
        });

    my $newitem = new ePortal::Catalog;
    my $iditem  = new ePortal::Catalog;

    # looking for parent_id
    if (defined $p{parent_id} ) {
        if ( ! $iditem->restore( $p{parent_id} )) {
            # parent catalog item not found
            logline('error', "Cannot find Catalog item with nickname: $p{parent_id}");
            return undef;
        }
    }

    # We trying to upgrade existing items
    $newitem->restore( $p{nickname} );
    foreach (qw/ nickname title recordtype url memo /) {
        $newitem->value($_, $p{$_});
    }
    $newitem->parent_id( $iditem->id );
    $newitem->Priority( $p{priority} );
    $newitem->Clicks(0);
    $newitem->Hits(0);
    $newitem->uid('admin');
    my $ret = $newitem->save;

    $newitem->xacl_read(undef);
    $newitem->xacl_read('everyone') if $p{all_r};
    $newitem->xacl_read('registered') if $p{all_reg};

    $newitem->update;

    return 1;
}##AddCatalogItem

1;
