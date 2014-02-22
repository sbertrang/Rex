#
# (c) Simon Bertrang <janus@cpan.org>
#
# vim: set ts=3 sw=3 tw=0 et:

package Rex::Virtualization::QEMU::hypervisor;

use Rex::Logger;
use Rex::Helper::Run;

sub execute {
   my ($class, $arg1, %opt) = @_;

   unless($arg1) {
      die("You have to define the vm name!");
   }

   my %ret;

   if ( $arg1 eq "capabilities" ) {
      ( my $qemu_img ) = i_run "which qemu-img";
      if ($?!=0) {
         die("Error looking up qemu-img");
      }
      ( my $expr = $qemu_img ) =~ s![-]img\z!-system-*!;
      my %archs = map m!/qemu[-]system[-]([^/-]+)\z!
                    ? ( $1, $_ )
                    : (), glob $expr;
      @ret{ keys %archs } = ("true") x keys %archs;
   }
   else {
      Rex::Logger::debug("Unknown action $arg1");
      die("Unknown action $arg1");
   }

   return \%ret;
}

1;
