#
# (c) Simon Bertrang <janus@cpan.org>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Virtualization::QEMU::create;

use strict;
use warnings;

use Rex::Logger;
use Rex::Commands::Gather;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Helper::Run;

use Rex::Virtualization::QEMU::hypervisor;

sub execute {
   my ($class, $name, %opt) = @_;

   my $opts = \%opt;
   $opts->{name} = $name;
   $opts->{type} ||= "i386"; # default to i386

   unless($opts) {
      die("You have to define the create options!");
   }

   my $hypervisor = Rex::Virtualization::QEMU::hypervisor->execute( "capabilities" );

   unless ( exists $hypervisor->{ $opts->{type} } ) {
      die("Hypervisor not supported.");
   }

   _set_defaults($opts);

   mkdir $opts->{dir};

   my @cmd = (
      "qemu-system-$opts->{type}",
      "-m $opts->{memory}",
      "-nographic",
      "-daemonize",
      "-pidfile $opts->{pidfile}",
      "-serial unix:$opts->{dir}/qemu.serial,server,nowait",
      "-monitor unix:$opts->{dir}/qemu.monitor,server,nowait",
   );
   for ( @{ $opts->{storage} } ) {
      if ( ! exists $_->{template} && $_->{size} && $_->{type} eq "file" ) {
         if ( is_file( $_->{file} ) ) {
            Rex::Logger::info("$_->{file} already exists. Using this.");
         }
         else {
            Rex::Logger::debug("creating storage disk: \"$_->{file}\"");
            i_run "qemu-img create -f $_->{format} $_->{file} $_->{size}";
            if($? != 0) {
               die("Error creating storage disk: $_->{file}");
            }
         }
      }
      elsif ($_->{template} && $_->{type} eq "file") {
         Rex::Logger::info("building domain: \"$opts->{name}\" from template: \"$_->{template}\"");
         Rex::Logger::info("Please wait ...");
         i_run "qemu-img convert -f $_->{format} $_->{template} -O $_->{format} $_->{file}";
         if($? != 0) {
            die("Error building domain: \"$opts->{name}\" from template: \"$_->{template}\"\nTemplate doesn't exist or the qemu-img binary is missing");
         }
      }
      push( @cmd, "-$_->{drive} $_->{file}" );
   }

   Rex::Logger::info("creating domain: \"$opts->{name}\"");

   file $opts->{cmdfile},
      content => join "\n", @cmd;

   return;
}

sub _set_defaults {
   my ($opts) = @_;

   my $name = $opts->{name} 
      or die("You have to give a name.");
   unless ( exists $opts->{storage} ) {
      die("You have to add at least one storage disk.");
   }

   my $vmdir = "~/.qemu/vms/$name";
   $opts->{dir} = $vmdir;
   $opts->{cmdfile} = "$vmdir/qemu.cmd";
   $opts->{pidfile} = "$vmdir/qemu.pid";

   if( ! exists $opts->{"memory"} ) {
      $opts->{"memory"} = 512;
   }
   else {
      # default is mega byte
      $opts->{memory} = $opts->{memory};
   }

   _set_storage_defaults($opts);

   _set_network_defaults($opts);

}

sub _set_storage_defaults {
   my ( $opts ) = @_;
   my @storage;
   my %storage = (
      disk   => [],
      cdrom  => [],
      floppy => [],
   );

   my %drive = (
      disk   => [qw[ hda hdb hdc hdd ]],
      cdrom  => [qw[ cdrom ]],
      floppy => [qw[ fda fdb ]],
   );

   for my $store ( @{ $opts->{storage} } ) {
      # default type
      if ( ! exists $store->{type} ) {
         $store->{type} = "file";
      }

      # default format for type file
      if( $store->{type} eq "file" && ! exists $store->{format} ) {
         $store->{format} = "qcow2";
      }

      if ( $store->{format} ) {
         $store->{format} = lc $store->{format};
      }

      # default size for type file
      if( ! exists $store->{size} && $store->{type} eq "file" ) {
         $store->{size} = "10G";
      }

      # normalize size for type file
      if( $store->{type} eq "file" ) {
         $store->{size} = _calc_size( $store->{size} );
      }

      if( exists $store->{file} && ! exists $store->{device} ) {
         if ( $store->{file} =~ m/\.iso$/ ) {
            $store->{device} = "cdrom";
         }
         elsif ( $store->{file} =~ m/\.fs$/ ) {
            $store->{device} = "floppy";
         }
         else {
            $store->{device} = "disk";
         }
      }

      if( ! exists $store->{device} ) {
         $store->{device} = "disk";
      }

      $store->{drive} = shift @{ $drive{ $store->{device} } };

      push( @{ $storage{ $store->{device} } }, $store );
   }

   if ( @{ $storage{disk} } > 3 && @{ $storage{cdrom} } == 1 ) {
      die("Only three disks drives are supported with a cdrom drive");
   }
   if ( @{ $storage{cdrom} } > 1 ) {
      die("Only one cdrom drive is supported");
   }
   if ( @{ $storage{floppy} } > 2 ) {
      die("Only two floppy drives are supported");
   }

}

sub _set_network_defaults {
   my ($opts, $hyper) = @_;

   if( ! exists $opts->{"network"} ) {
      $opts->{"network"} = [
         {
            type   => "bridge",
            bridge => "eth0",
         },
      ];
   }

   for my $netdev ( @{ $opts->{"network"} } ) {

      if( ! exists $netdev->{"type"} ) {
         $netdev->{"type"} = "bridge";
      }

      if( ! exists $netdev->{"bridge"} ) {
         $netdev->{"bridge"} = "eth0";
      }

   }
}

# return size in megabyte: 1g == 1024, 100m == 100
sub _calc_size {
   my ( $size ) = @_;
   my $ret_size = 0;

   if( $size =~ m/^([0-9]+)[Gg]$/ ) {
      $ret_size = $1 * 1024;
   }
   elsif ( $size =~ m/^([0-9]+)[Mm]$/ ) {
      $ret_size = $1;
   }

   return $ret_size;
}

1;
