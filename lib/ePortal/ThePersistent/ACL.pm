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
# $Header: /home/cvsroot/ePortal/lib/ePortal/ThePersistent/ACL.pm,v 3.4 2003/04/24 05:36:52 ras Exp $
#
#----------------------------------------------------------------------------
# ACL (Access Control List) support for ThePersistent classes.
# For ACL to work the following attributes must exists:
# 	owner varchar(64)
# 	acl varchar(4000)
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::ACL - Access Control Lists base class for
persistent objects.

=head1 SYNOPSIS

B<ePortal::ThePersistent::ACL> implements Access Control Lists (ACL)
functions) for ThePersistent classes.


=head1 METHODS

=cut

package ePortal::ThePersistent::ACL;
	use base qw/ePortal::ThePersistent::Support/;
	our $VERSION = sprintf '%d.%03d', q$Revision: 3.4 $ =~ /: (\d+).(\d+)/;

	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang

    use Params::Validate qw/:types/;
    use Error qw/:try/;
    use ePortal::Exception;

=head2 initialize()

Overloaded method. Adds ACL specific attributes to the object.

=cut

############################################################################
sub initialize	{	#04/25/02 10:29
############################################################################
	my ($self, @p) = @_;

	$self->SUPER::initialize(@p);

    if (! $self->attribute('uid') ) {
		$self->add_attribute( uid => {
					dtype => 'VarChar',
					maxlength => 64,
					order => 8,
					label => {rus => 'Доступ хозяин', eng => 'Owner name'},
		});
		$self->add_attribute( gid => {
					dtype => 'VarChar',
					maxlength => 64,
					order => 8,
					label => {rus => 'Доступ Группа', eng => 'Group name'},
		});
		$self->add_attribute( gid_r => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Группа (R)', eng => 'Group Read access'},
		});
		$self->add_attribute( gid_w => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Группа (W)', eng => 'Group Write access'},
		});
		$self->add_attribute( gid_a => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Группа (A)', eng => 'Group Admin access'},
		});
		$self->add_attribute( all_r => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Все (R)', eng => 'Everyone Read access'},
		});
		$self->add_attribute( all_w => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Все (W)', eng => 'Everyone Write access'},
		});
		$self->add_attribute( all_a => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Все (A)', eng => 'Everyone Admin access'},
		});
		$self->add_attribute( all_reg => {
					dtype => 'YesNo',
					label => {rus => 'Доступ Только зарег.', eng => 'Registered users only'},
		});
    }

}##initialize



=head2 ACL_attributes(prefix)

Returns array in array context or comma separated string for all ACL
specific attributes. This is static function but may be called in OOP
manner.

If C<prefix> given than every attribute is prefixed

 ACL_attributes('t') => 't.uid, t.gid, ...'

=cut

############################################################################
sub ACL_attributes	{	#04/25/02 10:33
############################################################################
	my $prefix = shift;
	$prefix = shift if ref($prefix);
	my @a = (qw/ uid gid gid_r gid_w gid_a all_r all_w all_a all_reg /);
	if ($prefix) {
		@a = map ($prefix . '.' . $_, @a)
	}

	return wantarray ? @a : join(',', @a);
}##ACL_attributes



=head2 value(...)

There is no way to modify ACL attributes with standard ->value() function.
Use set_acl() instead. This overloaded function just makes ACL attributes
read-only.

=cut

############################################################################
sub value   {   #06/19/02 2:39
############################################################################
    my ($self, $attribute, @data) = @_;
    $attribute = lc($attribute);

    # Return read-only value for known ACL attributes
    foreach (ACL_attributes()) {
        if ($_ eq $attribute) {
            @data = ();
            last;
        }
    }

    # Call standard method for all other attributes
    $self->SUPER::value($attribute, @data);
}##value



=head2 insert()

Overloaded function. Calls acl_check_insert() to check access for object
creation.

Installs default ACL with set_acl_default().

=cut

############################################################################
sub insert	{	#07/04/00 1:18
############################################################################
	my $self = shift;

	# --------------------------------------------------------------------
	# Работа с ACL. Объект получает хозяина и доступ к объекту по умолчанию
	# берется либо с родителя объекта либо доступ имеет только хозяин.
	#
    throw ePortal::Exception::ACL( -operation => 'insert', -object => $self)
        if ! $self->acl_check_insert;

	# create default ACL set for new object. Maybe overloaded
    $self->set_acl_default;

	$self->SUPER::insert(@_);
}##insert


=head2 delete()

Calls acl_check('w') for access.

=cut

############################################################################
sub delete	{	#09/19/00 4:00
############################################################################
	my $self = shift;

	die "Recursive delete does not allow ID as parameter" if @_;

    throw ePortal::Exception::ACL( -operation => 'delete', -object => $self)
        if ! $self->acl_check('w');

	$self->SUPER::delete();
}##delete



=head2 restore_where()

Adds some WHERE conditions to comply with ACL.

=cut

############################################################################
sub restore_where	{	#09/05/01 4:42
############################################################################
  	my ($self, %p) = @_;

	if ((ref($self) eq 'ePortal::ThePersistent::ACL') || UNIVERSAL::isa($self,'ePortal::ThePersistent::ACL')) {		# ACL supported
		my $username = $ePortal->username;
        my $table = $self->{Table};
        $table .= '.' if $table;

		if ($ePortal->isAdmin and !$self->{drop_admin_priv}) {
		} elsif ($username eq '') {
            $self->add_where( \%p, $table.'all_r<>0 AND '.$table.'all_reg=0');
		} else {
            my $ACL_WHERE = '('.$table.'all_r<>0 OR '.$table.'uid=?';
			my @groups = $ePortal->user->member_of;
            my @binds = ($username, @groups);
			if (scalar @groups) {
                $ACL_WHERE .= ' OR ('.$table.'gid_r<>0 AND '.$table.'gid in (' .
                    join(',', map('?', @groups)) . '))';
			}
			$ACL_WHERE .= ')';
            $self->add_where( \%p, $ACL_WHERE, @binds);
		}
    }

	return $self->SUPER::restore_where(%p);
}##restore_where



=head2 restore_next()

Additional but not paranoid checks for ACL

=cut

############################################################################
sub restore_next	{	#10/19/01 10:35
############################################################################
	my $self = shift;

	if (UNIVERSAL::isa($self,'ePortal::ThePersistent::ACL') ) {
		# ACL check done by WHERE clause of SQL
		return $self->SUPER::restore_next(@_);

	} else {
		# This object support ACL but via parent. It's not possible
		# to implement ACL checks in WHERE clause of SQL
		my $result;
		while ($result = $self->SUPER::restore_next(@_)) {
			last if $self->acl_check('r');
        }
		return $result;
	}
}##restore_next


=head2 update()

Calls acl_check('w') for access.

=cut

############################################################################
sub update	{	#10/27/00 8:28
############################################################################
    my ($self, @param) = @_;

    throw ePortal::Exception::ACL( -operation => 'update', -object => $self)
        if ! $self->acl_check('w');

    $self->SUPER::update(@param);
}##update


=head2 acl_check(right)

Checks the object for ACL with C<right>. C<right> may be r|w|a.

=cut

############################################################################
# Function: acl_check
# Description: Check object permissions
# Parameters:
# 	right letter: r|w|a
# Returns: 	[1|0]
#
############################################################################
sub acl_check	{	#09/05/01 3:38
############################################################################
	my $self = shift;
	my $right = shift;

	if (! UNIVERSAL::isa($self,'ePortal::ThePersistent::ACL') ) {	# no ACL for this object
		my $parent = $self->parent;
		return defined $parent ? $parent->acl_check($right) : 1;
    }
	return 0 if ($right ne 'r') and ($right ne 'w') and ($right ne 'a');
	return 1 if $self->value('all_'.$right) and $self->value('all_reg') == 0; # ALL users
	return 1 if $ePortal->isAdmin;			 # Administrator

	my $username = $ePortal->username;
	return 1 if $username and $self->uid eq $username;	# object owner
	return 1 if $username and $self->value('all_'.$right); # ALL for registered users

	# check permission for group
	if ($username) {
		my @groups = $ePortal->user()->member_of();
		my $group = lc($self->gid);
		return 1 if $self->value('gid_'.$right) and grep({$_ eq $group} @groups);
	}

	return 0;
}##acl_check




=head2 acl_check_insert(system_acl_name)

Checks parent of the object for C<acl_check('w')> or
C<sysacl_check(system_acl_name)>

=cut

############################################################################
sub acl_check_insert	{	#01/03/01 3:20
############################################################################
	my $self = shift;
	my $sysaclname = shift;

	return 1 if $ePortal->isAdmin;

    # check sysacl OR parent
    my $result = 0;
    my $parent = $self->parent;

    if (defined $sysaclname) {
        $result ||= $ePortal->sysacl_check($sysaclname, 'w');
    }
    if (defined $parent) {
        $result ||= $parent->acl_check('w');
	}
    return $result if $result;


    # Log negative results
    logline('debug', 'acl_check_insert for ', ref($self),
		exists($self->{Data}->{id}) ? ':'. $self->id : '',  ' is NO');
	0;
}##acl_check_insert


=head2 set_acl_default()

Installs default ACL values for the object during insert(). The default
behavior is to take ACL from parent.

This method updates C<uid> if not defined and set C<all_r> to 1.

This method does not updates the object. C<insert()> does it.

=cut

############################################################################
sub set_acl_default {   #10/01/01 11:17
############################################################################
    my ($self, $sysacl_name) = Params::Validate::validate_pos(@_,
            { type => OBJECT, isa => 'ePortal::ThePersistent::ACL' },
            { type => SCALAR, optional => 1});

    my $parent = $self->parent;

    # save it to preserve overwriting. Install it last
    my $uid = $self->value('uid') || $ePortal->username;

    # Set to default '1'. Parent may overwrite it
    $self->set_acl( all_r => 1 );

    # Get default ACL from Parent object
    if ($parent and UNIVERSAL::isa($parent,'ePortal::ThePersistent::ACL')) {
        $self->set_acl_from_obj($parent);

        # If parent does not exists but SystemACL name given
#    } elsif ($sysacl_name) {
#        my $sa = new ePortal::SystemACL;
#        if ($sa->restore($sysacl_name)) {
#            $self->set_acl_from_obj($sa);
#        }
    }

    # Install uid
    $self->set_acl( uid => $uid ) if defined $uid;
}##set_acl_default





=head2 set_acl()

Modifies ACL values for the object. This is the only way to modify ACL.

Parameter is a hash

 set_acl(uid => username, gid => groupname, all_r => 1)

set_acl() modifies only stated as parameters attributes. Others are stay
unchanged.

This method does not updates the object. Call C<update()> manually!

=cut

############################################################################
sub set_acl {   #06/19/02 3:00
############################################################################
    my ($self, %p) = @_;

    foreach ($self->ACL_attributes) {
        if (exists $p{$_}) {
            $self->SUPER::value($_, $p{$_});
        }
    }
    1;
}##set_acl



=head2 set_acl_from_obj($source)

Copy all ACL attributes from C<$source> object.

This method does not updates the object. Call C<update()> manually!

=cut

############################################################################
sub set_acl_from_obj    {   #08/12/02 3:59
############################################################################
    my ($self, $source) = Params::Validate::validate_pos(@_,
        { type => OBJECT, isa => 'ePortal::ThePersistent::ACL' },
        { type => OBJECT, isa => 'ePortal::ThePersistent::ACL' });

    foreach ($self->ACL_attributes) {
        $self->SUPER::value($_, $source->value($_));
    }
    1;
}##set_acl_from_obj


=head2 set_acl_r()

The same as C<set_acl()> but does this recursive on the object and its
children.

This method UPDATES the object. Call C<update()> manually!

=cut

############################################################################
sub set_acl_r   {   #06/19/02 3:08
############################################################################
    my ($self, %p) = @_;

    my $count = 0;
    my $children = $self->children;
    if (ref($children) eq 'ARRAY') {
        foreach my $child ( @{$children} ) {
            $count += $child->set_acl(%p);
        }
    } elsif ( UNIVERSAL::isa($children,'ePortal::ThePersistent::Base') ) {
        while ($children->restore_next) {
            $count += $children->set_acl_r(%p);
            $children->update;
        }
    }

    $count += $self->set_acl(%p);
    $self->update;

    logline('debug', "Changed ACL recursively on $count objects");
    return $count;
}##set_acl_r



1;


=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
