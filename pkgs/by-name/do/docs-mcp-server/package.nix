{
  lib,
  buildNpmPackage,
  fetchFromGitHub,

  makeWrapper,

  playwright-test,
  playwright-driver,

  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "docs-mcp-server";
  version = "2.4.0";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "arabold";
    repo = "docs-mcp-server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wgNCygIkoN/MQJZz73+20OO2m7I60Uz2lWrYFghqxXA=";
  };

  npmDepsHash = "sha256-492ZBeXnP1LijSIR0xnDRpxL2Rm5u6HTS2AEd+MNVSM=";

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    pkg_dir="$out/lib/node_modules/@arabold/docs-mcp-server"
    rm -rf "$pkg_dir/node_modules/playwright"
    rm -rf "$pkg_dir/node_modules/playwright-core"
    ln -s ${playwright-test}/lib/node_modules/playwright "$pkg_dir/node_modules/playwright"
    ln -s ${playwright-test}/lib/node_modules/playwright-core "$pkg_dir/node_modules/playwright-core"

    # just replacing the playwright library isn't enough and needs to point to
    # matching the browsers
    wrapProgram $out/bin/${finalAttrs.meta.mainProgram} \
      --set PLAYWRIGHT_BROWSERS_PATH ${playwright-driver.browsers} \
      --set-default PLAYWRIGHT_MCP_BROWSER chromium
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-Source Alternative to Context7, Nia, and Ref.Tools";
    homepage = "https://grounded.tools/";
    changelog = "https://github.com/arabold/docs-mcp-server/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      j-k
    ];
    mainProgram = "docs-mcp-server";
    platforms = lib.platforms.all;
  };
})
