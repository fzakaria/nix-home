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
  go = {
  };
  java = {
    "java.jdt.ls.java.home" = "${pkgs.openjdk}/lib/openjdk";
    "java.configuration.runtimes" = [
      {
        "default" = true;
        "name" = "JavaSE-21";
        "path" = "${pkgs.openjdk}/lib/openjdk";
      }
    ];
  };
  telemetry = {
    "redhat.telemetry.enabled" = false;
    "telemetry.telemetryLevel" = "off";
  };
  frontend = {
    "svelte.enable-ts-plugin" = true;
  };
  meson = {
    "mesonbuild.downloadLanguageServer" = false;
    "mesonbuild.languageServer" = "mesonlsp";
    "mesonbuild.languageServerPath" = pkgs.lib.getExe pkgs.unstable.mesonlsp;
    "mesonbuild.modifySettings" = false;
    # default for Nix project
    "mesonbuild.buildFolder" = "build";
  };
in {
  xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";

  programs.vscode = {
    enable = true;

    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;

    package = pkgs.unstable.vscode;

    extensions =
      # use the nixpkgs version but at least unstable
      (with pkgs.unstable.vscode-extensions; [
        # nixpkgs has special handling to create this extension
        ms-vscode.cpptools
        # remote development
        ms-vscode-remote.remote-ssh
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
        # golang
        golang.go
        # bazel
        bazelbuild.vscode-bazel
        # java
        redhat.java
        vscjava.vscode-java-debug
        vscjava.vscode-gradle
        vscjava.vscode-maven
        vscjava.vscode-java-dependency
        vscjava.vscode-java-test
        vscjava.vscode-java-pack # just so we don't get prompted. does nothing.
        # haskell
        haskell.haskell
        justusadam.language-haskell
        # frontend
        svelte.svelte-vscode
        bradlc.vscode-tailwindcss
        # ruby
        shopify.ruby-lsp
        # remote development
        ms-vscode-remote.remote-ssh-edit
        ms-vscode.remote-explorer
        # meson
        mesonbuild.mesonbuild
        # malloy
        malloydata.malloy-vscode
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
        "malloy.nodePath" = pkgs.lib.getExe pkgs.nodejs;
        "malloy.useNewExplorer" = true;
      }
      // editor
      // telemetry
      // window
      // nix
      // cpp
      // java
      // go
      // frontend
      // meson;
  };
}
