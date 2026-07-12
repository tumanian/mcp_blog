---
title: "Paper Reader"
date: 2026-07-12T09:00:00-07:00
tags: ["ai", "tools", "building"]
description: "How I built paper-reader.dev with Claude and Cursor in two weeks, and what I learned about working with AI coding agents."
draft: false
---

I built [paper-reader.dev](https://paper-reader.dev) to help me parse through ML papers. As a backend engineer by training, building anything with UI has always been out of reach for me. In one or two weeks with modern tools, I opened up the other half of my craft.

The tool: select anything to explain a passage, break down the math symbol by symbol, or pull up what a citation actually says. No sign-in required.

How it came to be: I asked Claude if there was a good tool for reading ML papers with an AI alongside you. There sort of was, but nothing did the thing I actually wanted. So I asked the obvious follow-up: would this be hard to build? Claude said no, and then more or less dared me to do it. So I did.

The whole thing was built only on Claude and Cursor. Takeaways from the process:

1. Proper software engineering (testing, modularity, observability) is as important as before to get great results from LLMs. Your agent is like a new team member onboarding with every session, so having a good codebase speeds things up.

2. Zero to proof of concept takes seconds, polish still takes time, but the fast feedback loops keep the process rewarding.

3. AI can't beat humans at what they are best at (for now), but can make them good at what they couldn't do before.
