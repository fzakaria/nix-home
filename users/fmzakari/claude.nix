# Claude Code — Anthropic's CLI — and the language servers exposed to it.
{
  inputs,
  pkgs,
  ...
}: let
  agentSettings = import ./agent-settings.nix;

  # Binaries from numtide's llm-agents.nix (tracks upstream more aggressively
  # than nixpkgs). The home-manager `programs.claude-code` module below manages
  # the *config* around whichever binary we point its `package` at.
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Language servers exposed to Claude Code.
  #
  # Claude Code discovers LSP servers through a *plugin* that ships a
  # `.lsp.json`; the plugin directory is handed to the CLI via `--plugin-dir`.
  # home-manager's `programs.claude-code` module gains a native `lspServers`
  # option on master, but our pinned release predates it, so we replicate that
  # mechanism by hand (below) and wrap the binary ourselves.
  #
  # Commands are referenced by absolute store path so they resolve regardless of
  # PATH and get pulled into the closure. clang-tools + nixd are also on PATH
  # (see home.packages) for Helix and manual use.
  #
  # FORWARD-COMPAT: once home-manager ships `programs.claude-code.lspServers`
  # (added post-25.11 upstream), delete `claudeLspPlugin` and the `--plugin-dir`
  # flag in `claudeWrapped` below, and move `claudeLspServers` verbatim into
  # `programs.claude-code.lspServers`. Keep `claudeWrapped` for `--settings`.
  claudeLspServers = {
    clangd = {
      command = "${pkgs.clang-tools}/bin/clangd";
      args = ["--background-index"];
      extensionToLanguage = {
        ".c" = "c";
        ".h" = "c";
        ".cc" = "cpp";
        ".cpp" = "cpp";
        ".hpp" = "cpp";
      };
    };
    nixd = {
      command = "${pkgs.unstable.nixd}/bin/nixd";
      extensionToLanguage = {
        ".nix" = "nix";
      };
    };
    # Recommended given the languages in this repo — trim freely.
    pyright = {
      command = "${pkgs.pyright}/bin/pyright-langserver";
      args = ["--stdio"];
      extensionToLanguage = {
        ".py" = "python";
        ".pyi" = "python";
      };
    };
    gopls = {
      command = "${pkgs.unstable.gopls}/bin/gopls";
      args = ["serve"];
      extensionToLanguage = {
        ".go" = "go";
      };
    };
  };

  # Mirror home-manager master's plugin builder: a plugin dir with a
  # `.claude-plugin/plugin.json` marker file and the generated `.lsp.json`.
  claudeLspPlugin = pkgs.runCommand "claude-code-lsp-plugin" {} ''
    install -Dm644 ${(pkgs.formats.json {}).generate "plugin.json" {name = "nix-home-lsp";}} \
      $out/.claude-plugin/plugin.json
    install -Dm644 ${(pkgs.formats.json {}).generate "lsp.json" claudeLspServers} \
      $out/.lsp.json
  '';

  # Wrap the CLI so it always loads the plugin dir (again mirroring master's
  # `--plugin-dir` wrapper) and the Nix-owned `claudeSettings` below. We have no
  # mcpServers, so the module's own `finalPackage` passes this through unchanged.
  #
  # `remote-control` (alias `rc`) refuses to start when global flags come before
  # the verb, because the sessions it spawns would not inherit them
  # (anthropics/claude-code#86330). Pass that subcommand straight through; its
  # spawned sessions run without the LSP plugin and `claudeSettings`.
  claudeWrapped = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [pkgs.claude-code];
    postBuild = ''
      mv $out/bin/claude $out/bin/.claude-wrapped
      cat > $out/bin/claude <<EOF
      #! ${pkgs.bash}/bin/bash -e
      case "\''${1:-}" in
        rc | remote-control)
          exec -a "\$0" "$out/bin/.claude-wrapped" "\$@"
          ;;
      esac
      exec -a "\$0" "$out/bin/.claude-wrapped" --plugin-dir "${claudeLspPlugin}" --settings "${claudeSettingsFile}" "\$@"
      EOF
      chmod +x $out/bin/claude
    '';
    inherit (pkgs.claude-code) meta;
  };

  # Status line renderer for the Claude pane.
  #
  # ccusage's `statusline` only reports token/cost estimates from local logs — it
  # has no idea about the *subscription plan* usage (the "you've used X% of your
  # limit" figure from `/usage`). But Claude Code pipes that server-side figure
  # to the statusLine command on stdin under `rate_limits.{five_hour,seven_day}.
  # used_percentage` (Pro/Max only, populated after the first API response in a
  # session). So we tee the stdin JSON: hand it to ccusage for the usual line,
  # and separately pull the real plan-usage % out with jq, appending it.
  ccusageStatusline = pkgs.writeShellScript "ccusage-statusline" ''
    input=$(cat)
    line=$(printf '%s' "$input" | ${llmAgents.ccusage}/bin/ccusage statusline)
    plan=$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '
      [ (.rate_limits.five_hour.used_percentage | select(. != null) | "5h \(.|floor)%"),
        (.rate_limits.seven_day.used_percentage | select(. != null) | "7d \(.|floor)%") ]
      | join(" ")' 2>/dev/null)
    if [ -n "$plan" ]; then
      printf '%s | 📊 %s\n' "$line" "$plan"
    else
      printf '%s\n' "$line"
    fi
  '';

  # Settings Home Manager owns. These go in through `--settings` on the wrapper
  # instead of ~/.claude/settings.json: Claude Code persists `/effort`, `/model`
  # and `/config` changes to that file, and a store symlink there fails with
  # EROFS. The `--settings` layer takes precedence over the user file, so the
  # keys below still win.
  claudeSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    theme = "auto";
    permissions.allow = [
      # agent-browser is read-mostly automation against a throwaway headless
      # browser; prompting on every click and snapshot makes it unusable.
      "Bash(agent-browser:*)"
    ];
    # Claude's own internal status line — rendered at the bottom of the
    # Claude pane. This is the only place session usage/tokens/cost show up
    # (tmux's status bar can't see inside the Claude session). We feed it the
    # `ccusageStatusline` wrapper (above), referenced by store path so it works
    # regardless of PATH and is pulled into the closure without also being
    # installed onto PATH.
    statusLine = {
      type = "command";
      command = "${ccusageStatusline}";
    };
  };
  claudeSettingsFile = (pkgs.formats.json {}).generate "claude-code-settings.json" claudeSettings;
in {
  # Claude Code — Anthropic's CLI.
  #
  # The binary comes from llm-agents.nix (wrapped above to load our LSP plugin
  # and settings); this module owns CLAUDE.md and skills. Keeping the binary
  # here (not in home.packages) avoids installing claude-code twice into the
  # profile.
  programs.claude-code = {
    enable = true;
    package = claudeWrapped;

    # Host-level memory — written to ~/.claude/CLAUDE.md and loaded for *every*
    # project on this machine (a per-repo ./CLAUDE.md is layered on top). Keep
    # this to durable, machine-wide guidance; project specifics belong in the
    # repo's own CLAUDE.md.
    memory.text = agentSettings.instructions;

    # Skills — symlinked into ~/.claude/skills/<name>/ and loaded on demand
    # (only the frontmatter description is always in context, so a skill costs
    # nothing until Claude decides it is relevant).
    #
    # A *directory* is used rather than an inline string on purpose: the
    # home-manager module writes strings to `~/.claude/skills/<name>.md`, but
    # Claude Code discovers skills as `<name>/SKILL.md`.
    skills = agentSettings.skills;

    # Leave `settings` unset so ~/.claude/settings.json stays writable and
    # unmanaged: see `claudeSettings` above.
  };
}
