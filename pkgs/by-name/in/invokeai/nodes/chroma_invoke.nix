# https://gitlab.com/keturn/chroma_invoke
# {
#   lib,
#   fetchFromGitLab,
#   buildPythonPackage,
#   pythonOlder,

#   setuptools,

#   pyparsing,
#   jinja2,

#   # optional
#   transformers,
#   requests,
#   pyyaml,

#   pytest-cov,
#   pytest-lazy-fixture,

#   pytestCheckHook,
# }:
# buildPythonPackage rec {
#   pname = "chroma_invoke";
#   version = "0-unstable-2025-07-17";
#   pyproject = true;
#   disabled = pythonOlder "3.8";

#   src = fetchFromGitLab {
#     owner = "keturn";
#     repo = "chroma_invoke";
#     rev = "ef405579c400c1689858efd66b2f83afc0f83e70";
#     hash = "sha256-gBDOsgxSxDQVavNFoLuYVzbGX6td/Xq7SoamGZkD3pw=";
#   };

#   build-system = [
#     setuptools
#   ];

#   dependencies = [
#     # pyparsing
#     # jinja2
#   ];

#   optional-dependencies = {
#   };

#   pythonImportsCheck = [ "chroma_invoke" ];
#   # nativeCheckInputs = [
#   #   pytestCheckHook
#   # ] ++ lib.flatten (builtins.attrValues optional-dependencies);

#   meta = {
#     description = "Templating language for generating prompts for text to image generators such as Stable Diffusion";
#     homepage = "https://github.com/adieyal/dynamicprompts/";
#     license = lib.licenses.asl20;
#     maintainers = with lib.maintainers; [
#       jk
#     ];
#   };
# }

{
  lib,
  fetchFromGitLab,
  mkInvokeaiNode,
  pythonPackages,
}:

mkInvokeaiNode rec {
  pname = "chroma_invoke";
  version = "0-unstable-2025-07-17";

  src = fetchFromGitLab {
    owner = "keturn";
    repo = "chroma_invoke";
    rev = "ef405579c400c1689858efd66b2f83afc0f83e70";
    hash = "sha256-gBDOsgxSxDQVavNFoLuYVzbGX6td/Xq7SoamGZkD3pw=";
  };

  banditSkipChecks = [
    # LOW - some basic asserts for object types
    "B101"
  ];

  propagatedBuildInputs = [ pythonPackages.kornia ];

  meta = {
    description = "Chroma support for InvokeAI";
    homepage = "https://gitlab.com/keturn/chroma_invoke/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
