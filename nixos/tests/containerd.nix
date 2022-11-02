# This test runs containerd and checks if simple container starts

import ./make-test-python.nix ({ lib, pkgs, ... }: {
  name = "containerd";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ jk jlesquembre ];
  };

  nodes = {
    machine = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nerdctl ];
      virtualisation.containerd.enable = true;

      users.users.noprivs = {
        isNormalUser = true;
        description = "Can't access the containerd daemon";
      };
    };
  };

  # TODO: replace nerdctl usage with ctr
  testScript = { nodes, ... }: ''
    machine.wait_for_unit("sockets.target")
    machine.wait_for_unit("containerd.service")
    # machine.wait_for_unit("containerd.socket")
    machine.succeed("nerdctl load --input='${pkgs.dockerTools.examples.bash}'")

    machine.succeed(
        "nerdctl run -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin ${pkgs.dockerTools.examples.bash.imageName} /bin/sleep 10"
    )
    machine.succeed("nerdctl ps | grep sleeping")
    machine.fail("sudo -u noprivs nerdctl ps")
    machine.succeed("nerdctl stop sleeping")
  '';
})
    # machine.wait_for_unit("sockets.target")
    # machine.wait_for_unit("containerd.service")
    # # machine.wait_for_unit("containerd.socket")
    # # print(machine.succeed("tar cv --files-from /dev/null | ctr images import - --base-name scratchimg --no-unpack"))
    # print(machine.succeed("ctr images import ${pkgs.dockerTools.examples.bash}"))

    # machine.succeed(
    #     "ctr run -d --pid-file=/tmp/sleeping --mount type=bind,src=/nix/store,dst=/nix/store,options=rbind:ro --mount type=bind,src=/run/current-system/sw/bin,dst=/bin,options=rbind:ro ${pkgs.dockerTools.examples.bash.imageName} /bin/sleep 10"
    # )
    # machine.succeed("ctr task ls | grep $(cat /tmp/sleeping)")
    # machine.succeed("sudo -u hasprivs ctr task ls")
    # machine.fail("sudo -u noprivs ctr task ls")
    # machine.succeed("ctr task kill v0 $(cat /tmp/sleeping)")
