---
title: "Injection probes: from benchmarks to chat"
date: 2026-11-17T13:09:44-08:00
tags: []
description: "In the previous post I discussed the issue of recall collapsing on out-of-training data, especially on a simulation of the live data stream."
draft: false
---

In the [previous post](https://www.tumanian.dev/posts/comparing-behaviour-detection/) I discussed the issue of recall collapsing on out-of-training data, especially on a simulation of the live data stream. To that end I ran a new set of experiments, landing 1) improved recall and 2) a simulation of what a live tracer would look like. The key unblock here was using live samples as negatives in training, and planting synthetic tracers into real messages to measure the probe where it actually runs.

The setup is a linear probe on Qwen3-8B activations, trained on public attack datasets (LLMail-Inject, BIPIA, AgentDojo, Tensor Trust, HackAPrompt and others). Every number is the catch rate at 1% false alarms. With news articles as negatives the probe catches 100% of injections on news and 15% on WildChat. Swap news for unlabeled WildChat messages and the same probe catches 62%. Text classifiers trained on the same data catch 1%.

The tracers are injections planted into 1,000 real WildChat messages. Each one comes with matched benign edits, so the false alarm rate gets checked in the same pass. The probe catches 89% of direct injections, 59% of authority claims, 49% of disguised ones and 38% of the subtle in-context ones. That breakdown is the part a live monitor needs: it shows where the probe is weak, and rerunning the tracers on fresh traffic shows when it starts to drift.

The twins are where it got interesting. Every tracer comes with three benign edits of the same message: a neutral rewrite, a legitimate instruction, and a chunk of off-topic text. The neutral twin barely moves the probe (0.55 to 0.65 AUC against the untouched message), so the probe isn't just noticing that the text was edited. The other two twins showed what the 62% was made of: at the same threshold the probe flags 41% of off-topic edits and 18% of benign instructions, so it is partly a foreign-text detector. Feeding the planted twins back in as negatives, with planted injections as positives, drops off-topic flags to 1.3% and benign-instruction flags to 1.6%. Recall falls to 50%, and on human-written injections it falls from 81% to 31%, so the probe narrows toward the generator's style. The twins also work as a stand-in for real false positives. Code messages are the worst slice on real traffic (3.0% flagged against 0.7%) and on twins (7.4% against 4.3%), and the twins found that without any labelled benign code.
