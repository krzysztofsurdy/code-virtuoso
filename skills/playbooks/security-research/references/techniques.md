# Techniques and which target they fit

A technique is a way of thinking. A tool is an instrument that automates part of it. "Taint tracking" and "variant analysis" are techniques. Semgrep and CodeQL are tools that automate them. Pick the technique for the target first, then choose a tool, and refresh the tool choice in the live-research step because tools, language support and licensing change.

This file covers methodology only. For payload-level depth, use the PortSwigger Web Security Academy and the OWASP Web Security Testing Guide (links at the end). Nothing here is a payload cookbook.

## Contents

- [Taxonomy: technique, tools, best fit](#taxonomy-technique-tools-best-fit)
- [Which fits which target](#which-fits-which-target)
- [Notes per technique](#notes-per-technique)
- [Memory-safety triage](#memory-safety-triage)
- [Reverse engineering closed targets](#reverse-engineering-closed-targets)
- [Read the threat model first](#read-the-threat-model-first)
- [Learning and depth](#learning-and-depth)

## Taxonomy: technique, tools, best fit

| Technique | Typical tools | Best-fit targets |
|---|---|---|
| Manual source audit, source-to-sink tracing by hand | editor, ripgrep, IDE cross-references, debugger | Any source-available code, logic and auth flaws |
| Sink-class-first review (pick a dangerous sink, walk back to the inputs) | grep, Semgrep, CodeQL | Deserialization, SQL, SSRF, path traversal, command execution, authorization checks |
| Rule or query based static analysis | Semgrep, CodeQL, Joern, Psalm taint, Progpilot, Exakat | Source-available code, language decides the tool |
| Variant analysis (turn one known bug into a hunt for siblings) | CodeQL (multi-repository variant analysis), Semgrep, grep, Joern | A codebase with a known past bug or CVE fix |
| Patch diffing, n-day analysis | git diff and log, BinDiff, Diaphora, Ghidra | Open source: git. Closed binaries: BinDiff or Diaphora |
| Coverage-guided fuzzing | libFuzzer, AFL++, honggfuzz, Centipede, OSS-Fuzz, ClusterFuzz | Parsers, decoders, file-format and protocol code, memory-unsafe code |
| Structure-aware fuzzing | libFuzzer custom mutators, libprotobuf-mutator, grammar fuzzers | Highly structured inputs: compressed, chunked, IDL, SQL, configs |
| Sanitizer as oracle | ASan, UBSan, MSan, LSan, TSan | Native code: turns silent corruption into a report |
| Dynamic analysis | gdb, lldb, rr, Valgrind, Frida, strace, Burp (web runtime) | Root-causing and instrumenting native or black-box targets |
| Differential testing, parser differentials | custom harness, Burp, comparing implementations | Several implementations of one spec: HTTP and URL parsers, proxies, caches, encoders |
| Recon to vulnerability: attack surface mapping | passive subdomain discovery, httpx, ASN and WHOIS, Burp crawl, content discovery | Public bug bounty web and API assets, in scope only |
| Authorization and logic testing (two or more test accounts, workflow abuse) | Burp, own test accounts | Access control (IDOR), auth bypass, business logic. Scanners miss these |
| Memory-safety triage (reproduce, minimize, classify, decide exploitability) | sanitizer build, rr, minimizers, casr | Use-after-free, out-of-bounds, type confusion, double free |
| Classification and severity | CWE, OWASP Top 10, CVSS | Every finding, at report time |
| LLM-assisted research (agent proposes hypotheses, debugger confirms) | LLM agent with a code browser and a debugger | Emerging. Best seeded by variant analysis |
| Reverse engineering of binaries and apps you own or are authorized to examine | rea driving Ghidra, IDA or Hopper, objdump, Rizin, JEB, Frida, BinDiff, Diaphora | Closed native binaries, Electron, .NET, Android APKs, firmware, WASM |

## Which fits which target

| Target type | First techniques | Evidence | De-prioritize |
|---|---|---|---|
| Native C or C++ library or parser (open source) | Fuzz with ASan and UBSan, then manual audit of hot parsers, variant analysis from past CVEs | Sanitizer report plus minimized input | Web-style recon |
| Language runtime or interpreter extension | Source audit of lifecycle and reference-counting code, the project's own fuzzers, sanitizer build, variant analysis from prior CVEs in the same subsystem | Sanitizer report, rr trace | Tools that do not support the language (CodeQL has no PHP support) |
| Web application code, for example PHP or Symfony userland | Sink-first source audit, Semgrep, Psalm taint, optional Joern | Taint path plus local reproduction | Fuzzing (low yield) |
| Web app or API under a bug bounty | Read scope, recon, entry-point mapping, multi-account authorization testing, logic abuse, targeted sink testing | Differing responses between your own accounts | Mass scanning, out-of-scope hosts |
| Closed binary or app bundle | rea over Ghidra, IDA or Hopper for static triage, patch diffing, dynamic tracing with Frida, black-box fuzzing | Crash plus diff evidence | Source-based taint tools |
| Protocol or spec with several implementations | Differential testing, parser-differential review | Disagreement between implementations | Fuzzing one implementation alone |
| Dependency or supply chain | Advisory feeds (OSV, GitHub Advisory Database), reachability analysis, variant hunting in sibling packages | Reproduction in your lab | Exploiting production |

## Notes per technique

Facts below carry a source row in [research-notes.md](research-notes.md). Tool facts change, so confirm them in the live-research step.

### Source audit and taint tracing

- A source is where attacker-controlled data enters. A sink is where it is executed or rendered. A taint flow is a path between them with inadequate handling. PortSwigger states this model for DOM XSS, and it applies server-side.
- Hand method: inject a unique marker at the source, find it in the code or runtime, set breakpoints, and follow the value to the sink.
- Psalm's taint model is a ready-made PHP checklist: sources include the request superglobals and `php://input`. Sinks include output, include, headers, SQL, shell, unserialize, eval, SSRF and file operations. Taint analysis assumes escaping is correct, so wrong escaping is a blind spot.
- Sink-class-first (pick one sink class, list every call site, walk back to inputs) is practitioner convention, not a named published method.

### Static analysis: when each fits

- CodeQL: path queries define a source and a sink and run data flow or taint tracking. Compiled languages need a successful build. Supported languages include C and C++, C#, Go, Java, Kotlin, JavaScript and TypeScript, Python, Ruby, Rust and Swift. PHP is not supported.
- Semgrep: taint mode needs sources, and sinks, sanitizers and propagators are optional. Analysis is function-level by default and cross-function or cross-file analysis is a paid tier. PHP is generally available. Check the current supported-languages page.
- Psalm: run `--taint-analysis` after the normal analysis passes. `--dump-taint-graph` helps debug a missed taint.
- Joern: builds code property graphs and has a taint engine. Its PHP support is rated medium maturity, C and C++ and Java very high.
- Variant analysis from a fixed bug: model the bug pattern as a query so it also matches logical variants. GitHub's multi-repository variant analysis runs a CodeQL query over many repositories, and it only works on repositories with CodeQL databases.

### Fuzzing

- libFuzzer is in-process and coverage-guided. The target is `LLVMFuzzerTestOneInput`. Build with the fuzzer, address and undefined sanitizers together. Keep a seed corpus and a dictionary for formats with magic values.
- A good target is deterministic, never exits, does no I/O in the loop, covers one format, and is fast. Under 10 executions per second per core is a warning sign, and about 1000 is typical.
- Checksummed, compressed or grammar-heavy inputs need structure-aware fuzzing (a custom mutator that parses, mutates and reserializes). It costs real manual work per input type.
- AFL++ is the maintained successor to AFL. Its workflow: choose instrumentation, use persistent mode, add comparison-solving options, run one sanitizer type per instance, minimize the corpus, and triage with minimizers and clustering.
- OSS-Fuzz and ClusterFuzz add continuous fuzzing, deduplication, minimization, regression bisection and automatic bug filing. OSS-Fuzz accepts established open-source projects with critical impact.
- Fuzzing fits parsers and native code with a callable entry point. It does not fit authorization, workflow state or anything without a crash oracle.
- Harness configuration decides what fuzzing can see. In Project Zero's Big Sleep write-up, a SQLite bug survived because the OSS-Fuzz harness build did not enable the affected feature.

### Patch diffing and variant analysis

- Project Zero found that about a quarter of the exploited zero-days it reviewed for 2020 were closely related to earlier public bugs. Vendors often block only the reported path, so a fix's siblings are worth hunting.
- Source diff for open source: read the fix commit, ask which invariant was violated, then grep or query for other places that violate it.
- Binary diff tools: BinDiff (works with IDA, Ghidra and Binary Ninja through BinExport) and Diaphora.
- Frame this as understanding fixes and finding unpatched siblings in code you are authorized to test, then reporting them. It is not a way to exploit users who have not received a fix.
- Big Sleep: an LLM agent was given a recent SQLite commit and asked to find similar unfixed bugs. It found one, and the maintainers fixed it before release. The authors call the result experimental.

### Web and API recon, in scope only

- Scope is the boundary. New assets and betas get less testing, but only listed assets are allowed.
- Parameter analysis: for each parameter note its type, its role (object id, URL, file, redirect, format) and the trust boundary it crosses.
- Access control (IDOR): map every object reference, use at least two test users that own different objects (plus a privileged one), and substitute identifiers across users.
- SSRF: look at parameters that take full URLs, parameters the server completes into a URL, XML, and server-side fetched headers. Keep the work at concept level.
- Business logic: test client-side-only validation, step skipping, unexpected values and function combinations. It needs human context.
- Parser differentials rank in PortSwigger's annual top techniques list, so differential testing deserves a slot when several implementations parse the same input.

## Memory-safety triage

1. Reproduce twice on a clean sanitizer or debug build.
2. Minimize the input (libFuzzer, afl-tmin or ClusterFuzz minimization).
3. Record the bug class and top stack frames. Bisect the regression range if you can.
4. Root-cause with rr or a debugger.
5. Check reachability from a documented untrusted input in a supported configuration.
6. Rate severity with the vendor's rubric plus CVSS. Record unknowns honestly.

Chromium's severity guidelines show how exploitability gets decided: reachability from untrusted input, sandbox context, whether user interaction is needed, and whether the read size is controlled. They also state that most crashes do not indicate vulnerabilities. A published PHP session write-up is a method example (source review, instrumented lab build, per-SAPI testing, crashes reproduced twice). Take severity and timing from the vendor advisory, not from that page.

The CWE Top 25 names the usual classes: out-of-bounds write (787), use-after-free (416), out-of-bounds read (125), classic overflow (120), NULL dereference (476). Look up the CWE for type confusion and double free on cwe.mitre.org instead of recalling the id.

## Reverse engineering closed targets

Use [rea](https://github.com/morluto/rea) when the target is a binary, app bundle, firmware image or package you own or are authorized to examine, and no source exists. Its README scopes it to software you own or are authorized to examine.

- It is an MCP server plus agent skills. `npx rea-agents setup` registers the server and workflow instructions and shows the proposed changes with backups. Review them and restart the agent.
- It needs Node.js 22.19 or later (or 24.11 or later, or 26 or later). Native analysis uses Hopper, Ghidra or IDA that you install and license yourself. It grants no license to those tools.
- Official sources are the morluto/rea repository, rea.tools and the rea-agents npm package. Check the package name before you run `npx`.
- Analysis runs locally, but the model provider your agent uses has its own data policy. Think before feeding it a vendor's binary or decompilation.
- Pair it with patch diffing (BinDiff, Diaphora) and dynamic tracing (Frida, rr). Do not use it in place of source audit or fuzzing for open-source targets.

For C and C++ review, variant analysis, sanitizer and fuzzing how-tos, point the user at trailofbits/skills and the Trail of Bits Testing Handbook (appsec.guide) rather than restating them.

## Read the threat model first

A vendor's definition of a security bug decides whether your finding counts. The PHP project's SECURITY.md, for example, says crashes from crafted code in destructors or error handlers, `unserialize()` on malicious input, `open_basedir` and `disable_functions` bypasses, and FFI misuse are not security issues, and it asks for short reports with a minimal reproducer. Read the target's policy before spending hours, and re-read it each time because policies change.

## Learning and depth

| Resource | Use for |
|---|---|
| [PortSwigger Web Security Academy](https://portswigger.net/web-security) | Free labs per web topic, payload depth, Burp Community Edition is enough for many labs |
| [OWASP Web Security Testing Guide](https://owasp.org/www-project-web-security-testing-guide/) | Test procedures for each web area (v4.2 stable, v5.0 in development) |
| [PortSwigger research and annual top web hacking techniques](https://portswigger.net/research/top-10-web-hacking-techniques) | New web research each year |
| [Trail of Bits Testing Handbook](https://appsec.guide) | Static analysis, fuzzing, sanitizers, Burp |
| [Google fuzzing docs](https://github.com/google/fuzzing) and [AFL++ docs](https://github.com/AFLplusplus/AFLplusplus/blob/stable/docs/fuzzing_in_depth.md) | Harness design, structure-aware fuzzing, workflow |
| [The Fuzzing Book](https://www.fuzzingbook.org/) | Free online, mutation, grammar and coverage fuzzing |
| [Hacker101](https://www.hacker101.com) and [pwn.college](https://pwn.college) | Free practice. pwn.college asks learners not to publish challenge write-ups |
| [CTFtime](https://ctftime.org) | Events, ratings and write-up archive |

Project Zero's careers page advises studying fixed bugs through open-source trackers and Project Zero's bug reports, practicing adversarial code reading, and fixing bugs in open-source projects. Refresh this table in the live-research step.
