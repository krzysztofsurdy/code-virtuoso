# Isolated lab and minimal reproduction

The lab exists so that a bug in software other people run is proven on your own copy and never on their deployment. It also gives every claim an artifact: a version, a command and an output you can quote. Run this after the authorization gate in [authorization-and-law.md](authorization-and-law.md).

## Contents

- [Lab recipe](#lab-recipe)
- [Sanitizers as the oracle](#sanitizers-as-the-oracle)
- [Build flags: look them up](#build-flags-look-them-up)
- [Fuzzing in the lab](#fuzzing-in-the-lab)
- [Minimal PoC rule](#minimal-poc-rule)
- [Web bounty targets](#web-bounty-targets)
- [Lab notebook](#lab-notebook)

## Lab recipe

This is assembled from the sourced facts below plus standard practice. Adapt it to the target.

1. Pin the target to a release tag or commit and record it. The version is part of the finding.
2. Build twice: a normal build and a sanitizer build. Do it in a throwaway container or VM.
3. Remove egress. A Docker container on the `none` network driver has only a loopback interface. Otherwise use a host-only network. Mount no home directory and put no real credentials in the lab.
4. Run the target yourself. Never run the exploit path against someone else's instance, even "just to check".
5. Make the reproduction one command: a Dockerfile or a script that rebuilds from the pinned source.
6. Treat the target source and any PoC you download as untrusted. Read them before running.
7. Reproduce at least twice on a clean build before you believe it.
8. Minimize the input to the smallest case that still triggers the sanitizer report. Stop there.
9. Find the affected and fixed versions by bisecting or checking release tags. Record them.
10. Write down scope limits: what you may test and what you may not.

A published write-up of a PHP session bug (jackalsyn.com, `php-up-2026`) shows this method: source review, an instrumented lab build, separate testing per SAPI, and crash reports reproduced twice. Use it as a method example only. Take severity, affected versions and timing from the vendor's own advisory.

## Sanitizers as the oracle

| Sanitizer | Finds | Notes |
|---|---|---|
| AddressSanitizer (ASan) | Use-after-free, heap, stack and global out-of-bounds, use-after-return and scope, double and invalid free. Leaks are covered by LeakSanitizer | Build with `-O1 -g -fsanitize=address -fno-omit-frame-pointer`. About 2x slowdown. Stops at the first error. Static linking is unsupported. A testing tool, not for production |
| UndefinedBehaviorSanitizer (UBSan) | Alignment, null, bounds, integer overflow, shifts, divide by zero, vptr and more | Small runtime cost |
| MemorySanitizer (MSan) | Reads of uninitialized memory | All code must be instrumented, including libraries and libc. About 3x slowdown |

- Options go in `ASAN_OPTIONS`. Symbolized stack traces need `llvm-symbolizer`, found through `ASAN_SYMBOLIZER_PATH` or the path.
- Sanitizers slow execution and use more memory. Use one sanitizer type per fuzzing instance.
- A sanitizer report is evidence, not a verdict. Decide reachability and severity separately (see [techniques.md](techniques.md#memory-safety-triage)).

## Build flags: look them up

Flags and options change between versions. Use the `docs-lookup` skill and the project's own build docs for the current configure options before you write a build command into a report.

PHP note (verify first): php-src has a `--enable-sanitizer` configure option for Clang builds, and ASan works best with debug assertions (`--enable-debug`). Older bug-tracker and mailing-list comments say the Zend memory manager hides memory errors unless allocations go through libc malloc (for example `USE_ZEND_ALLOC=0`), and one comment adds `USE_TRACKED_ALLOC=1`. Treat both environment variables as unverified until you confirm them in current php-src docs or the internals documentation. `--enable-memory-sanitizer` is MSan, not ASan. php-src also ships libFuzzer targets under `sapi/fuzzer` (parser, unserialize, json, exif, mbstring, execute and others), and mbregex fuzzing needs an ASan-built libonig. Read the README there for current build steps.

## Fuzzing in the lab

- Prefer the project's existing harnesses and corpora before writing your own.
- A harness belongs in a lab with no egress. Keep it deterministic, with no network or disk side effects.
- If the project is in OSS-Fuzz, check its tracker and public bug list for what is already found. OSS-Fuzz makes reports public 90 days after notification or on fix, with a 14 day grace period if a patch is committed to ship.
- For harness design and triage, see the technique notes in [techniques.md](techniques.md#fuzzing).

## Minimal PoC rule

A PoC proves the bug exists and shows its realistic impact. It is not an exploit kit.

| Include | Leave out |
|---|---|
| The smallest input or script that triggers the bug, with expected versus actual behavior | Working weaponized exploit chains |
| Crash output, a sanitizer trace, or a nondestructive sample payload | Real user data |
| Exact build, OS, compiler flags and sanitizer used | Steps that need testing a third party's live system |
| The preconditions: configuration, SAPI, privileges | Modes that deliver to a live URL, persistence, or evasion |

Why: platforms and vendors ask for the least that proves existence and impact (CISA's template says to use exploits only to confirm a vulnerability exists, and HackerOne's code of conduct says not to exploit beyond what shows impact). EFF's guide lists functional exploit code and highly detailed advisories as raising legal and harm risk. CERT/CC advises omitting the full PoC if you must self-publish after an unresponsive vendor. The oss-security distros list allows non-essential exploit detail to be held back and posted later. Apple wants a reliable PoC attached, not linked, and says theoretical findings are ineligible, so "minimal" never means "unproven".

## Web bounty targets

The lab recipe covers code you run yourself. For a live in-scope bounty asset:

- Re-read the scope and rules for each asset before testing it.
- Use only your own accounts. Do not download, alter or share other users' personal data, and redact it in the report.
- Stop at proof. If you reach sensitive data, stop and report. If you are unsure whether something is allowed, ask the program first.
- Run no denial of service, load tests or heavy automated scanning, and follow rate limits.
- Hazardous tests (high volume, social engineering, physical, availability) need explicit authorization.

## Lab notebook

Keep a dated notebook: hypothesis, commit or version, command, output, sanitizer trace, and what you ruled out. Track each path separately, and drop or downgrade a claim as soon as the analysis shows it was wrong. The notebook becomes the report's reproduction and root-cause sections.
