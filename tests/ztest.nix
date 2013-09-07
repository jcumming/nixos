{ pkgs, ... }:

{
  nodes = {
    machine =
      { pkgs, config, ... }:

      {
        virtualisation.emptyDiskImages = [ 4096 ];
        boot.supportedFilesystems = [ "zfs" "ext4" ] ; 
      };
  };

  testScript = ''
    startAll;

    $machine->waitForUnit("default.target");

    # this is a work in progress, it currently fails with:
    #   pack/bigT mismatch in 0x7f5ff010cf60/0x7f5ff068fea8
    # probably some disk io synchronization problems. 

    # we don't directly create a zfs filesystem here we create a ext3
    # filesystem and the the zfs unit tests use it.. 

    $machine->succeed("mkfs.ext3 -L ztest /dev/vdb");
    $machine->succeed("mkdir /ztest");
    $machine->succeed("mount LABEL=ztest /ztest");
    $machine->succeed("echo Running ZFS unit tests, this may take a while...");
    $machine->succeed("ztest -f /ztest -t1 -VVV");  # single threaded
    $machine->shutdown;
  '';
}
