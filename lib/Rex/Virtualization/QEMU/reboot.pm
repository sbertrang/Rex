#
# (c) Simon Bertrang <janus@cpan.org>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Virtualization::QEMU::reboot;

use strict;
use warnings;

use Rex::Logger;
use Rex::Helper::Run;

use Rex::Virtualization::QEMU::list;

sub execute {
   my ( $class, $arg1, %opt ) = @_;

   unless ( $arg1 ) {
      die("You have to define the vm name!");
   }

   my $dom = $arg1;
   Rex::Logger::debug("rebooting domain: $dom");

   my $vms = Rex::Virtualization::QEMU::list->execute( "all" );

   my ( $vm ) = grep $_->{name} eq $dom, @$vms;

   unless ( $vm ) {
      die("VM $dom not found.");
   }

   unless ( $vm->{status} eq "running" ) {
      die("VM $dom not running.");
   }

   i_run "echo reset | nc -U $vm->{dir}/qemu.monitor";
   if ( $? != 0 ) {
      die("Error rebooting vm $dom");
   }
}

1;
