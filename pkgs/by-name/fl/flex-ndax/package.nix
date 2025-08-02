{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitHub,
  libpulseaudio,
  nix-update-script,
}:

buildGoModule rec {
  pname = "flex-ndax";
  version = "0.5-20250801.0";

  src = fetchFromGitHub {
    owner = "kc2g-flex-tools";
    repo = "nDAX";
    tag = "v${version}";
    hash = "sha256-2yHv1FSikQuPamAwSzZB6+ZoblFoD/8Jnvhhv9OO+VY=";
  };

  buildInputs = [ libpulseaudio ];

  vendorHash = "sha256-saQjN2G4mhS4XAxZbPnP2+F6n4pWw5bMNlcb8xEs11M=";

  passthru.updateScript = nix-update-script { };

  meta = {
    broken = stdenv.hostPlatform.isDarwin;
    homepage = "https://github.com/kc2g-flex-tools/nDAX";
    description = "FlexRadio digital audio transport (DAX) connector for PulseAudio";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mvs ];
    mainProgram = "nDAX";
  };
}
