{
  config,
  pkgs,
  lib,
  ...
}: let
  # Marketplace / OpenVSX extensions, filtered to versions whose
  # `engines.vscode` is satisfied by the VS Code we actually ship.
  marketplace = pkgs.unstable.forVSCodeVersion pkgs.unstable.vscode.version;

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
    # gopls from unstable so it supports newer Go toolchains (e.g. go 1.25)
    "go.alternateTools" = {
      "gopls" = pkgs.lib.getExe pkgs.unstable.gopls;
    };
  };
  rust = {
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

  # `claudeProcessWrapper` spawns us as `wrapper <that-path>
  # <claude flags...>`, so `shift` drops the bundled path before we exec.
  claudeVscodeWrapper = pkgs.writeShellScript "claude-code-vscode-wrapper" ''
    shift
    exec ${lib.getExe config.programs.claude-code.finalPackage} "$@"
  '';
  claude = {
    "claudeCode.claudeProcessWrapper" = "${claudeVscodeWrapper}";
    "claudeCode.preferredLocation" = "sidebar";
    "claudeCode.initialPermissionMode" = "acceptEdits";
  };
  githubPr = {
    "githubPullRequests.pullBranch" = "never";
    "githubPullRequests.fileListLayout" = "tree";
  };
  git = {
    "git.blame.editorDecoration.enabled" = true;
  };
in {
  xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";

  programs.vscode = {
    enable = true;

    profiles.default = {
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;

      extensions =
        (with marketplace.vscode-marketplace; [
          # Native-binary extensions: nix-vscode-extensions applies nixpkgs'
          # patchelf/special handling — from unstable, since the marketplace set
          # is built on pkgs.unstable — over the marketplace extension version.
          ms-vscode.cpptools
          ms-vscode-remote.remote-ssh

          # rust extensions
          rust-lang.rust-analyzer

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
          # justusadam.language-haskell — dropped: its marketplace VSIX 404s, and
          # the all-unstable base can't fall back to a pre-realized copy.
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
          # AI
          anthropic.claude-code
          # git / GitHub
          github.copilot
          github.copilot-chat
          github.vscode-pull-request-github
        ])
        # Kept intentionally empty. Use this channel only for extensions we want
        # pinned to stable releases (pre-releases excluded). forVSCodeVersion
        # already guarantees engine compatibility on the main channel above, so
        # its pre-releases are fine for everything we currently install.
        ++ (with marketplace.vscode-marketplace-release; [
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
        // rust
        // meson
        // claude
        // githubPr
        // git;
    };

    mutableExtensionsDir = false;

    package = pkgs.unstable.vscode;
  };
}
