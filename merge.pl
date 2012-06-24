#!/usr/bin/perl

# notes.pl
#
# Copyleft (Ↄ) 2012, Lorraine Lee, all rights reversed.
#
# Make a list of note events in a midi file.
#
# Requires midicsv and csvmidi,
# which are free, public doman programs,
# available at http://www.fourmilab.ch/webtools/midicsv/
#
# Usage is:
#
#  notes.pl <input file>
#
# List goes to stdout.


my @csv=`midicsv $ARGV[0]`;



my %events=();
my @lines=();
my %active=();
my @notes=();
my @empty=();
my $lino=0; # line number

my $mintrack=999;
my $minchan=999;

foreach (@csv) {
 my @fields=split(/\s*,\s*/,$_);
 unshift(@fields,$lino);
 push(@lines,\@fields);
 $track=$fields[1];
 $timeindex=$fields[2];
 $command=$fields[3];
 $channel=$fields[4];
 $pitch=$fields[5];
 $velocity=$fields[6];
 if (($command eq 'Note_on_c') && $velocity>0) { # start-of-note event detected
  $mintrack=($track<$mintrack)?$track:$mintrack;
  $minchan=($channel<$minchan)?$channel:$minchan;
  if (!exists($active{$pitch})) { # initialize list of notes on this pitch, if none already
   $active{$pitch}=[];
  }
  $foo=$active{$pitch}; # add reference to this note-on event to list of notes for this pitch
  push(@$foo,[$lino,$track,$timeindex,$channel,$pitch]); # store line number, track number, channel number; indexed by pitch
 }
 if ((($command eq 'Note_on_c') && $velocity==0) || ($command eq 'Note_off_c')) { # end-of-note event detected
  $foo=$active{$pitch};
  $indx=0;
  foreach (@$foo) {
   @goo=@$_;
   if ($goo[1] == $track && $goo[3] == $channel) { # does this note end match this note start?
    push(@notes,[$goo[0],$lino,$track,$goo[2],$timeindex,$channel,$goo[4]]); # add line numbers for note start and end events to notes array
    splice @$foo,$indx,1; # remove from list of active notes
   }
   $indx+=1;
  }
 }
 $lino+=1;
}

# sort @notes array
# see http://www.misc-perl-info.com/perl-sort.html#smmc

@notes = sort {
 $a->[3] <=> $b->[3] || # sort by start time
 $a->[4] <=> $b->[4] || # then by end time
 $a->[6] <=> $b->[6] || # then by pitch
 $a->[2] <=> $b->[2] || # then by track
 $a->[5] <=> $b->[5];   # then by channel
} @notes; 

# remove redundant notes:

$indx=0;
foreach (@notes) {
 @goo=@$_;
 if ($goo[3]==$stime && $goo[4]==$etime && $goo[6]==$pitch) {
  splice @notes,$indx,1;
  $lines[$goo[0]]=0; # remove line at which redundant note starts
  $lines[$goo[1]]=0; # remove line at which redundant note ends
 }
 $stime=$goo[3];
 $etime=$goo[4];
 $pitch=$goo[6];
 $indx+=1;
}

# print preliminary tracks

$line=shift(@lines);
@foo=@$line;
shift(@foo);
$foo[4]=2;
while ($foo[0]<$mintrack) {
 print join(', ',@foo);
 $line=shift(@lines);
 @foo=@$line;
 shift(@foo);
}

print join(', ',@foo);

#do {
# $line=shift(@lines);
# @foo=@$line;
# shift(@foo);
# print join(', ',@foo);
#} while ($foo[0]<$mintrack);



# time sort what comes after preliminary tracks

@lines=sort {
 $a->[2] <=> $b->[2] ||
 $a->[0] <=> $b->[0]; # sort lines by time index
} @lines;

print "$mintrack, 0, Channel_prefix, $minchan\n";
print "$mintrack, 0, Title_t, \"Guitar\"\n";
print "$mintrack, 0, Instrument_name_t, \"Guitar\"\n";

while (@lines) {
 $line=shift(@lines);
 if ($line) { # skip line if removed earlier as redundancy
  @foo=@$line;
  shift(@foo);
  if ($foo[0] && $foo[2] =~ '_c$') {
   if ($foo[0]>$mintrack) {
    $foo[0]=$mintrack;
    if (exists $foo[3]) {
     $foo[3]=$minchan;
    }
   }
   $thislin=join(', ',@foo);
   if ($thislin ne $prevlin) {
    print $thislin;
   }
   $prevlin=$thislin;
  }
 }
}

print "$mintrack, $foo[1], End_track\n";
print "0, 0, End_of_file\n";


