#!/usr/bin/perl
use POSIX qw(strftime);
%bads={};

open(my $iostat, "-|", "/usr/bin/iostat -xnr 1") or die "couldn't open pipe to iostat: $!";

while(my $line = <$iostat>) {
  if($line =~ m/(\d*\.\d),(\d*\.\d),(\d*\.\d),(\d*\.\d),(\d*\.\d),(\d*\.\d),(\d*\.\d),(\d*\.\d),(\d*),(\d*),(c\d+t[0-9,A-F]+d\d+)/) {
    $datetime = strftime('%F-%H:%M:%S', gmtime());
    if (($8 > 300) || ($10 > 98)) {
      if (20 < ++$bads{$11}) { $bads{$11}=20; } #undefined hash-elements are autovivified to 0
      if (10 == $bads{$11}) { print STDERR "\n[$datetime] $11 marked bad";}
    } else {
      if (exists($bads{$11}) && (not --$bads{$11})) { delete $bads{$11}; }
      if (9 == $bads{$11}) { print STDERR "\n[$datetime] $11 marked good"; }
    }
  }

  if ($line =~ m/extended device statistics/) { # After each iostat pass, recreate bad.disks, if required.
    my ($key, $value);
    my $output = '';

    while (($key, $value) = each(%bads)){ if ($value > 9){ $output .= "$key\n"; } }

    if ( $output ){
      open(fh, ">", "/home/prominic/bad.disks") or die "Can't open ~prominic/bad.disks for writing: $!";
      print fh $output;
      close fh;
    } else { unlink "/home/prominic/bad.disks"; }
  }
}
