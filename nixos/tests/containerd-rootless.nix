# This test runs containerd and checks if simple container starts

import ./make-test-python.nix ({ lib, pkgs, ... }: {
  name = "containerd-rootless";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ jk jlesquembre ];
  };

  nodes = {
    machine = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nerdctl ];
      virtualisation.containerd.enable = false;
      virtualisation.containerd.rootless.enable = true;
      virtualisation.containerd.rootless.portDriver = "slirp4netns";

      users.users.alice = {
        uid = 1000;
        isNormalUser = true;
      };
    };
  };

  testScript = { nodes, ... }:
    let
      user = nodes.machine.config.users.users.alice;
      runtimeDir = "/run/user/${toString user.uid}";
      doAsAlice = lib.concatStringsSep " " [
        "XDG_RUNTIME_DIR=${runtimeDir}"
        "sudo"
        "--preserve-env=XDG_RUNTIME_DIR"
        "-u"
        "alice"
      ];
    in
    ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("loginctl enable-linger alice")
      machine.wait_until_succeeds("${doAsAlice} systemctl --user is-active containerd.service")
      # machine.wait_until_succeeds("${doAsAlice} systemctl --user is-active buildkit.service")
      machine.wait_for_file("${runtimeDir}/containerd-rootless/child_pid")
      # machine.wait_for_file("${runtimeDir}/buildkit/buildkitd.sock")
      machine.succeed("echo 'FROM scratch' > Dockerfile",
                      "${doAsAlice} nerdctl build -t scratchimg .")
      machine.succeed(
          "${doAsAlice} nerdctl run -d --name=sleeping " +
          "-v /nix/store:/nix/store " +
          "-v /run/current-system/sw/bin:/bin " +
          "scratchimg /bin/sleep 10"
      )
      machine.succeed("${doAsAlice} nerdctl ps | grep sleeping")
      machine.succeed("${doAsAlice} nerdctl stop sleeping")
    '';
})
