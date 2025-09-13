{
  lib,
  stdenv,
  python,
  pythonOlder,
  pythonAtLeast,
  buildPythonPackage,
  fetchPypi,

  attrs,
  matplotlib,
  numpy,
  opencv4,
  protobuf,

  autoPatchelfHook,
}:

let
  version = "0.10.21";
  getSrcFromPypi =
    {
      platform,
      dist,
      hash,
    }:
    fetchPypi {
      inherit
        version
        platform
        dist
        hash
        ;
      pname = "mediapipe";
      format = "wheel";
      python = dist;
      abi = dist;
    };

  # complex bazel project, fetching prebuilt wheels
  srcs = {
    "3.12-x86_64-linux" = getSrcFromPypi {
      platform = "manylinux_2_28_x86_64";
      dist = "cp312";
      hash = "sha256-lW6x68J1xinmGwhbLKuJw6W56TutG7EHNI2Y2vtaS7U=";
    };
    "3.11-x86_64-linux" = getSrcFromPypi {
      platform = "manylinux_2_28_x86_64";
      dist = "cp311";
      hash = "sha256-LPPm/xNDtbV2TTWJPON16z5qhZBIty3I9wCv7CFai6Y=";
    };
    "3.10-x86_64-linux" = getSrcFromPypi {
      platform = "manylinux_2_28_x86_64";
      dist = "cp310";
      hash = "sha256-dDC8RnxtxbvBhvgcq5L0GhJy9aodFkbBu/rqkleD2oU=";
    };
    "3.9-x86_64-linux" = getSrcFromPypi {
      platform = "manylinux_2_28_x86_64";
      dist = "cp39";
      hash = "sha256-dDC8RxptxbvBhvgcq5L0GhJy9aodFkbBu/rqkleD2oU=";
    };
  };
in
buildPythonPackage {
  pname = "mediapipe";
  inherit version;
  format = "wheel";
  disabled = pythonOlder "3.9" || pythonAtLeast "3.13";

  src = (
    srcs."${python.pythonVersion}-${stdenv.hostPlatform.system}"
      or (throw "python${python.pythonVersion}Packages.mediapipe is not supported on ${stdenv.hostPlatform.system}")
  );

  propagatedBuildInputs = [
    protobuf
    numpy
    opencv4
    matplotlib
    attrs
  ];

  nativeBuildInputs = [ autoPatchelfHook ];

  pythonImportsCheck = [ "mediapipe" ];

  postPatch = ''
    # silence matplotlib warning
    export MPLCONFIGDIR=$(mktemp -d)
  '';

  meta = {
    description = "Cross-platform, customizable ML solutions for live and streaming media";
    homepage = "https://ai.google.dev/edge/mediapipe";
    downloadPage = "https://pypi.org/project/mediapipe/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      jk
    ];
    # are also wheels for darwin
    platforms = lib.intersectLists lib.platforms.x86_64 lib.platforms.linux;
    # using prebuilt wheels
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
