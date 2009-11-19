#! /usr/bin/perl -w 

use strict;

use English;
use Getopt::Long;
use Pod::Usage;
use Carp;
use IO::File;
use URI;
use LWP;
use WWW::Mechanize;
use HTTP::Cookies;

$::TT_ACCOUNT_MGMT_URL = "https://66.208.8.211/myaccount/acclogin.asp?glo=totaltalk";
$::TT_TRIGGER = "http://66.208.8.211/webcall/default.asp?modename=totaltalk";

$::VERBOSE = 0;

sub main () {

  #
  # Process commandline arguments.
  #

  my ($o_help, $o_man, $o_verbose, 
      $o_tt_fullname, $o_tt_email, $o_tt_account, $o_tt_changeonly,
      $o_tt_callback, $o_tt_triggernum, $o_tt_sec_pin,
      $o_tt_dest);

  GetOptions('help|?'          => \$o_help,
	     'man'             => \$o_man,
	     'verbose'         => \$o_verbose,
	     'changeonly'      => \$o_tt_changeonly,
	     'fullname=s'      => \$o_tt_fullname,
	     'email=s'         => \$o_tt_email,
	     'account=s'       => \$o_tt_account,
	     'callback=s'      => \$o_tt_callback,
	     'triggernumber=s' => \$o_tt_triggernum,
	     'security|pin=s'  => \$o_tt_sec_pin,
	     'destination=s'   => \$o_tt_dest,
	    )
    or pod2usage(2);
  $#ARGV == -1 or pod2usage(2);	# no extra args

  pod2usage(1) if $o_help;
  pod2usage(-exitstatus => 0, -verbose => 2) if $o_man;

  # required arguments
  pod2usage(1) if (!$o_tt_fullname && !$o_tt_email) && $o_tt_callback;
  pod2usage(1) if !$o_tt_triggernum && !$o_tt_changeonly;
  pod2usage(1) if $o_tt_callback && !$o_tt_sec_pin;

  $::VERBOSE = 1 if $o_verbose;

  if ($o_tt_callback) {
    change_callback($o_tt_account, $o_tt_fullname, $o_tt_email, 
		    $o_tt_sec_pin, $o_tt_callback)
      or croak "can't change callback";
  }

  if (!$o_tt_changeonly) {
    trigger_callback($o_tt_triggernum, $o_tt_dest) 
      or croak "can't trigger callback";
  }
}

sub change_callback ($$$$$) {
  my ($account, $fullname, $email, $pin, $new_callback) = @_;

  $email = "" if $fullname;	# just a precaution

  my $browser = LWP::UserAgent->new;

  my $agent = WWW::Mechanize->new();
  $agent->cookie_jar(HTTP::Cookies->new);

  $agent->get( $::TT_ACCOUNT_MGMT_URL );

  # login page
  $agent->form(1);
  $agent->field('account', $account);
  $agent->field('name',    $fullname);
  $agent->field('email',   $email);
  $agent->click();

  $agent->follow_link(text => "EDIT ACCOUNT");

  # login into edit account
  $agent->form(1);
  $agent->field('mypin', $pin);
  $agent->click();

  $agent->follow_link(text => "- callback");

  # change callback
  $agent->form(1);
  $agent->field('callback', $new_callback);
  $agent->click();

  1;
}

sub trigger_callback ($$) {
  my ($trigger, $dest) = @_;

  my $agent = WWW::Mechanize->new();
  $agent->cookie_jar(HTTP::Cookies->new);

  # makes an object representing the URL
  $agent->get( $::TT_TRIGGER );

  $agent->form(1);
  $agent->field('trigger', $trigger);
  $agent->field('DialOut', $dest);
  $agent->click();

  print "submitted request to call $dest, trigger=$trigger\n" if $::VERBOSE;
  1;
}

main();

1;

__END__
=head1 NAME

totaltalk-callback.pl - total-talk callback manager

=head1 SYNOPSIS

totaltalk-callback.pl [options]

 Options:

   -help                  brief help message

   -man                   full documentation

   -verbose               be more verbose

   -fullname <fullname>   full name, used for login

   -email <email>

   -callback <cb>

   -trigger <trigger#>

   -security|pin <pin>

   -destination <dest>

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-verbose>

Makes bgallery a bit more verbose.

=back

=head1 DESCRIPTION

B<This program> will cause total-net to generate a callback, and change 
callback number if nessesary.

... more info forthcoming ...

=cut
