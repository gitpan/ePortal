%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<%perl>
  my %args = $m->request_args;

#
#=== Default navigator ======================================================
#

my %NAV = (
  title => pick_lang(rus => "�������� ��������������: ", eng => "Admin's home: "),
  description => pick_lang(rus => '� ������� �������� ��������� ePortal.', eng => 'ePortal setup home page'),
  url => '/admin/index.htm',
  items => [ qw/ users groups other/ ],

  users => {
    title => pick_lang(rus => '������������', eng => 'Users'),
    description => pick_lang(rus => '������ � �������������� ePortal', eng => 'Administer users of ePortal'),
    items => [qw/users_list user_new/],
  },
  users_list => {
    title => pick_lang(rus => '������', eng => 'List'),
    description => pick_lang(rus => '������ �������������', eng => 'List of users'),
    url => '/admin/users_list.htm',
  },
  user_new => {
    title => pick_lang(rus => '����� ������������', eng => 'New user'),
    description => pick_lang(rus => '����� ������������', eng => 'New user'),
    url => '/admin/users_edit.htm?objid=0',
  },

  groups => {
    title => pick_lang(rus => '������ �������������', eng => 'Groups of users'),
    description => pick_lang(rus => '������ � �������� ������������� ePortal', eng => 'Administer groups of users of ePortal'),
    items => [qw/groups_list group_new/],
  },
  groups_list => {
    title => pick_lang(rus => '������', eng => 'List'),
    description => pick_lang(rus => '������ ����� �������������', eng => 'List of groups of users'),
    url => '/admin/groups_list.htm',
  },
  group_new => {
    title => pick_lang(rus => '����� ������', eng => 'New group'),
    description => pick_lang(rus => '����� ������ �������������', eng => 'New group of users'),
    url => '/admin/groups_edit.htm?objid=0',
  },

  other => {
    title => pick_lang(rus => '������', eng => 'Other'),
    description => pick_lang(rus => '������ ������� �����������������', eng => 'Other administrative tasks'),
    items => [qw/CronJob_list statistics/],
  },
  CronJob_list => {
    title => pick_lang(rus => '������������� �������', eng => 'Periodic jobs'),
    description => pick_lang(rus => '������ ������������� ������� � ����������', eng => 'List of periodic jobs'),
    url => '/admin/CronJob_list.htm',
  },
  statistics => {
    title => pick_lang(rus => '����������', eng => 'Statistics'),
    description => pick_lang(rus => '���������� ������ ePortal �������', eng => 'Statistics of ePortal'),
    url => '/admin/statistics.htm',
  },
  %ARGS);
</%perl>

<& /navigator.mc, %NAV &>

