# aerc: a terminal email client, configured for Gmail and geared towards
# reading/reviewing kernel-style mailing lists (LKML et al.).
# https://aerc-mail.org/
{
  pkgs,
  osConfig,
  ...
}: let
  aerc = pkgs.unstable.aerc;
  filters = "${aerc}/libexec/aerc/filters";
  b4 = "${pkgs.b4}/bin/b4";

  # The Gmail app password is provided as an agenix secret at the NixOS level
  # (see machines/nyx/configuration.nix). We assume it always exists.
  passwordFile = osConfig.age.secrets."gmail-app-password".path;
in {
  accounts.email.accounts.gmail = {
    primary = true;
    flavor = "gmail.com";
    realName = "Farid Zakaria";
    address = "farid.m.zakaria@gmail.com";
    userName = "farid.m.zakaria@gmail.com";

    # `cat` the decrypted agenix secret; nothing is written to the nix store.
    passwordCommand = "cat ${passwordFile}";

    # Gmail exposes its special mailboxes under the [Gmail] hierarchy.
    folders = {
      inbox = "INBOX";
      drafts = "[Gmail]/Drafts";
      sent = "[Gmail]/Sent Mail";
      trash = "[Gmail]/Trash";
    };

    aerc.enable = true;
  };

  programs.aerc = {
    enable = true;
    package = aerc;

    extraConfig = {
      general = {
        # Required: home-manager writes accounts.conf into the (world-readable)
        # nix store, so aerc's default 0600 permission check must be relaxed.
        # This is safe because the password is only ever fetched via
        # passwordCommand and never stored in the file itself.
        unsafe-accounts-conf = true;
      };

      ui = {
        styleset-name = "dracula";

        # Gmail's IMAP does not implement server-side THREAD well, so build
        # the thread tree on the client instead.
        threading-enabled = true;
        force-client-threads = true;
        threading-by-subject = true;
        # Newest threads at the bottom, and show the surrounding thread
        # context even when only part of it matched a search -- handy when
        # jumping into the middle of a long kernel discussion.
        reverse-thread-order = true;
        show-thread-context = true;

        this-day-time-format = "           15:04";
        this-week-time-format = "Mon Jan 02 15:04";
        this-year-time-format = "Mon Jan 02 15:04";
        timestamp-format = "2006-01-02 15:04";

        spinner = "[ ⡿ ],[ ⣟ ],[ ⣯ ],[ ⣷ ],[ ⣾ ],[ ⣽ ],[ ⣻ ],[ ⢿ ]";
        border-char-vertical = "┃";
        border-char-horizontal = "━";
      };

      # aerc ships purpose-built email filters, referenced directly by store
      # path. `colorize` is email-aware: it highlights quoted text *and* unified
      # diffs, which is exactly what you want when reading inline patches on a
      # mailing list. (This is why we prefer it over delta here -- delta expects
      # a full git diff and does not understand email quoting.) The `html`
      # filter already bundles w3m via its wrapper, and `catimg` renders inline
      # images -- so no extra home.packages entries are needed.
      filters = {
        "text/plain" = "${filters}/colorize";
        "text/calendar" = "${filters}/calendar";
        "text/html" = "${filters}/html";
        "message/delivery-status" = "${filters}/colorize";
        "message/rfc822" = "${filters}/colorize";
        "application/mbox" = "${filters}/colorize";
        "application/x-patch" = "${filters}/colorize";
        "image/*" = "${pkgs.catimg}/bin/catimg -";
      };
    };

    # aerc does NOT merge a user binds.conf with its defaults -- if the file
    # exists, it is used verbatim and the built-in navigation keys (j/k, arrows,
    # Enter, /, q, ...) are lost. So seed our binds.conf with aerc's shipped
    # defaults, then append the kernel patch workflow binds.
    #
    # Kernel patch workflow via b4 (https://b4.docs.kernel.org): pipe the
    # message to b4, which reads the mbox from stdin, extracts its Message-Id,
    # and pulls the *entire* series from lore -- latest revision, collected
    # review trailers, and any follow-up fixups -- instead of applying just the
    # one email under the cursor. Launch aerc from inside the target git tree so
    # these act on the right repo. Keys sit in the patch namespace (aerc's own
    # patch binds are pl/pa/pd/pb/pt/ps); pA = fetch + apply the series, pM =
    # fetch it into an mbox for review without applying. The repeated [messages]
    # / [view] headers are fine: aerc parses binds with go-ini, which merges
    # duplicate sections into the ones from the defaults above.
    extraBinds = ''
      ${builtins.readFile "${aerc}/share/aerc/binds.conf"}

      [messages]
      pA = :pipe -m ${b4} shazam -<Enter>
      pM = :pipe -m ${b4} am -<Enter>

      [view]
      pA = :pipe -m ${b4} shazam -<Enter>
      pM = :pipe -m ${b4} am -<Enter>
    '';
  };
}
