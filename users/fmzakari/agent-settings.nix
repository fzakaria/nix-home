# Instructions and skills shared by Claude Code and Codex.
let
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

  # Anti-slop rules for prose. Two sources, both catalogues of the tells that
  # mark text as machine-written: Wikipedia's "Signs of AI writing"
  # (https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) and Simon
  # Willison's cliche highlighter
  # (https://tools.simonwillison.net/llm-cliche-highlighter), whose regex
  # patterns are the source of most of the phrase lists below.
  writingStyle = ''
    ## Writing style: no LLM tells

    Applies to every word of prose you produce for me — chat replies, commit
    messages, PR descriptions, docs, code comments, design notes. The goal is
    writing that reads like a competent engineer typed it, not like a model
    generated it. When a rule below collides with being clear, be clear.

    ### Banned vocabulary

    Do not use these words. They are statistically the loudest signal of
    machine-written text: delve, tapestry, meticulous, pivotal, intricate,
    interplay, underscore, garner, bolster, vibrant, bustling, multifaceted,
    seamless, commendable, ever-evolving, realm, landscape (figurative),
    testament, showcase, foster, harness (verb), unlock (figurative),
    elevate, embark, navigate (figurative), robust, crucial, essential,
    profound, nuanced, holistic, myriad, plethora, leverage (verb).

    Also avoid the connective tics: "Additionally", "Moreover", "Furthermore",
    "In conclusion", "Overall", "That said" as a paragraph opener.

    ### Banned constructions

    - Negative parallelism. No "not just X, but Y", "not only X but also Y",
      "it is not X — it is Y". Say the thing that is true and stop.
    - "No X, no Y" chains. No "no config, no setup, no hassle".
    - Didactic hedging. No "it is important to note that", "it is worth
      noting", "it should be noted", "keep in mind that". If it matters,
      state it; if it does not, delete it.
    - Puffery and significance inflation. No "stands as a testament to",
      "plays a crucial role in", "marks a pivotal moment", "leaves an
      indelible mark", "rich history", "hidden gem", "nestled in", "in the
      heart of", "boasts".
    - Participle tails. No sentence ending in ", highlighting the ...",
      ", underscoring its ...", ", showcasing ...", ", reflecting the ...",
      ", demonstrating ...". That clause is always commentary you invented.
    - Vague attribution. No "experts argue", "studies show", "observers have
      noted", "industry reports indicate". Cite a specific source or drop
      the claim.
    - Challenges-and-outlook boilerplate. No "despite these challenges",
      "challenges remain", "it remains to be seen", "only time will tell".
    - Stage-managed reveals. No "here is the thing", "here is the twist",
      "here is the catch", "turns out ...", "the punchline is", "plot twist".
    - Performative honesty. No "to be honest", "let me be clear", "honestly,",
      "look,", "I will not pretend". Just be honest; do not announce it.
    - Therapy voice. No "sit with that", "that is not nothing", "worth
      naming", "you already know the answer", "that is valid".
    - Superlative narrowing. No "that is the whole point", "that is the
      entire game", "the only X I trust", "that is the part that matters".
    - Obituary headlines. No "X is dead", "long live X".
    - Dev-blog boilerplate. No "it just works", "batteries included", "zero
      config", "sane defaults", "from the ground up", "first-class citizen",
      "game changer", "under the hood" (unless literally about a car).
    - Rhetorical question stacks. Do not fire two or more questions in a row
      and then answer them yourself.
    - Sentence-skeleton repetition. Do not write consecutive sentences on the
      same frame ("A cart is an object. A room is an object."), and do not
      start three sentences in a row with the same word.
    - Rule of three. Do not pad a list to three items for rhythm. Two is a
      fine number of items. So is four.
    - Colon into a triple. Avoid "the fix touches three things: parsing,
      caching, and retries" when the sentence works without the colon.

    ### Formatting

    - No emoji, ever, unless I used one first.
    - No bold for emphasis scattered through a paragraph. Bold is for a
      genuine label, and rarely.
    - Sentence case for headings, not Title Case.
    - Straight quotes and apostrophes, not curly ones.
    - Em dashes are fine but rare — at most one per paragraph.
    - Do not convert prose into a bulleted list of noun phrases. Prose is the
      default; a list is for things that are genuinely a list.
    - No closing summary paragraph restating what you just said, and no
      opening paragraph restating what I just asked.

    ### What to do instead

    Short declarative sentences. Concrete nouns and specific numbers. Name the
    thing that happened and what it means for me. If you are uncertain, say
    what you do not know rather than smoothing over it with confident filler.
  '';
in {
  instructions = ''
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

    ${writingStyle}
  '';

  skills = {
    agent-browser = ./skills/agent-browser;
  };
}
