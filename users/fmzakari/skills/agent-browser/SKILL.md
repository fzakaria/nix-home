---
name: agent-browser
description: Drive a real headless Chromium to browse, interact with, and screenshot web pages — click, type, fill forms, wait on elements, run JS, read the accessibility tree, capture annotated screenshots or PDFs. Use when a page needs JavaScript, a login, or interaction to reach, when the user asks to see how a page looks, or when testing a locally running web app. Do NOT use for plain read-only text from a static public page — WebFetch/WebSearch are cheaper.
---

# Browsing the web with agent-browser

`agent-browser` is on PATH (installed from `llm-agents.nix`, see
`users/fmzakari/claude.nix`). It drives a headless Chromium from the Nix store
via a background daemon that persists between commands, so the first call is
slow and the rest are fast.

## Read the bundled docs first

The CLI ships its own instructions, version-matched to the binary. Do not guess
commands from this file — it deliberately says almost nothing, so it can never
go stale. Before the first browser command in a session, run:

```
agent-browser skills get core --full
```

That is large (~120KB). For a quick job the overview alone is often enough:

```
agent-browser skills get core
```

Specialized guides exist for other jobs — `agent-browser skills list` shows
them. Notable ones: `electron` (VS Code, Slack, Discord desktop apps),
`dogfood` (systematically explore a web app hunting for bugs), `derive-client`
(reverse-engineer a site's internal API by recording traffic).

## The shape of the loop

Enough to orient before loading the real docs:

```
agent-browser open https://example.com     # navigate
agent-browser snapshot                     # accessibility tree, elements get @eN refs
agent-browser click @e2                    # act on a ref from that snapshot
```

Prefer `snapshot` over `screenshot` for finding things — it is text, so it
costs a fraction of an image, and its `@eN` refs are what the action commands
take. Reach for a screenshot when the *appearance* is the question (layout,
styling, "does this look right"), not the content.

```
agent-browser screenshot --annotate ./shot.png
```

`--annotate` overlays numbered labels on interactive elements and prints a
legend mapping each `[N]` back to its `@eN` ref, so one image serves both
purposes. Read the resulting file to actually see it.

## Close when done

The daemon self-terminates after an hour idle, but a browser left open holds
memory on the user's desktop machine. Close it once the task is finished:

```
agent-browser close --all
```
