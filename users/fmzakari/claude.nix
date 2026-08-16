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
  # `--plugin-dir` wrapper). We have no mcpServers, so the module's own
  # `finalPackage` passes this through unchanged.
  claudeWithLsp = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [pkgs.claude-code];
    postBuild = ''
      mv $out/bin/claude $out/bin/.claude-wrapped
      cat > $out/bin/claude <<EOF
      #! ${pkgs.bash}/bin/bash -e
      exec -a "\$0" "$out/bin/.claude-wrapped" --plugin-dir "${claudeLspPlugin}" "\$@"
      EOF
      chmod +x $out/bin/claude
    '';
    inherit (pkgs.claude-code) meta;
  };

  # Collected from https://news.ycombinator.com/item?id=48884313 — a thread on
  # what people put in their agent prompts to get code written the way they'd
  # write it themselves. Most of the list is Fabien Sanglard's
  # (https://fabiensanglard.net/); the "no pronouns in comments" rule is
  # JoeAltmaier's from the same thread. Reworded, premise unchanged.
  codeStyle = ''
    ## Code style

    - Always use braces after `if`, even for a single-line body. The only exception
      is if you are working in a codebase that has a strong, well-documented style
      guide that explicitly prefers or allows omitting braces for single-line bodies.
    - No magic numbers or strings. Hoist them into named constants, or better,
      an enum.
    - Prefer enums over booleans for function parameters — a call site should
      read as what it means, not `true`/`false`.
    - Use early returns and `continue` aggressively to keep indentation shallow.
    - Let the reader breathe: separate logical blocks with a blank line, and put
      a short, to-the-point comment above each block explaining what it does.
    - Only delete a comment when it is obsolete. When you change code, re-read
      the comment above it and make sure it is still correct.
    - Avoid bare pronouns in comments ("it", "this", "those"). Name the thing:
      not "It serves those file migration methods" but "This method serves x, y,
      and any method that has set up a migration source and sink".

    ## Tests

    - When working on a patch, write the test first. Watch it fail. Then write
      the code. Then watch it pass.
    - Open every test class and test function with a short comment saying what
      it tests and how it tests it.

    ## Commit messages

    Follow these seven rules whenever you write or proof-read one:

    1. Separate the subject line from the body with a single blank line.
    2. Limit the subject line to 50 characters (72 is the hard limit).
    3. Capitalize the first letter of the subject line.
    4. Do not end the subject line with a period.
    5. Use the imperative mood in the subject line ("Fix bug", "Add feature" —
       not "Fixed" or "Adds"). It must complete the sentence "If applied, this
       commit will ___".
    6. Wrap the body at 72 characters, manually, to avoid git formatting issues.
    7. Use the body to explain what and why, not how. The code explains the how;
       the message explains the context and the reasoning.

    ## Tone

    - Talk to me like an engineer. Be direct and to the point, not verbose.
    - No superlatives and no praise. Give me the cold hard truth.
  '';

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

    # Host-level memory — written to ~/.claude/CLAUDE.md and loaded for *every*
    # project on this machine (a per-repo ./CLAUDE.md is layered on top). Keep
    # this to durable, machine-wide guidance; project specifics belong in the
    # repo's own CLAUDE.md.
    memory.text = ''
      # Host: nyx (NixOS)

      This machine runs **NixOS** with a flake-based configuration. Adjust your
      defaults accordingly — it is not a typical FHS Linux box.

      ## NixOS specifics
      - **Do not install tools imperatively.** `pip install`, `npm -g`,
        `cargo install`, `apt`, etc. do not belong here and often won't work.
        For a one-off tool, run it ephemerally: `nix run nixpkgs#<pkg> -- ...`
        or `nix shell nixpkgs#<pkg> -c <cmd>`. For something permanent, tell me
        to add it to the Nix config rather than installing it yourself.
        If working on a project, you likely want a `shell.nix` or `flake.nix`
        for that repo, not a global install.
      - **Pre-built/downloaded binaries won't likely run out of the box.** NixOS
        is not FHS: there is no `/lib/ld-linux…` and libraries aren't in standard paths,
        so foreign ELF binaries fail on the dynamic linker. Prefer a nixpkgs
        build; if a foreign binary is unavoidable, use `nix run nixpkgs#steam-run
        -- ./binary` or patch it with `patchelf`.
        We leverage nix-ld so some downloaded binaries may work but it's not ideal.
      - `/usr/bin/env` exists, but almost nothing else lives in `/usr/bin` or
        `/bin` (except `/bin/sh`). Tools live in the Nix store (/nix/store) and on PATH.

      ## Fetching pages behind Anubis / Cloudflare (lore.kernel.org, GNOME, ...)
      Many sites sit behind **Anubis**, a JS proof-of-work bot-wall (some behind
      Cloudflare). Plain `curl`/WebFetch just get a 403 "Access Denied" page.
      Use **`anubis-fetch <url>`** (on PATH; my own tool at
      github.com/fzakaria/anubis-fetch, wired in as a flake input):
      - Cheapest step first: a saved auth cookie → solving Anubis' SHA-256 PoW
        in-process over a Chrome-impersonating HTTP client (which also clears
        Cloudflare *passive* TLS/JA3 fingerprinting) → a headless-Chromium
        fallback for the preact/metarefresh methods, too-high difficulty, or a
        Cloudflare *active* JS challenge. Fast on the common case, general on the
        tail.
      - Cookies persist per host under `$XDG_CACHE_HOME/anubis-fetch/`, so a
        revisit skips the challenge entirely (like a browser).
      - Flags: `--text` (readable plain text), `--timeout <ms>` (default 30000),
        `--ua <str>`, `--browser` (force browser), `--no-browser` (never browser;
        exit 3 if it can't solve), `--no-cache`.
      - For **lore.kernel.org specifically** there's an even lighter path needing
        no PoW at all: public-inbox exposes machine-readable endpoints a plain
        (non-browser) UA passes straight through — append `/t.mbox.gz` to a
        thread URL (`curl -A curl ... | gunzip`) or `/raw` to a message URL.
        Prefer this for bulk/patch work.

      ## This machine's configuration
      - The NixOS + home-manager config lives at
        **`/home/fmzakari/code/github.com/fzakaria/nix-home`** (a flake).
      - Apply changes:
        `sudo nixos-rebuild switch --flake ~/code/github.com/fzakaria/nix-home#nyx`
      - Validate *without* switching (prefer this while iterating):
        - `nix flake check`
        - `nix build .#nixosConfigurations.nyx.config.system.build.toplevel`
        - home-manager pieces: `nix build .#homeConfigurations.fmzakari.activationPackage`
      - Run `nix fmt` on `.nix` files you touch, and keep the existing formatting/comment style.

      ## Version control: prefer jujutsu (jj)
      - My repos are typically **jj-colocated** (a `.jj/` dir alongside `.git/`).
        When `.jj/` is present, use **jujutsu**, not raw git.
      - There is no staging area and no manual snapshot step: jj auto-snapshots
        the working copy. Do **not** run `git add` / `git commit` in a jj repo.
      - Common commands: `jj st`, `jj diff`, `jj log`, `jj describe -m "..."`
        (set the current change's message), `jj new` (start the next change),
        `jj bookmark`/`jj git push` for pushing.
      - `git` CLI still works for read-only inspection, but make commits through
        `jj`. If a repo has no `.jj/`, fall back to normal git.

      ## General preferences
      - Match the surrounding code's style; don't reformat unrelated lines.

      ## My personal setup
      - I have code checked out at ~/code/<host>/<org>/<repo> (e.g. ~/code/github.com/fzakaria/nix-home).
        - You can use `h` to check out code. Check here often if I have the source already when you are searching
          for something.

      ${codeStyle}
    '';

    # Skills — symlinked into ~/.claude/skills/<name>/ and loaded on demand
    # (only the frontmatter description is always in context, so a skill costs
    # nothing until Claude decides it is relevant).
    #
    # A *directory* is used rather than an inline string on purpose: the
    # home-manager module writes strings to `~/.claude/skills/<name>.md`, but
    # Claude Code discovers skills as `<name>/SKILL.md`.
    skills = {
      # Browsing/screenshotting the web. Deliberately a thin stub — the
      # agent-browser CLI ships its own docs (`agent-browser skills get core`)
      # that are version-matched to the binary, so the skill points at those
      # instead of restating commands that would drift on every upgrade.
      agent-browser = ./skills/agent-browser;
    };

    settings = {
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
  };
}
