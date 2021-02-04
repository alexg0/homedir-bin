#!/usr/bin/perl

for (<>) {
  chomp;
  print "$_\n" if (-f $_);
}
