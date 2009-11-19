#!/usr/bin/perl -w
use strict;
$|++;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use HTML::Parser;
use URI;

{
  my $url = shift;
  my $ua = LWP::UserAgent->new;
  $ua->cookie_jar(HTTP::Cookies->new);
  my $response = $ua->request(GET $url);
  $response->is_success
    or die "Cannot get $url: ", $response->status_line, "\n";
  
  print <<'END';
use LWP::UserAgent;
use HTTP::Request::Common;
my $ua = LWP::UserAgent->new;
$ua->env_proxy;
END
  if ($ua->cookie_jar->as_string) { # they set cookies
    print 'use HTTP::Cookies; $ua->cookie_jar(HTTP::Cookies->new);', "\n";
    print '$ua->request(GET ', S($url), "); # to set cookies\n";
  }
  MyParser->dump_forms_for($response);
}

sub S {                         # perl stringify argument
  join ", ",
  map {
    local $_ = $_;
    s/([^ !#%-?A-~])/sprintf "\\x%02x", ord $1/ge;
      qq{"$_"};
  } @_;
}

BEGIN {                         # MyParser
  package MyParser;
  use base qw(HTML::Parser);
  *S = \&main::S;

  sub dump_forms_for {
    my $class = shift;
    my $self = $class->SUPER::new;
    my $response = shift;
    $self->{__PACKAGE__}{response} = $response;
    $self->parse($response->content);
    $self->eof();
  }

  sub start {                   # CALLBACK
    my $self = shift;
    my ($tag,$attr,$attrseq,$origtext) = @_;
    if ($tag eq "form") {
      $self->{__PACKAGE__}{in_form} = 1;
      $self->{__PACKAGE__}{fields} = [];
      my $url = URI->new_abs($attr->{action} || "",
                             $self->{__PACKAGE__}{response}->base)->as_string;
      $self->{__PACKAGE__}{invoke} = $url;
      return;
    }
    return unless $self->{__PACKAGE__}{in_form};
    if ($tag eq "input") {
      $self->dumptext;
      my $type = lc $attr->{type};
      my $name = $attr->{name}; $name = "" unless defined $name;
      my $value = $attr->{value}; $value = "" unless defined $value;
      push @{$self->{__PACKAGE__}{fields}}, [$name, $type, $value];
      return;
    }
    if ($tag eq "select") {
      $self->dumptext;
      my $name = $attr->{name};
      my $type = exists $attr->{multiple} ? "select multiple" : "select";
      $self->{__PACKAGE__}{in_select} = [$name, $type];
      return;
    }
    if ($tag eq "option") {
      $self->endoption;         # end previous one if needed
      my $selected = exists $attr->{selected} ? "selected" : "";
      my $value = $attr->{value}; $value = "" unless defined $value;
      $self->{__PACKAGE__}{in_option} = [$selected, $value];
      return;
    }
    if ($tag eq "textarea") {
      $self->dumptext;
      my $name = $attr->{name};
      $self->{__PACKAGE__}{in_textarea} = $name;
      return;
    }
    $self->{__PACKAGE__}{text} .= $origtext;
  }

  sub end {                     # CALLBACK
    my $self = shift;
    my ($tag, $origtext) = @_;
    return unless $self->{__PACKAGE__}{in_form};
    if ($tag eq "form") {
      delete $self->{__PACKAGE__}{in_form};
      $self->dumptext;
      my $url = $self->{__PACKAGE__}{invoke};
      print "\$ua->request(POST ",S($url),", [\n";
      for (@{$self->{__PACKAGE__}{fields}}) {
        if (ref $_) {
          my ($name, $type, $value) = @$_;
          print "  ", S($name), " => ", S($value), ", # $type\n";
        } else {
           # original text
          print "  # text ", S($_), "\n";
        }
      }
      print "],\n";
      print "  Referer => ", S($self->{__PACKAGE__}{response}->base), ",\n";
      print ");\n";
      return;
    }
    if ($tag eq "option") {
      $self->endoption;
      return;
    }
    if ($tag eq "select") {
      $self->endoption;
      delete $self->{__PACKAGE__}{in_select};
      return;
    }
    if ($tag eq "textarea") {
      my $name = delete $self->{__PACKAGE__}{in_textarea};
      my $text = delete $self->{__PACKAGE__}{text};
      push @{$self->{__PACKAGE__}{fields}}, [$name, "textarea", $text];
      return;
    }
    $self->{__PACKAGE__}{text} .= $origtext;
  }

  sub text {                    # CALLBACK
    my $self = shift;
    my ($text) = @_;
    return unless $self->{__PACKAGE__}{in_form};
    $self->{__PACKAGE__}{text} .= $text;
  }

  sub endoption {
    my $self = shift;
    return unless exists $self->{__PACKAGE__}{in_option};
    my ($name, $type) = @{$self->{__PACKAGE__}{in_select}};
    my ($selected, $value) = @{delete $self->{__PACKAGE__}{in_option}};
    my $text = delete $self->{__PACKAGE__}{text};
    $type .= " $selected" if $selected;
    $value = $text unless length $value;
    $type .= " (text ".S($text).")" unless $text eq $value;
    push @{$self->{__PACKAGE__}{fields}}, [$name, $type, $value];
  }

  sub dumptext {
    my $self = shift;
    my $text = delete $self->{__PACKAGE__}{text};
    if (defined $text and length $text) {
      push @{$self->{__PACKAGE__}{fields}}, $text;
    }
  }
}
