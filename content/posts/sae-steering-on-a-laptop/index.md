---
title: "Steering GPT-2 with a sparse autoencoder, on a laptop"
date: 2026-09-17T22:27:55-07:00
tags: ["ai", "interpretability", "building"]
description: "tiny experiments with SAEs - doom loop steering"
draft: false
---

Spent an evening steering GPT-2 small with a sparse autoencoder on an M1 laptop. CPU only, 100ms per forward pass. Recap:

- The setup: GPT-2 small, layer 8 residual stream, a public SAE with 24k features (gpt2-small-res-jb via sae_lens). Neuronpedia has an auto-generated label for every feature, so you can eyeball what a feature is supposed to mean.
- The loop: inspect what fires on a text, contrast two texts to find candidate features, steer by adding a feature's decoder direction to the residual stream during generation, score the outputs. Four scripts, 50 lines each.
- First lesson came from cranking one feature to strength 1000. Feature 3917 is labeled "sanctuary for undocumented immigrants". Output: "San francisco is a city of ctuaryctuaryctuary". It is a token detector for the bare `San` token, fires at exactly 20.0 in every context, and its direct effect on the logits is "ctuary". The label describes the training contexts, not the mechanism.
- Hypothesis I had was that the feature was for a token specifically, similar to edge detectors in vision models: a small model at a middle layer captures tokens, not concepts, the way early conv layers capture edges and not faces. Half right. The residual stream is additive, nothing ever subtracts the token embedding out, so token features show up at every layer, not just the early ones. Ranking features by peak activation selects for token detectors at any depth. Contrast finds the concepts.
- The target: get a neutral prompt ("San Francisco is a city") to produce doom loop prose without the prompt asking for it. Contrasting a doom paragraph against a thriving one mostly surfaced the words I swapped (empty/full, tent/cafe), plus a feature for programming loops firing on "doom loop". 2019 GPT-2 has never heard the narrative, eh.
- Steered with four features at once, each around 20-25: SF, drugs, fleeing danger, leaving a place. Baseline writes about food, gentrification and bike accidents. Steered: "the homeless are caught in an economic war zone". Doom vocabulary went from 0.4% of words to 4%.
- Ablation: drugs alone matched the four-feature steer at half the fluency cost. Confirmed that drugs feature only can push the LLM towards doom loop.
- Learning - on a small model a single concept can drive a strong response, a lot of concepts are not encoded.
