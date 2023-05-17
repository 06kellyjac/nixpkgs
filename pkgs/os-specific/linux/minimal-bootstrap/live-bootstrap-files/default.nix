{ lib
, fetchurl
, sources ? import ./sources.nix
}:
let
  inherit (sources) targetCommit files;
  pname = "live-bootstrap";
  buildURL = commit: file: "https://github.com/fosslinux/${pname}/raw/${commit}/${file}";
  # keep name inline with the fetcher so they're found in the store rather than re-fetched
  # doesn't affect getting the right sha
  # e.g. /nix/store/3425qxmzdw3q3yarx4jcqcslair5dvd5-live-bootstrap-1bc4296091c51f53a5598050c8956d16e945b0f5-sysa-gzip-1.2.4-mk-main.mk
  buildName = commit: file: "${pname}-${commit}-${lib.replaceStrings ["/"] ["-"] file}";
  fileFetcher = commit: file: sha256: fetchurl {
    name = buildName targetCommit file;
    url = buildURL targetCommit file;
    inherit sha256;
  };
  fetchedFiles = lib.mapAttrs (name: value: fileFetcher targetCommit name value) files;
in
rec {
  getSubsetOfFiles = prefix:
    # trim prefix from filtered files
    lib.mapAttrs'
      (n: v: lib.nameValuePair (lib.removePrefix prefix n) v)
      # filter files with a matching prefix
      (lib.filterAttrs
        (n: _: lib.hasPrefix prefix n)
        fetchedFiles);
  packageFiles = { parent, pname, version }:
    getSubsetOfFiles "${parent}/${pname}-${version}/";
  files = fetchedFiles;
}
