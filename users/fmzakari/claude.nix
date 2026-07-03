# Claude Code — Anthropic's CLI — and the language servers exposed to it.
{
  inputs,
  pkgs,
  ...
}: let
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
  # (added post-25.11 upstream), delete `claudeLspPlugin` / `claudeWithLsp`
  # below, point `programs.claude-code.package` back at `llmAgents.claude-code`,
  # and move `claudeLspServers` verbatim into `programs.claude-code.lspServers`.
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
      command = "${pkgs.gopls}/bin/gopls";
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
  # `--plugin-dir` wrapper). We have no mcpServers, so the module's own
  # `finalPackage` passes this through unchanged.
  claudeWithLsp = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [llmAgents.claude-code];
    postBuild = ''
      mv $out/bin/claude $out/bin/.claude-wrapped
      cat > $out/bin/claude <<EOF
      #! ${pkgs.bash}/bin/bash -e
      exec -a "\$0" "$out/bin/.claude-wrapped" --plugin-dir "${claudeLspPlugin}" "\$@"
      EOF
      chmod +x $out/bin/claude
    '';
    inherit (llmAgents.claude-code) meta;
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
in {
  # Claude Code — Anthropic's CLI.
  #
  # The binary comes from llm-agents.nix (wrapped above to load our LSP plugin);
  # this module owns the *config* it writes to ~/.claude/settings.json. Keeping
  # the binary here (not in home.packages) avoids installing claude-code twice
  # into the profile.
  programs.claude-code = {
    enable = true;
    package = claudeWithLsp;

    settings = {
      theme = "auto";
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
  };
}
