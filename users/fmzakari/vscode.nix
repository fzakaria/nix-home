{
  config,
  pkgs,
  lib,
  ...
}: let
  window = {
    "window.zoomLevel" = 2;
  };
  editor = {
    "editor.bracketPairColorization.enabled" = true;
    "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
    "editor.trimAutoWhitespace" = true;
    "editor.renderLineHighlight" = "all";
    "editor.semanticHighlighting.enabled" = true;
    "editor.guides.indentation" = true;
    "editor.guides.bracketPairs" = true;
    "editor.lineNumbers" = "relative";
  };
  cpp = {
    "C_Cpp.intelliSenseEngine" = "disabled";
    "cmake.configureOnOpen" = false;
  };
  nix = {
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nixd";
    "nix.formatterPath" = "alejandra";
    "nix.serverSettings" = {
      "nixd" = {
        "formatting" = {
          "command" = ["alejandra"];
        };
      };
    };
  };
  telemetry = {
    "redhat.telemetry.enabled" = false;
    "telemetry.telemetryLevel" = "off";
  };
in {
  xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";

  programs.vscode = {
    enable = true;

    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;

    package = pkgs.vscode;

    extensions =
      (with pkgs.vscode-extensions; [
        # nixpkgs has special handling to create this extension
        ms-vscode.cpptools
      ])
      ++ (with pkgs.vscode-marketplace; [
        # nix extensions
        jnoortheen.nix-ide
        # general extensions
        christian-kohler.path-intellisense
        # c++ extensions
        twxs.cmake
        ms-vscode.cpptools-themes
        ms-vscode.cmake-tools
        llvm-vs-code-extensions.vscode-clangd
        # python
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ms-python.mypy-type-checker
        ms-python.isort
        ms-python.black-formatter
      ])
      ++ (with pkgs.vscode-marketplace-release; [
        github.copilot
        github.copilot-chat
        eamodio.gitlens
      ]);

    userSettings =
      {
        # You can put one-off settings here, otherwise try to put them
        # in a more specific attrset above.
      }
      // editor
      // telemetry
      // window
      // nix
      // cpp;
  };
}
