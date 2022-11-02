{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, nerdctl
, libselinux
, rootlesskit
, containerd
, runc # default container runtime
, slirp4netns # user-mode networking for unprivileged namespaces
, util-linux # nsenter
, iptables
, iproute2
}:

stdenvNoCC.mkDerivation rec {
  pname = "containerd-rootless";
  inherit (nerdctl) src version;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase =
    let
      binPath = lib.makeBinPath ([
        libselinux
        rootlesskit
        containerd
        runc
        slirp4netns
        util-linux
        iptables
        iproute2
      ]);
    in
    ''
      install -D extras/rootless/containerd-rootless.sh $out/bin/containerd-rootless

      wrapProgram $out/bin/containerd-rootless \
        --prefix PATH : ${lib.escapeShellArg binPath}
    '';

  meta = with lib; {
    homepage = "https://github.com/containerd/nerdctl/";
    changelog = "https://github.com/containerd/nerdctl/releases/tag/v${version}";
    description = "A helper for launching containerd rootless";
    license = licenses.asl20;
    maintainers = with maintainers; [ jk jlesquembre ];
    platforms = platforms.linux;
  };
}
