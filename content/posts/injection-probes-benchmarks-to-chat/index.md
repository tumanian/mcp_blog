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
