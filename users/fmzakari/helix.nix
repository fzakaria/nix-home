{pkgs, ...}: {
  # Good references:
  # https://github.com/maximbaz/dotfiles/blob/4a5fc2f6a93100670f07445a9a351566df1733f1/modules/common/helix.nix
  programs.helix = {
    enable = true;
    package = pkgs.unstable.helix;
    settings = {
      theme = "draula";
      editor = {
        color-modes = true;
        lsp = {
          display-inlay-hints = true;
        };
      };
    };
    extraPackages = with pkgs; [
      marksman
      unstable.nixd
      unstable.alejandra
      nodePackages.prettier
    ];
    languages = {
      language = [
        {
          name = "nix";
          formatter.command = "alejandra";
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = ["marksman" "gpt"];
          formatter = {
            command = "prettier";
            args = ["--stdin-filepath" "file.md"];
          };
          auto-format = true;
        }
      ];
    };
  };
}
