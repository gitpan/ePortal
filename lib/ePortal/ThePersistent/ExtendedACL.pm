#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2001 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Revision: 3.7 $
# $Date: 2003/04/24 05:36:52 $
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/ExtendedACL.pm,v 3.7 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# ACL (Access Control List) support for ThePersistent classes.
# For ACL to work the following attributes must exists:
#   owner varchar(64)
#   acl varchar(4000)
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::ExtendedACL - Extended Access Control Lists base
class for persistent objects.

=head1 SYNOPSIS

B<ePortal::ThePersistent::ExtendedACL> implements Access Control Lists
(ACL functions) for ThePersistent classes.


=head1 METHODS

=cut

package ePortal::ThePersistent::ExtendedACL;
    use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = sprintf '%d.%03d', q$Revision: 3.7 $ =~ /: (\d+).(\d+)/;

    use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang

    use Params::Validate qw/:types/;
    use Error qw/:try/;
    use ePortal::Exception;



=head2 initialize()

Overloaded method. Adds ACL specific attributes C<uid> and C<xacl_read> to 
the object.

Additional parameters:

=over 4

=item * XACL_Attributes

Additional XACL attributes. Attribute data type is selected automatically.

 xacl_attribute => description

=item * XACL_ON_PARENT

Do not add special attributes C<uid> and C<xacl_read>.

=item * xacl_uid_field

Redefine standard C<uid> attribute name to something another.

=item * xacl_read_field

Redefine standard C<xacl_read> attribute name to something another.

=item * drop_admin_priv

By default Admin may SELECT everything from database. If this is not 
desired then pass this parameter.

  drop_admin_priv => 1

=back

=cut

############################################################################
sub initialize  {   #04/25/02 10:29
############################################################################
    my ($self, %p) = @_;

    # save for future some special field names
    foreach (qw/XACL_Attributes XACL_ON_PARENT
            xacl_uid_field xacl_read_field
            drop_admin_priv/) {
        $self->{$_} = $p{$_};
        delete $p{$_};
    }

    # Call SUPER initialization function. No additional parameters!
    $self->SUPER::initialize(%p);

    if ( ref($self->{XACL_Attributes}) eq 'HASH') {
        foreach my $xacl (keys %{$self->{XACL_Attributes}}) {
            $self->add_attribute( $xacl => {
                        dtype => 'VarChar',
                        maxlength => 64,
                        order => 8,
                        label => $self->{XACL_Attributes}->{$xacl},
                        fieldtype => 'xacl',
            });
        }
    }

    unless ($self->{XACL_ON_PARENT}) {
        if (! $self->attribute('uid') ) {
            $self->add_attribute( uid => {
                        dtype => 'VarChar',
                        maxlength => 64,
                        order => 8,
                        label => {rus => 'Автор', eng => 'Author'},
            });
        }
        if (! $self->attribute('xacl_read') ) {
            $self->add_attribute( xacl_read => {
                        dtype => 'VarChar',
                        maxlength => 64,
                        order => 8,
                        label => {rus => 'Доступ по чтению', eng => 'Read access'},
                        fieldtype => 'xacl',
            });
        }
    }

}##initialize




############################################################################
sub insert  {   #07/04/00 1:18
############################################################################
    my $self = shift;

    if (! $self->xacl_check_insert) {
        throw ePortal::Exception::ACL(
            -operation => 'insert',
            -object => $self);
    }

    # create default ACL set for new object. Maybe overloaded
    $self->set_acl_default;

    $self->SUPER::insert(@_);
}##insert


############################################################################
sub delete  {   #09/19/00 4:00
############################################################################
    my $self = shift;

    die "ExtendedACL does not support delete(id)" if @_;

    if ( ! $self->xacl_check_delete() ) {
        throw ePortal::Exception::ACL(
            -operation => 'delete',
            -object => $self);
    }

    $self->SUPER::delete();
}##delete


############################################################################
sub update  {   #10/27/00 8:28
############################################################################
    my ($self, @param) = @_;

    throw ePortal::Exception::ACL( -operation => 'update', -object => $self)
        if ! $self->xacl_check_update();

    $self->SUPER::update(@param);
}##update


=head2 xacl_where()

Construct SQL WHERE clause based on C<uid> and C<xacl_read> fields.

=cut

############################################################################
sub xacl_where  {   #11/05/02 4:31
############################################################################
    my $self;

    $self = shift @_ if (ref($_[0]));
    my $xacl_field = shift || 'xacl_read';
    my $uid_field = shift || 'uid';
    my ($XACL_WHERE, @BINDS);

    if ($self and $self->{xacl_uid_field}) {
        $uid_field = $self->{xacl_uid_field};
    }
    if ($self and $self->{xacl_read_field}) {
        $xacl_field = $self->{xacl_read_field};
    }

    my $username = $ePortal->username;
    if ($ePortal->isAdmin and !$self->{drop_admin_priv}) {
        # no restrictions for Admin
    } elsif ($username eq '') {
        # restrictions for anonyous user
        $XACL_WHERE = "($xacl_field='everyone')";
    } else {
        my @groups = $ePortal->user->member_of;
        my $groups_placeholder = join(',', map('?', @groups));
        $XACL_WHERE = "(($xacl_field='everyone') OR ($xacl_field='registered') OR
            ($xacl_field='uid:$username') OR ($xacl_field='owner' AND $uid_field=?)";
        push @BINDS, $username;
        if (@groups) {
            $XACL_WHERE .= " OR ($xacl_field in ($groups_placeholder))";
            push @BINDS, map("gid:$_", @groups);
        }
        $XACL_WHERE .= ')';
    }

    return ($XACL_WHERE, @BINDS);
}##xacl_where

=head2 xacl_check()

Base XACL checking function. Omit using it in end packages, use 
xacl_check_xxx() for specific XACL processing.

=cut

############################################################################
sub xacl_check  {   #11/05/02 4:31
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    # Check for existance of xacl_field
    throw ePortal::Exception::Fatal(-text => "xacl_check(" . ref($self) . "): attribyte $xacl_field not exists")
        if ! $self->attribute($xacl_field);
    
    my $xacl_value = $self->value($xacl_field);
    my $username = $ePortal->username;

    # Easy checks
    return 1 if $ePortal->isAdmin; # Administrator
    return 1 if $xacl_value eq 'everyone';
    return 0 if ($username eq '');           # not registered user

    # User dependent checks
    # The user is registered
    if ($xacl_value eq '') {
        return 0;

    } elsif ($xacl_value eq 'admin') {
        return 0;   # admin check done before

    } elsif ($xacl_value eq 'registered') {
        return 1;

    } elsif ($xacl_value eq 'owner') {
        return $username eq $self->value('uid') ? 1 : 0;

    } elsif ($xacl_value =~ /^uid:(.*)/o) {
        return $username eq $1 ? 1 : 0;

    } elsif ($xacl_value =~ /^gid:(.*)/o) {
        my $gid = $1;
        my @groups = $ePortal->user->member_of;
        foreach (@groups) { return 1 if ($_ eq $gid); }
        return 0;
    }
    
    throw ePortal::Exception::Fatal(-text => "xacl_check: unsupported value in $xacl_field: $xacl_value");
}##xacl_check

=head2 xacl_check_read()

C<read> access. This method is not used inside of C<ExtendedACL> but may be 
used in overloaded packages.

Inside of C<ExtendedACL> read access is restricted with SQL WHERE clause.

=cut

############################################################################
sub xacl_check_read {   #04/16/03 3:20
############################################################################
    my $self = shift;
    my $xacl_field = shift || 'xacl_read';

    return $self->xacl_check($xacl_field);
}##xacl_check_read



=head2 xacl_check_delete()

C<delete> current object right.

Check C<xacl_delete> attribute if exists or C<xacl_check_update()>. 

Owner of the object always may delete the object. This is addition to 
C<xacl_check()>

=cut


############################################################################
sub xacl_check_delete   {   #11/11/02 3:48
############################################################################
    my $self = shift;
    my $xacl_field = shift || 'xacl_delete';

    if ($self->attribute($xacl_field)) {
        return 1 if $ePortal->username and ($ePortal->username eq $self->uid);
        return $self->xacl_check($xacl_field);
    } else {
        return $self->xacl_check_update;
    }
}##xacl_check_delete



=head2 xacl_check_update()

C<update> or C<modify> current object right.

Check C<xacl_write> attribute. 

Owner of the object always may modify the object. This is addition to 
C<xacl_check()>

=cut

############################################################################
sub xacl_check_update   {   #11/11/02 3:48
############################################################################
    my $self = shift;
    my $xacl_field = shift || 'xacl_write';

    return 1 if $ePortal->username and ($ePortal->username eq $self->uid);
    return $self->xacl_check($xacl_field);
}##xacl_check_update



=head2 xacl_check_admin()

C<change ACL> on current object right.

Check C<xacl_admin> attribute if exists or C<xacl_check_update()>. 

Owner of the object always may change ACL if xacl field eq 'owner'. Author 
of the object does not get xacl_admin rights automatically.

=cut

############################################################################
sub xacl_check_admin    {   #02/26/03 9:09
############################################################################
    my $self = shift;
    my $xacl_field = shift || 'xacl_admin';

    if ($self->attribute($xacl_field)) {
        # If the attribute xacl_admin exists then strictly follow it
        # do not allow every author to change access rights, derive them from parent
        #
        #return 1 if $ePortal->username and ($ePortal->username eq $self->uid);
        return $self->xacl_check($xacl_field);
    } else {
        return $self->xacl_check_update;
    }
}##xacl_check_admin


=head2 xacl_check_insert()

Actually checks parent with C<xacl_check_children()>.

The object is obligatory to have a parent or overwrite this method.

=cut

############################################################################
sub xacl_check_insert    {   #01/03/01 3:20
############################################################################
    my $self = shift;
    my $xacl_field = shift;

    # check sysacl OR parent
    my $parent = $self->parent;

    throw ePortal::Exception::DataNotValid(-text => pick_lang(
            rus => "Родительский об'ект не определен", 
            eng => "Unknown parent object"))
        if ! ref($parent);

    throw ePortal::Exception::Fatal(-text => "Object doesn't support xacl_check_children method",
            -object => $parent)
        if ! UNIVERSAL::can($parent, 'xacl_check_children');
        
    return $parent->xacl_check_children($xacl_field);
}##xacl_check_insert


=head2 xacl_check_children()

ACL check for inserting children objects. Default to xacl_check_update(). 

This method is called from C<xacl_check_insert()> of a children object.

=cut

############################################################################
sub xacl_check_children {   #04/16/03 3:40
############################################################################
    my $self = shift;
    my $xacl_field = shift;
    return $self->xacl_check_update($xacl_field);
}##xacl_check_children




=head2 restore_where()

Adds some WHERE conditions to comply with ACL.

=cut

############################################################################
sub restore_where   {   #09/05/01 4:42
############################################################################
    my ($self, %p) = @_;

    if (! $self->{XACL_ON_PARENT} and ! $p{XACL_ON_PARENT}) {
        my ($xacl_where, @xacl_binds) = $self->xacl_where;
        $self->add_where( \%p, $xacl_where, @xacl_binds);
    }
    delete $p{XACL_ON_PARENT};

    return $self->SUPER::restore_where(%p);
}##restore_where




=head2 set_acl_default()

Installs default ACL values for the object during insert(). The default
behavior is to take most of ACL attributes from parent object. Other ACL 
attributes initialized to 'owner'

This method updates C<uid> if not defined.

This method does not updates the object. C<insert()> does it.

=cut

############################################################################
sub set_acl_default {   #10/01/01 11:17
############################################################################
    my ($self, $sysacl_name) = Params::Validate::validate_pos(@_,
            { type => OBJECT, isa => 'ePortal::ThePersistent::ExtendedACL' },
            { type => SCALAR, optional => 1});

    my $parent = $self->parent;

    # save it to preserve overwriting. Install it last
    my $uid = $self->attribute('uid')
        ? $self->value('uid') || $ePortal->username
        : undef;

    # Get default ACL from Parent object
    if ($parent and UNIVERSAL::can($parent, 'set_acl_from_obj')) {
        $self->set_acl_from_obj($parent);
    }

    # Install uid and default xacl
    $self->uid( $uid ) if $self->attribute('uid') and defined $uid;
    foreach my $i ($self->attributes) {
        next unless $i =~ /^xacl_/o;
        $self->value($i, 'owner') unless $self->value($i);
    }
}##set_acl_default




=head2 set_acl_from_obj()

Copy all ACL attributes from C<$source> object.

This method does not updates the object. Call C<update()> manually!

=cut

############################################################################
sub set_acl_from_obj    {   #08/12/02 3:59
############################################################################
    my ($self, $source) = Params::Validate::validate_pos(@_,
        { type => OBJECT, isa => 'ePortal::ThePersistent::ExtendedACL' },
        { type => OBJECT, isa => 'ePortal::ThePersistent::ExtendedACL' });

    foreach ($self->attributes) {
        if (/^xacl_/o and $source->attribute($_)) {
            $self->SUPER::value($_, $source->value($_)) if $source->value($_);
        }
    }
    1;
}##set_acl_from_obj


############################################################################
sub htmlSave    {   #02/26/03 9:57
############################################################################
    my $self = shift;
    my %ARGS = @_;

    if ($self->check_id) {  # object restored. UPDATing it
        if (! $self->xacl_check_update) {
            throw ePortal::Exception::ACL(
                -operation => 'update',
                -object => $self);
        }
        if (! $self->xacl_check_admin) {
            if (exists $ARGS{uid} or grep(m/^xacl_/, keys %ARGS)) {
                throw ePortal::Exception::ACL(
                    -operation => 'admin',
                    -object => $self);
            }
        }
    } else {    # ID not valid, INSERTing object
                # xacl_check_insert() will turn during insert()
    }    

    return $self->SUPER::htmlSave(%ARGS);
}##htmlSave


=head2 xacl_set_r()

Recursively copy ExtendedACL attributes from this object to all childrens

=cut

############################################################################
sub xacl_set_r  {   #04/01/03 3:47
############################################################################
    my $self = shift;

    my $C = $self->children;
    return if ! ref $C;
    while($C->restore_next) {
        if (UNIVERSAL::can($C, 'set_acl_from_obj')) {
            $C->set_acl_from_obj($self);
            $C->update;
            $C->xacl_set_r;
        }
    }
}##xacl_set_r

1;


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
