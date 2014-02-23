#
# (c) Simon Bertrang <janus@cpan.org>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Virtualization::QEMU::list;

use strict;
use warnings;

use Rex::Logger;
use Rex::Helper::Run;
use Rex::Commands::File;
use Rex::Commands::Fs;
use Rex::Commands::Process;

sub execute {
   my ( $class, $arg1, %opt ) = @_;
   my $user = Rex::Config->get_user();
   my $dir = "~/.qemu/vms";
   my $cmdfile = "qemu.cmd";

   # lookup directory names
   my @vms = map m!/([^/]+)/\Q$cmdfile\E\z! ? $1 : (),
      glob "$dir/*/$cmdfile";
   my %vms;

   # get qemu processes for the given user only
   my %ps = map +( $_->{pid}, $_ ),
      grep $_->{user} eq $user &&
           $_->{command} =~ m/\b\Qqemu-system-\E/,
      ps();

   for my $vm ( @vms ) {
      my $pid = i_run "head -1 $dir/$vm/qemu.pid";

      if ( $pid && $pid =~ m/\A\s*([0-9]+)\b\s*/m ) {
         $pid = $1;
      }
      else {
         $pid = undef;
      }

      my $status = $pid && exists $ps{ $pid }
                 ? "running"
                 : "stopped";

      $vms{$vm} = {
         name   => $vm,
         dir    => "$dir/$vm",
         pid    => $pid,
         status => $status,
      };
   }

   if ( $arg1 eq "all" ) {
      @vms = sort @vms;
   } elsif ( $arg1 eq "running" ) {
      @vms = sort grep $vms{$_}{status} eq "running", @vms;
   } else {
      return;
   }

   my @ret = @vms{ @vms };

   return \@ret;
}

1;
