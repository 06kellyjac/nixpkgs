{
  lib,
  mkCoqDerivation,
  rocqPackages_9_0,
  rocqPackages_9_1,
  rocqPackages,
  which,
  coq,
  version ? null,
}:

with lib;
(mkCoqDerivation {
  pname = "parseque";
  repo = "parseque";
  owner = "rocq-community";

  inherit version;
  defaultVersion =
    with versions;
    switch
      [ coq.coq-version ]
      [
        {
          cases = [ (range "8.16" "9.0") ];
          out = "0.2.2";
        }
      ]
      null;

  release."0.2.2".sha256 = "sha256-O50Rs7Yf1H4wgwb7ltRxW+7IF0b04zpfs+mR83rxT+E=";

  releaseRev = v: "v${v}";

  meta = {
    description = "Total parser combinators in Coq/Rocq";
    maintainers = with maintainers; [ womeier ];
    license = licenses.mit;
  };
}).overrideAttrs
  (
    o:
    # this is just a wrapper for rocPackages.parseque for Rocq >= 9.0
    lib.optionalAttrs
      (coq.version != null && (coq.version == "dev" || lib.versions.isGe "9.0" coq.version))
      (
        let
          case = case: out: { inherit case out; };
          rp = lib.switch coq.coq-version [
            (case "9.0" rocqPackages_9_0)
            (case "9.1" rocqPackages_9_1)
          ] rocqPackages;
        in
        {
          configurePhase = ''
            echo no configuration
          '';
          buildPhase = ''
            echo building nothing
          '';
          installPhase = ''
            echo installing nothing
          '';
          propagatedBuildInputs = [ rp.parseque ];
        }
      )
  )
