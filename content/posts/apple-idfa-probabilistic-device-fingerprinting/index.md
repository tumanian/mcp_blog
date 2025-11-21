---
title: "Apple and IDFA - Probabilistic Device Fingerprinting"
date: 2025-11-21T09:00:00-08:00
tags: ["adtech", "probabilistic-algorithms", "minhash", "war-stories"]
description: "How I approached probabilistic device identification at Flurry in 2012, using MinHash and Jaccard similarity to match apps across devices without persistent identifiers."
draft: false
---

All around the AdTech and Martech world, everyone is preparing for apple discontinuing IDFA. The ground is shaking, AdTech stocks are failing, experts are posting on LinkedIn. Yet, it's not the first time Apple is pulling the rug from AdTech. When I first started in the field, the device UUID was the main identifier for a device. Then it was the MAC address of the device. Then Apple announced IDFA and IDFV, and blocked the collection of the MAC addresses. After the n+1 iteration of this, all companies got tired of this and started creating synthetic ids for the devices, which could be remapped to the new id space without backend changes. Yet, every time Apple pulled the rug, there was a massive scare and troves of engineers thrown at the transition.

Around 2013(or 2012, don't remember exactly), it came my turn to be thrown at the problem. One day Apple announced that IDFA can only be used by advertisers and not for analytics. Tomato tomato, but my manager goes into a meeting on one sunny afternoon and comes out with news that the All-Mighty-Execs anointed me - semi-junior eng with some (weak) ML chops to solve the IDFA going away issue. More specifically, the problem was not to identify the device itself - but to recognize that two apps were running on the same phone without using IDFA.

What I describe below was never built or launched to production - by the time we got to it, Apple relaxed its enforcement of IDFA rules. The Adtech world continued ticking as it used to, and I got reassigned to another data science boondoggle. So consider these my musings on how the probabilistic identification could work. In the spirit of disclaimers, I haven't looked into this topic for the last seven years, and the signals that Apple allows to collect are probably different these days.

So let's state the problem: every time an app is launched, the analytics SDK collects some signals about the device - device type, screen size, battery level, last device start timestamp(in minute resolution). It sends these metrics to the server, which for every request, logs the source IP address. The SDK also sends IDFV to identify app instance. Problem: based on these signals, identify whether the apps' signals come from the same device.

Sounded simple enough - we could pick a few of the signals, hash it together and use the hash as a synthetic id. It turned out that the signals available either didn't have enough differentiating power ( screen size and device version) or were too fast-changing like IP addresses.

In popular thinking, using IP addresses is considered the most foolproof way to track a device, but they were the most fickle of all - for a given phone, we could never read stable IP addresses; they would change multiple times over days, hours. While we were collecting IP, but we could never say an IP address of what it was exactly.

We did see there was some recurrence in the IP addresses for the same device. The device would have an IP address in the morning, then a different one in the afternoon, but then the IP address would repeat in the evening.

One of the hypotheses we had at a time that source IP address we got on the network was the mobile tower's address that the device was connected to, and as people were moving around the IP addresses would change. So the morning IP address and the evening IP addresses corresponded to a person commuting. This was a decent enough hypothesis, but the signal from this was still pretty weak.

Since we couldn't rely on IP addresses, the only hope was for the device boot timestamp. However, the boot timestamp had a minute-level resolution, which led to millions of devices having the same boot timestamp. On the other hand, the boot timestamp would change with every restart, making any derived id unusable.

At this point I was about two weeks into looking at all of these signals, and no cigar yet. The all-mighty-execs were getting rowdy and demanding the magic ML dust be applied, or else!

If execs want ML, we give them ML, and down the rabbit hole we go. The problem looked like a clustering issue (use the similarity of signals to map to the same device), or nearest neighbor matching. Both of these approaches had the same problems: One - how do you encode IP addresses while making note that the distance in the ip addresses is not an indicator of device similarity, and on the other hand how do we deal with the dimensionality when for some very active users you have a lot of samples. This was looking to be a hell of playing around with dimensionality reduction (PCA?) and weird distance measures, while the execs were getting hungrier, and I had to start sending weekly updates. Execs would walk around my desk and ask things like "can we use the battery level reading to identify devices?". Scary.

One thing that popped when thinking about the nearest neighbor, is that we are interested in how often the signals from apps match. The SDK could collect boot timestamps over the lifetime of the app, and we could find another app running on the same device by the best match of the sets of boot timestamps. In fact, every time the device was restarted we would get a new boot timestamp that would make the match signal stronger.

Consider two devices at time t1 - both have the same boot timestamp, so we can't rely on it to identify the device. But as devices restart at t2 and t3, the apps from the same device have a better matching set of timestamps. Apps are installed and uninstalled at random, so the boot timestamps collected by the apps will intersect, but will not always match.

To identify the device, look at the boot timestamps that the SDK collected over the lifetime of the app, and match with boot timestamps that were collected by the other apps. If the size of the intersection is large enough, the apps are running on the same device. Of course, the size of the intersection is meaningless, so we need to divide it by the total size of sets - in essence: Jaccard similarity.

This was a good lead. Moreover, we could use the same logic to add IP addresses to the mix. Hey, we didn't even care what the signals were, as long as they were discrete, we could add them. Everything. Everything except the battery level.

The next step was to check out if the data supports it. I wrote a piece of MapReduce that would sample a bunch of user data, about 500k, and compute the similarity of the signals for cases where IDFA matched vs not matched. The job ran for a day. I send another anxious status update to execs.

The pairwise scores came through. Pairs of sets from apps on different devices clustered near zero similarity. Pairs from apps on the same device clustered near one. Clean separation. This meant that if we defined a threshold on the similarity score we could pick the FP/FN rate of the system. And because the set of signals for an app grew over time (as the device moved around and had different ip addresses, or kept restarting), the accuracy of the fingerprinting would grow over time too. A new app install would start its life as unidentified, and over time it would accumulate more signals and match another app. That sounded cool. I sent an excited email to execs.

Now it was the time to design a system around this. We already had a microservice (it was just a service, but I am calling it micro- because buzzwords) that would find out internal device ids every time the SDK dialed back home. On the backend we had a simple table that translated external ids to the internal id space. Since it was doing point lookups, it was pretty fast (10ms or around there) - and basically every request to store any data would go through the system. I needed to build something that would plug into this, but not slow the system down. Obviously doing pairwise set similarity comparisons with ALL the devices that we have in the system wouldn't work. Even mumbling this would get you laughed away from the boat.

Even as a batch job that would be too heavy. To find out the best match we would need to full scan our 'users' table (where each row contained information for a device we are tracking and had probably a billion records by then), and then do billion*billion comparisons, and then find the pairs with the highest Jaccard score. This was hard. I wished I never touched data engineering, and was a chill PHP developer living a chill life.

As I was reading the Wiki page on Jaccard index the following jumped at me:

> The MinHash min-wise independent permutations locality sensitive hashing scheme may be used to efficiently compute an accurate estimate of the Jaccard similarity coefficient of pairs of sets, where each set is represented by a constant-sized signature derived from the minimum values of a hash function.

What is this sorcery? I am going to spare you the description on how it works - a great explanation is [here](http://infolab.stanford.edu/~ullman/mmds/ch3n.pdf), but in essence, a min-hash for a given input set will produce a fancy hash that will collide with another min-hash with a probability that is proportional to the Jaccard similarity of the input sets. This also means we can pick a similarity threshold and find the parameters for min-hash so that when we generate the hash it matches another only if the signal sets (IP addresses, boot timestamps) are over X percent similar. Further, because variations of min-hash support weighting, we could assign the boot timestamp a higher weight than the IP addresses.

The system built on this would work as follows:

- We would seed the system by reading the historical device signals once and computing their min-hash.
- Create a mapping from min-hash to internal device ids, and merge together the data from device ids that have the same min-hash, 'healing' the data.
- The SDK would collect the boot timestamps and the IP addresses on the device. Once the number of elements is large enough (there is no point of using the method if there is one data point) compute a min-hash and send it with the request. If a matching min-hash exists, find the internal id that matches best. If it doesn't, store the data as a new device. When the 'healing' process runs, it will merge the new device id with the old.

This was a good battle plan. I shoot an exciting email to execs, and went home with a feeling of excitement and wonder.

The next day my manager walked into the room and announced the project canceled. In this episode of catch and release, Apple let us live another day, as it usually does.
