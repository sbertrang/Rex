#
# (c) Simon Bertrang <janus@cpan.org>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Virtualization::QEMU::status;

use strict;
use warnings;

use Rex::Virtualization::QEMU::list;

sub execute {
   my ( $class, $arg1, %opt ) = @_;

   my $vms = Rex::Virtualization::QEMU::list->execute( "all" );

   my ( $vm ) = grep $_->{name} eq $arg1, @$vms;

   unless ( $vm ) {
      return;
   }

   if ( $vm->{status} eq "running" ) {
      return "running";
   }

   return "stopped";
} 

1;
