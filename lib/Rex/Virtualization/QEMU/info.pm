#
# (c) Simon Bertrang <janus@cpan.org>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Virtualization::QEMU::info;

use strict;
use warnings;

use Rex::Logger;
use Rex::Helper::Run;
use Rex::Commands::File;

use Data::Dumper;

use Rex::Virtualization::QEMU::list;

sub execute {
   my ($class, $vmname) = @_;

   unless($vmname) {
      die("You have to define the vm name!");
   }

   Rex::Logger::debug("Getting info of domain: $vmname");

   my $vms = Rex::Virtualization::QEMU::list->execute( "all" );

   my ( $vm ) = grep $_->{name} eq $vmname, @$vms;

   unless ( $vm ) {
      return;
   }

   my $cmd = cat "$vm->{dir}/qemu.cmd";

   if ( $? != 0 ) {
      die("Error reading QEMU command file");
   }

   my %ret = %$vm;

   my ( $prog, @args ) = split m!\n!, $cmd;

   if ( $prog =~ m!\A\Qqemu-system-\E(\S+)! ) {
      $ret{system} = $1;
   }
   else {
      die("Error reading QEMU system");
   }

   my %opts;

   for my $line ( @args ) {
      my ( $opt, $val ) = split m!\s+!, $line, 2;

      unless ( exists $opts{ $opt } ) {
         $opts{ $opt } = $val;
      }
      else {
         unless ( ref $opts{ $opt } ) {
            $opts{ $opt } = [ $opts{ $opt } ];
         }
         push( @{ $opts{ $opt } }, $val );
      }
   }

   $ret{opts} = \%opts;
   $ret{args} = \@args;

   return \%ret;
}

1;
