{ pkgs ? import ../../../../. { } }:

pkgs.nixosTest ({
  name = "tracee-test";
  nodes = {
    machine = { config, pkgs, ... }: {
      environment.systemPackages = [
        pkgs.tracee
        (pkgs.tracee.overrideAttrs (oa: {
          pname = oa.pname + "-integration";
          # commented out to show the error:
          # patches = oa.patches ++ [ ./integration-test.patch ];
          # just build the static lib we need
          makeFlags = oa.makeFlags ++ [ "./dist/libbpf/libbpf.a" ];
          postBuild = ''
            sed -i '/t.Skip("This test requires root privileges")/d' ./tests/integration/integration_test.go
            CGO_CFLAGS="-I$PWD/dist/libbpf" CGO_LDFLAGS="-lelf -lz $PWD/dist/libbpf/libbpf.a" go test -tags ebpf,integration -c -o $GOPATH/tracee-integration ./tests/integration
          '';
          doCheck = false;
          installPhase = ''
            mkdir -p $out/bin
            cp $GOPATH/tracee-integration $out/bin
          '';
          doInstallCheck = false;
        }))
      ];
    };
  };

  testScript = ''
    with subtest("run integration tests"):
      print(machine.succeed('TRC_BIN="$(which tracee-ebpf)" tracee-integration -test.v -test.run "Test_Events"'))
  '';
})
