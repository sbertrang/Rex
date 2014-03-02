#
# (c) Simon Bertrang <janus@cpan.org>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Virtualization::QEMU::start;

use strict;
use warnings;

use Rex::Commands;
use Rex::Commands::File;
use Rex::Helper::Path;
use Rex::Helper::Run;
use Rex::Logger;

use Rex::Virtualization::QEMU::info;

sub execute {
   my ( $class, $arg1, %opt ) = @_;

   unless ( $arg1 ) {
      die("You have to define the vm name!");
   }

   my $dom = $arg1;
   Rex::Logger::debug("starting domain: $dom");

   my $vm = Rex::Virtualization::QEMU::info->execute( $dom );

   unless ( $vm ) {
      die("VM $dom not found.");
   }

   my $bin = "qemu-system-$vm->{system}";
   my $args = $vm->{args};
   my $home = resolv_path( "~/" );

   s!~/!$home! for @$args;

   my $output = i_run "$bin @$args";

   if ( $? != 0 ) {
      die("Error starting domain: $dom");
   }
}

1;
