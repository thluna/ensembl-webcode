package EnsEMBL::Web::Object::User;

use strict;
use warnings;
no warnings "uninitialized";
use CGI qw(escape);
use CGI::Cookie;

use EnsEMBL::Web::Object;
use EnsEMBL::Web::Factory::User;

our @ISA = qw(EnsEMBL::Web::Object);


#------------------- ACCESSOR FUNCTIONS -----------------------------

sub user_name { return $_[0]->Obj->{'user_name'}; }
sub email     { return $_[0]->Obj->{'email'}; }
sub password  { return $_[0]->Obj->{'password'}; }
sub org       { return $_[0]->Obj->{'org'}; }

sub get_user_id {
  my $self = shift;
  my $user_id = $ENV{'ENSEMBL_USER_ID'};

  return $user_id;
}

sub get_user_by_id    { return $_[0]->web_user_db->getUserByID($_[1]); }
sub get_user_by_email { return $_[0]->web_user_db->getUserByEmail($_[1]); }
sub get_user_by_code  { return $_[0]->web_user_db->getUserByCode($_[1]); }
sub get_user_privilege  { return $_[0]->web_user_db->getUserPrivilege($_[1], $_[2], $_[3]); }

sub reset_password {
  my ($self, $email) = shift;
  return $self->web_user_db->resetPassword($email);
}

sub validate_user { 
  my ($self, $email, $password) = @_;
  return $self->web_user_db->validateUser($email, $password);
}

sub set_cookie {
  my $self = shift;
  return $self->web_user_db->setUserCookie;
}


sub save_user {
  my ($self, $record) = @_;
  my $result;
  my %details = %{$record};
  if ($details{'user_id'}) { # saving updates to an existing item
    $result = $self->web_user_db->updateUserAccount($record);
  }
  else { # inserting a new item into database
    $result = $self->web_user_db->createUserAccount($record);
  }
  return $result;
}

sub set_password { return $_[0]->web_user_db->resetPassword($_[1]); }

sub get_members { return $_[0]->web_user_db->getMembers($_[1]); } 

sub save_bookmark {
  my ($self, $user_id, $url, $title) = @_;
  return $self->web_user_db->saveBookmark($user_id, $url, $title);
}

sub get_bookmarks { return $_[0]->web_user_db->getBookmarksByUser($_[1]); }
sub delete_bookmarks { return $_[0]->web_user_db->deleteBookmarks($_[1]); }

sub get_groups_by_user { return $_[0]->web_user_db->getGroupsByUser($_[1]); }
sub get_groups_by_type { return $_[0]->web_user_db->getGroupsByType($_[1]); }
sub get_all_groups { return $_[0]->web_user_db->getAllGroups; }

1;
