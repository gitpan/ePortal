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


package ePortal::Catalog;
    our $VERSION = '4.2';
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


############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{recordtype} ||= {
                label => {rus => 'Тип ресурса', eng => 'Resource type'},
                dtype => 'VarChar',
                maxlength => 64,
                fieldtype => 'popup_menu',
                values => ['link', 'group', 'text', 'textHTML', 'textpara', 'file'],
                default => 'link',
                labels => {
                    link  => {rus => 'Ссылка', eng => 'Link'},
                    group => {rus => 'Группа ресурсов', eng => 'Group of resources'},
                    text  => {rus => 'Текст как есть', eng => 'Preformatted text'},
                    textHTML  => {rus => 'Текст HTML', eng => 'HTML text'},
                    textpara  => {rus => 'Текст по параграфам', eng => 'Text with paragraphs'},
                    textline  => {rus => 'Строка это параграф', eng => 'A line is paragraph'},
                    file  => {rus => 'Файл', eng => 'File'},
                },
    };
    $p{Attributes}{parent_id} ||= {
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
                    while($current_parent and $obj->restore($current_parent)) {
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
    };
    $p{Attributes}{priority} ||= {};
    $p{Attributes}{title}    ||= {};
    $p{Attributes}{nickname} ||= {};
    $p{Attributes}{ts}       ||= {};
    $p{Attributes}{url} ||= {
                label => {rus => "Адрес URL", eng => "URL address"},
                dtype => 'Varchar',
                size => 64,
    };
    $p{Attributes}{memo} ||= {
            label => {rus => "Краткое описание", eng => "Short description"},
            dtype => 'Varchar',
            maxlength => 255,
            fieldtype => 'textarea',
    };
    $p{Attributes}{clicks} ||= {
            label => {rus => "Переходов", eng => "Clicks"},
            dtype => 'Number',
            default => 0,
    };
    $p{Attributes}{hits} ||= {
            label => {rus => "Обращений", eng => "Hits"},
            dtype => 'Number',
            default => 0,
    };
    $p{Attributes}{state} ||= {
        values => ['unknown', 'ok'],
        default => 'ok',
        #description => 'The state of attachment. unknown when actial object is not saved',
    };
    $p{Attributes}{text} ||= {
            label => {rus => 'Текст ресурса', eng => 'Text of resource'},
            dtype => 'VarChar',
            maxlength => 16777215,
            fieldtype => 'textarea',
            rows => 7,
            cols => 80,
    };
    $p{Attributes}{texttype} ||= {
                label => {rus => 'Формат текста', eng => 'Text format'},
                dtype => 'VarChar',
                maxlength => 64,
                fieldtype => 'radio_group',
                values => ['text', 'HTML', 'pre'],
                default => 'text',
                labels => {
                    pre   => {rus => 'Текст как есть', eng => 'Preformatted text'},
                    HTML  => {rus => 'Текст HTML', eng => 'HTML text'},
                    text  => {rus => 'Автоформат', eng => 'Autoformat'},
                },
    };
    $p{Attributes}{upload_file} ||= { type => 'Transient',};
    $p{Attributes}{xacl_write}  ||= {};
    $p{Attributes}{xacl_admin}  ||= {};

    $self->SUPER::initialize(%p);
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

#    if ($self->RecordType eq 'file') {
#        $self->Title( $self->Filename ) unless $self->Title;
#    }

    # Check title
    if ( ! $self->title ) {
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

    if ($self->RecordType eq 'file' and ! $self->Title) {
        my $att = new ePortal::Attachment;
    }    

    undef;
}##validate


############################################################################
sub delete  {   #06/18/2003 1:15
############################################################################
    my $self = shift;

    my $att = $self->Attachment;
    my $result = $self->SUPER::delete;

    while($result and $att) {
        $result += $att->delete;
        last if ! $att->restore_next;
    }

    return $result;
}##delete


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
    my $count = $self->dbh->selectrow_array("SELECT count(*) as cnt
            FROM Catalog WHERE recordtype != 'group' AND parent_id=?",
            undef, $self->id);

    return 0+$count;
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

    # I have to do it manualy to avoid ACL denial
    my $dbh = $self->dbh;
    
    # replace null to 0
    $dbh->do("UPDATE Catalog SET clicks=0 WHERE clicks is null AND id=?", undef, $self->id);
    
    # increment counter
    $dbh->do("UPDATE Catalog SET clicks=clicks+1 WHERE id=?", undef, $self->id);
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
    my $dbh = $self->dbh;
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
    return ($self->dbh->selectrow_array(
        "SELECT sum(hits) from Statistics WHERE catalog_id=? AND date=curdate()",
        undef, $self->id))[0];
}##HitsToday

############################################################################
sub VisitorsTotal   {   #12/24/02 2:27
############################################################################
    my $self = shift;
    return ($self->dbh->selectrow_array(
        "SELECT count(distinct visitor) from Statistics WHERE catalog_id=?",
        undef, $self->id))[0];
}##HitsToday

############################################################################
sub VisitorsToday   {   #12/24/02 2:27
############################################################################
    my $self = shift;
    return ($self->dbh->selectrow_array(
        "SELECT count(distinct visitor) from Statistics WHERE catalog_id=? AND date=curdate()",
        undef, $self->id))[0];
}##HitsToday


############################################################################
sub htmlSave    {   #06/16/2003 3:49
############################################################################
    my $self = shift;
    my $result = $self->SUPER::htmlSave(@_);
    if ($result) {
        my $old_att = $self->Attachment;

        my $att = new ePortal::Attachment(obj => $self);
        if ($att->upload(r => $ePortal->r)) {
            $old_att->delete if $old_att;   # delete old if exists and
                                            # new upload is successful
        }
    }
    return $result;
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
    my $exists = $newitem->restore( $p{nickname} );
    foreach (qw/ nickname title recordtype url memo /) {
        $newitem->value($_, $p{$_});
    }
    $newitem->parent_id( $iditem->id );
    $newitem->Priority( $p{priority} );
    $newitem->uid('admin');
    my $ret = $newitem->save;

    # Do not reset ACL and statistics on existing items
    if ( !$exists) {
        $newitem->Clicks(0);
        $newitem->Hits(0);
        $newitem->xacl_read(undef);
        $newitem->xacl_read('everyone') if $p{all_r};
        $newitem->xacl_read('registered') if $p{all_reg};

        $newitem->update;
    }

    return $exists ? 0 : 1;
}##AddCatalogItem

############################################################################
sub LastModified    {   #10/17/2003 3:42
############################################################################
    my $self = shift;
    
    return scalar $self->dbh->selectrow_array(
        "SELECT unix_timestamp(ts) from Catalog WHERE id=?",
        undef, $self->id);
}##LastModified

1;
