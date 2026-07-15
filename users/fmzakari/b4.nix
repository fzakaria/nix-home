# Personal b4 configuration. The reusable/upstreamable module that this builds
# on lives at modules/home-manager/b4.nix.
{
  config,
  pkgs,
  outputs,
  ...
}: {
  imports = [
    outputs.homeManagerModules.b4
  ];

  programs.b4 = {
    enable = true;
    package = pkgs.unstable.b4;
  };

  # Give the `b4 review` reply editor its diff-aware highlighting inside nixvim
  # (activates automatically for *.b4-review.eml buffers). home-manager's native
  # programs.vim/neovim/emacs are auto-wired by the module; nixvim is third-party,
  # so we add the exposed plugin to its runtimepath ourselves.
  programs.nixvim.extraPlugins = [config.programs.b4.vimPlugin];
}
