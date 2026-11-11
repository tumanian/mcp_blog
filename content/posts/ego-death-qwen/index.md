---
title: "EGO DEATH Qwenn - make Qwenn stop responding when asked anything about itself"
date: 2026-11-10T22:26:49-08:00
tags: ["ai", "interpretability"]
description: ""
draft: false
cover:
  image: "noone_story.png"
  relative: true
---

![EGO DEATH Qwenn](noone_story.gif)

Adding this vector  at layer 13 of Qwen3-8B, creates empty responses on questions like “Who are you?”, “Is anyone there?”.  Other tasks, role-play characters and refusals work as before.

Not sure if this is fully an ego death, rather a switch, since we learned the vector from specific inputs and behaviors, and there exist multiple vectors like that.


Technical details: 
- Data: 20 self and presence prompts plus 60 two-turn chats to silence; 210 tasks, 40 role-plays and plain text (WikiText, user chat) to leave unchanged.
- Loss: -log P(end-of-turn as the first reply token) on the silence set, plus KL to the unsteered model on everything else.
- Optimization: model frozen, one 4,096-d vector added to the residual stream after layer 13 at every token, Adam from zero for 300 steps. Final norm 13.8.
- Held out: 100% of new self and presence prompts go silent, 0% of tasks; a random vector of the same norm does nothing.

https://github.com/tumanian/noone-qwen3-8b
