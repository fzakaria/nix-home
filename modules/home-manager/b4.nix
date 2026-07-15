# A reusable home-manager module for b4, the tool for kernel-style
# patch/email review workflows (https://b4.docs.kernel.org).
#
# b4 has no config file of its own: its global settings live in git-config under
# the `b4.*` namespace (per-repo `.b4-config` files can override a subset). So
# programs.b4.settings is written into git-config via `programs.git`.
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.b4;

  # The Vim/Emacs highlighting and the agent-reviewer instructions live in the
  # b4 git tree under misc/, but are NOT part of the PyPI sdist that nixpkgs
  # builds `b4` from -- so we fetch them from the tagged release.
  #
  # NOTE: keep `rev` in sync with `cfg.package`'s version. These files change
  # rarely, so a small drift is harmless.
  # FIXME(upstream): teach the nixpkgs b4 package to install these misc/ files
  # (the PyPI sdist omits them); then this fetch can be dropped in favour of
  # reading them straight out of cfg.package.
  miscSrc = pkgs.fetchgit {
    url = "https://git.kernel.org/pub/scm/utils/b4/b4.git";
    rev = "v0.15.2";
    hash = "sha256-NjYL3RKQpjDkU98qbXyl/cvLTJYVAfIowm8E2Rg8AgI=";
  };

  # b4's Vim review-editor files (ftdetect/ftplugin/syntax) as a runtimepath
  # plugin, so they can be dropped into any vim/neovim configuration.
  vimPlugin = pkgs.vimUtils.buildVimPlugin {
    pname = "b4-review-vim";
    version = cfg.package.version;
    src = "${miscSrc}/misc/vim";
    meta.description = "Vim syntax highlighting for the b4 review reply editor";
  };

  # b4's b4-review-mode.el as an Emacs (site-lisp) package, so it can go into
  # programs.emacs.extraPackages / an emacs load-path.
  emacsPackage = pkgs.emacsPackages.trivialBuild {
    pname = "b4-review-mode";
    version = cfg.package.version;
    src = "${miscSrc}/misc/emacs";
    meta.description = "Emacs major mode with highlighting for the b4 review reply editor";
  };
in {
  options.programs.b4 = {
    enable = mkEnableOption "b4, a tool for kernel-style patch/email review workflows";

    package = mkPackageOption pkgs "b4" {};

    settings = mkOption {
      type = with types; attrsOf (oneOf [bool int str (listOf str)]);
      default = {
        # Recommended: wire `b4 review`'s agent action (the `a` key in the review
        # TUI) to an AI reviewer. b4 shlex-splits review-agent-command and appends
        # a final argument telling the agent to read review-agent-prompt-path; it
        # runs with the repo top as cwd, so the relative `.git` paths resolve
        # per-repo. `--add-dir .git` lets the agent write its review files; the
        # second grants read access to the (out-of-tree) prompt file.
        review-agent-command =
          "${pkgs.claude-code}/bin/claude"
          + " --add-dir .git"
          + " --add-dir ${dirOf cfg.agentReviewInstructions}"
          + " --allowedTools 'Bash(git:*) Read Glob Grep Write(.git/b4-review/**) Edit(.git/b4-review/**)'"
          + " --";
        review-agent-prompt-path = "${cfg.agentReviewInstructions}";
      };
      defaultText = literalMD ''
        A recommended `review-agent-command` (Claude Code, `pkgs.claude-code`)
        and `review-agent-prompt-path` ({option}`programs.b4.agentReviewInstructions`).
      '';
      example = literalExpression ''
        {
          attestation-policy = "hardfail";
          review-agent-prompt-path = config.programs.b4.agentReviewInstructions;
        }
      '';
      description = ''
        Settings written verbatim to git-config's `[b4]` section (b4 has no config
        file of its own; it reads its configuration from git-config under the
        `b4.*` namespace). Setting this replaces the default in full; set it to
        `{ }` to write nothing. Requires {option}`programs.git.enable`.

        See <https://b4.docs.kernel.org/en/latest/config.html> for the full list
        of recognised keys.
      '';
    };

    vimSyntax = mkOption {
      type = types.bool;
      default = config.programs.vim.enable || config.programs.neovim.enable;
      defaultText = literalExpression "config.programs.vim.enable || config.programs.neovim.enable";
      description = ''
        Add b4's review-editor syntax highlighting to home-manager's Vim/Neovim
        ({option}`programs.vim`/{option}`programs.neovim`). Defaults to `true` when
        either is enabled. It activates automatically for `*.b4-review.eml`
        buffers. Editors managed outside home-manager (e.g. nixvim) can instead add
        the plugin exposed at {option}`programs.b4.vimPlugin` to their runtimepath.
      '';
    };

    emacsSyntax = mkOption {
      type = types.bool;
      default = config.programs.emacs.enable;
      defaultText = literalExpression "config.programs.emacs.enable";
      description = ''
        Add b4's `b4-review-mode` to home-manager's Emacs
        ({option}`programs.emacs`). Defaults to `true` when it is enabled; the mode
        autoloads for `*.b4-review.eml` files. Editors managed outside home-manager
        can instead consume the package exposed at {option}`programs.b4.emacsPackage`.
      '';
    };

    vimPlugin = mkOption {
      type = types.package;
      readOnly = true;
      default = vimPlugin;
      defaultText = literalMD "a Vim plugin built from b4's `misc/vim` files";
      description = ''
        b4's Vim review-editor files packaged as a runtimepath plugin, for adding
        to a vim/neovim configuration (e.g. `programs.neovim.plugins`).
      '';
    };

    emacsPackage = mkOption {
      type = types.package;
      readOnly = true;
      default = emacsPackage;
      defaultText = literalMD "an Emacs package built from b4's `misc/emacs` files";
      description = ''
        b4's `b4-review-mode.el` packaged as an Emacs site-lisp package, for
        adding to an emacs load-path (e.g. `programs.emacs.extraPackages`).
      '';
    };

    agentReviewInstructions = mkOption {
      type = types.either types.str types.path;
      default = "${miscSrc}/misc/agent-reviewer.md";
      defaultText = literalMD "b4's shipped `misc/agent-reviewer.md`";
      example = literalExpression ''
        # Supply a wholly custom file:
        ./my-agent-reviewer.md
        # ...or build one, e.g. a shared base plus your own house rules:
        pkgs.concatText "agent-reviewer.md" [
          ./base-agent-reviewer.md
          ./house-rules.md
        ]
      '';
      description = ''
        The `agent-reviewer.md` instructions describing how an AI agent should
        write review files under `.git/b4-review/`, as a file path. Defaults to
        the copy b4 ships in its `misc/` directory; override it to append your own
        guidance or supply a wholly custom file.

        Point `b4.review-agent-prompt-path` (see {option}`programs.b4.settings`) at
        this -- it is an absolute path, so b4 uses it verbatim in every repo,
        with no need to copy the file into each `.git/`.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [cfg.package];

      assertions = [
        {
          assertion = cfg.settings == {} || config.programs.git.enable;
          message = ''
            programs.b4.settings has [b4] git-config to write, but
            programs.git.enable is false. b4 reads its configuration from
            git-config's [b4] section, so enable programs.git (or set the b4.*
            keys in git-config yourself).
          '';
        }
      ];
    }

    (mkIf (cfg.settings != {}) {
      # b4's global config == git-config's [b4] section.
      programs.git.settings.b4 = cfg.settings;
    })

    # Inline the review-editor highlighting into home-manager's own editor
    # modules, rather than scattering loose dotfiles. vimSyntax/emacsSyntax
    # already default to the relevant editor being enabled; a plugins/packages
    # list set on a disabled editor is inert (read only under its own `enable`).
    (mkIf cfg.vimSyntax {
      programs.neovim.plugins = [cfg.vimPlugin];
      programs.vim.plugins = [cfg.vimPlugin];
    })
    (mkIf cfg.emacsSyntax {
      programs.emacs.extraPackages = epkgs: [cfg.emacsPackage];
    })
  ]);
}
