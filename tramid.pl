#!/usr/bin/perl

# tramid
#
# Copyleft (Ↄ) 2012, Lorraine Lee, all rights reversed.
#
# Script to transpose a midi file from the command line
#
# Requires midicsv and csvmidi,
# which are free, public doman programs,
# available at http://www.fourmilab.ch/webtools/midicsv/
#
# Usage is:
#
#  tramid <input file> <output file> <number of semitones>
#
# The first two arguments are midi files,
# the first of which exists and the second of which does not.
# The third argument is an integer,
# positive to transpose up,
# negative to transpose down.

my @csv=`midicsv $ARGV[0]`;


open OUTFILE, "| csvmidi > @ARGV[1]" or die "can't fork: $!";

foreach (@csv) {
 @fields=split(/,\s*/,$_);
 if ($fields[2] =~ m/Note_o/) {
  $fields[4]=$fields[4]+$ARGV[2];
 }
 if ($fields[2] =~ m/Key_signature/) {
  $fields[3]=$fields[3]+2*$ARGV[2];
  while ($fields[3]<-7) {
   $fields[3]=$fields[3]+12;
  }
  while ($fields[3]>7) {
   $fields[3]=$fields[3]-12;
  }
 }
 print OUTFILE join(', ',@fields);
}

close(OUTFILE);


