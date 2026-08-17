# ttfx: the terminal text effects binary Omarchy uses for its screensaver.
#
# omarchy-system-lock pkills it by name and omarchy-debug-idle matches on it,
# so the screensaver path stays broken until this is on PATH. A pure Rust
# binary with three crate dependencies and no system libraries, so there is
# nothing to wrap.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ttfx";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "ttfx";
    rev = "v${finalAttrs.version}";
    hash = "sha256-bwFjC6ZkZibkgXjoYVH2VuqqeXklGR9kmRl2fTitWBU=";
  };

  cargoHash = "sha256-DNrg12MNqBcQi6yvoJObM1gtE90iGBCxeQ3RwueYCE4=";

  nativeBuildInputs = [installShellFiles];

  # The binary generates its own clap completions, the same way upstream's
  # PKGBUILD does it. Safe to run here because the build is native. Only bash
  # and zsh: --print-completion fish returns nothing.
  postInstall = ''
    installShellCompletion --cmd ttfx \
      --bash <("$out/bin/ttfx" --print-completion bash) \
      --zsh <("$out/bin/ttfx" --print-completion zsh)
  '';

  meta = {
    description = "Terminal text effects as a single static binary, a Rust port of terminaltexteffects";
    homepage = "https://github.com/omacom/ttfx";
    license = lib.licenses.mit;
    mainProgram = "ttfx";
    platforms = lib.platforms.linux;
  };
})
