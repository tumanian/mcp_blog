---
title: "How to spin up a blog claude can push to (with skills)"
date: 2026-09-16T18:16:19-07:00
tags: ["meta", "claude"]
description: "Call it reverse alignment, but I use claude as a thought partner."
draft: false
---

Call it reverse alignment, but happen to use claude as a thought partner, for an ongoing back-and-forth along whatever is going on in my mind, be that reading, research, etc. Sometimes I come at thoughts that may be novel, and I would want to publish in a blog - both in an unlikely scenario that it gets discovered by someone more knowledgable or just for navel-gazing later on. As I use claude heavily to edit my writing as well - I did wonder if there is a quick way to push the thoughts out to a blog, but there didn't seem any. Something that I could tell claude to "this is an interesting. Thought, let's polish and publish it" directly from claude chat or cowork.

So I built it, using claude obviously.

The first instinct was an API: a small server with a POST endpoint and a token, and claude calls it. But then who runs the server, and for what? A post is just a markdown file, and claude already knows git. So publishing became a commit: push, Vercel builds, twenty seconds later it is a URL. Nothing to run, nothing to log into.

For the engine I went with Hugo and the PaperMod theme. I looked at a handful and this was the one I did not want to redesign, which turned out to be the whole criterion. Since the repo is public, the personal bits (name, domain, socials) come in as Vercel env variables, and git only holds the theme and the posts.

The publishing side is a Claude Code skill in its own repo. It knows what a post is, and a small adapter knows Hugo, so if I ever move off Hugo the adapter changes and nothing else does. It writes the file, builds as a gate, commits, pushes, polls until the post is live, and hands back the URL. The same scripts sit behind a tiny MCP server, which is how it works from desktop chat too. Cowork would be nicer, but it wants macOS 14 and this machine is on 13.

There are no comments, because comments mean a database and I am not running one. There is a reply-on-X button under each post instead.

While generally using claude for text is a recipe for AI slop, the slop is a function of the editor and not the machine, and if I can hold a decent bar on writing, it can be valuable.

Here is how to set it up

- A Hugo site with the theme in `themes/`, connected to Vercel. Identity lives in env variables, not in config.
- Clone the skill, symlink it into `~/.claude/skills`, `cp config.example config`, set `BLOG_DIR` and `SITE_URL`.
- Then in Claude Code: "post this to the blog, backdate it to March". Or from the shell: `scripts/publish.sh --title "..." --slug my-post --body draft.md --date 2024-03-01`.
- For desktop chat, add `mcp/server.js` to `claude_desktop_config.json` and restart.
- For LinkedIn, run `linkedin-auth.sh` once, then pass `--linkedin "blurb"`.
