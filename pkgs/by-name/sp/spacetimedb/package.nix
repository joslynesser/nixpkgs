{
  lib,
  callPackage,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  perl,
  git,
  versionCheckHook,
  librusty_v8 ? callPackage ./librusty_v8.nix {
    inherit (callPackage ./fetchers.nix { }) fetchLibrustyV8;
  },
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "spacetimedb";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "clockworklabs";
    repo = "spacetimedb";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QtNc/5ezhqyKlnqyakqdRiC2stjRjR+R5gfbuT4WOrc=";

    # extract git commit to provide in build.rs
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  cargoHash = "sha256-eNUh8tYef4WkT6cZvnBmjkqX6QNuysZ25AfKvOtWqCo=";

  postPatch = ''
    substituteInPlace crates/cli/build.rs crates/lib/build.rs \
      --replace-fail \
        'Command::new("git").args(["rev-parse", "HEAD"])' \
        'Command::new("cat").args(["COMMIT"])'
  '';

  nativeBuildInputs = [
    pkg-config
    perl
    git
  ];

  cargoBuildFlags = [ "-p spacetimedb-standalone -p spacetimedb-cli" ];

  checkFlags = [
    # requires wasm32-unknown-unknown target
    "--skip=codegen"
  ];

  doInstallCheck = true;

  env.RUSTY_V8_ARCHIVE = librusty_v8;

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/spacetime";
  versionCheckProgramArg = "--version";

  postInstall = ''
    mv $out/bin/spacetimedb-cli $out/bin/spacetime
  '';

  meta = {
    description = "Full-featured relational database system that lets you run your application logic inside the database";
    homepage = "https://github.com/clockworklabs/SpacetimeDB";
    license = lib.licenses.bsl11;
    mainProgram = "spacetime";
    maintainers = with lib.maintainers; [ akotro ];
  };
})
