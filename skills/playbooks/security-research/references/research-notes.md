# Research notes: security-research

Date: 2026-10-22
Depth: deep
Research skill used: yes (three parallel research passes, notes sr1-techniques, sr2-disclosure, sr3-reputation, each with its own source ledger)
Prior-art search: done (repo, installed skills, `npx skills find`, GitHub reads)

## Contents

- [Scope](#scope)
- [Gate approval record](#gate-approval-record)
- [Baseline and reason to exist](#baseline-and-reason-to-exist)
- [Prior art](#prior-art)
- [Fact ledger](#fact-ledger)
- [Not confirmed](#not-confirmed)
- [Left out](#left-out)

## Scope

Covers: a gated loop for authorized vulnerability research (authorization gate, mandatory live research, target selection and hunting, lab reproduction with a minimal PoC, classification, coordinated disclosure and CVE, post-patch write-up), a technique and target-fit taxonomy, the lab recipe, feeds to monitor, and the authorization and legal anchors as general information.

Does not cover: payload catalogs (linked to PortSwigger Academy and OWASP WSTG instead), exploit development, defensive secure-coding (the `security` skill), scanning of live systems, and legal advice.

Questions the research answered: which techniques fit which targets and which tools automate them; how scope and safe harbor work and where the legal line is; how coordinated disclosure, embargoes and the CVE and CNA path work now; what earns or costs trust; how to set up a lab; which sources to monitor; whether a better skill already exists.

The skill stays open by design. The 2025 to 2026 changes in the ledger (HackerOne disclosure guidelines, NVD enrichment, curl ending its bounty, EU CRA reporting) are the evidence that a frozen list goes stale.

## Gate approval record

No user was available. The maintainer approved the skill-writer confirmation gates through the sr-build brief on 2026-10-22:

| Gate | Decision |
|---|---|
| Phase 0 research gate | Research done by three prior passes. The build reads their notes and does not redo the research |
| Phase 1 intent | Purpose: authorized find, reproduce, classify, report. Trigger phrases: find and report a vulnerability, bug bounty, coordinated disclosure, get a CVE, audit an open-source project I run locally, hunt variants of a fixed bug, security research workflow. Near neighbor that must not fire: fixing a known flaw in your own code (the `security` skill) |
| Phase 2 placement | Name `security-research`, category `playbooks`, bundle `playbooks-virtuoso` (registered by the orchestrator, not this task), structure SKILL.md plus references |
| Invocation mode | `user-invocable: true`, model invocation allowed (auto mode), with an `argument-hint` for a target or bug class |
| Phase 3 draft | Maintainer reviews the finished files after the build |

## Baseline and reason to exist

No separate with-and-without model runs were made, because the brief forbids background agents. The gaps below come from research evidence, not from invented transcripts:

- Prior-art skills lack an authorization gate, a coordinated-disclosure and CVE flow, and a live-research step (see the table below).
- Out-of-model reports are the main source of not-applicable closures (php-src SECURITY.md lists classes it does not treat as security bugs), so the policy read must be a step.
- Unverified AI-generated reports are the clearest trust destroyer in 2026 (curl, Apple's rules), so verification and minimal PoC are steps.
- Severity inflation in secondary coverage and in self-published write-ups argues for "claim only what the lab proves" and for taking severity from the vendor advisory.

## Prior art

Queries run on 2026-10-22: `npx skills find` for "security research", "bug bounty", "vulnerability research", "vulnerability disclosure", "pentest", "penetration testing", "fuzzing", "ctf", "security-research", "security audit", "cve", "exploit" (first pass), and "bug bounty" and "vulnerability disclosure" again in this build to confirm the decision. `gh search repos` returned nothing useful. Local check: the installed set has `security` and general skills only.

The `timeout` wrapper was not available on this machine, so the two confirmation searches ran without it and completed normally.

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| code-yeongyu/oh-my-openagent `security-research` | https://github.com/code-yeongyu/oh-my-openagent/blob/HEAD/.agents/skills/security-research/SKILL.md | community | 475 installs, 2026-10-22 | Team audit of a repo or diff, severity via CWE, WSTG, ASVS, CVSS 4.0 | "No severity without an attack path", a second engineer tries to falsify, safe local PoCs, report template with downgraded candidates | Needs that tool's team API, no authorization gate, no disclosure process, no live research, no lab guidance | not checked |
| awarexone/agentic-bug-hunter `bug-bounty` | https://github.com/awarexone/agentic-bug-hunter/blob/HEAD/skills/bug-bounty/SKILL.md | community | 456 installs, 2026-10-22. skills.sh showed failing third-party audits (page summary) | Recon-to-report workflow for web programs, about 1,600 lines | "Can an attacker do this right now" gate, kills theoretical bugs, reads disclosed reports first, read scope first | Live-target and recon oriented, thin on source review, memory safety, lab builds and disclosure, very long | not checked |
| elementalsouls/claude-bughunter `bb-methodology` | https://github.com/elementalsouls/claude-bughunter/blob/HEAD/skills/bb-methodology/SKILL.md | community | 328 installs, 2026-10-22 | Bounty methodology family with engagement-mode confirmation | Confirm engagement type and scope first, authorized engagements only | Web-recon bias, no source review of open source, no disclosure or CVE flow, large | not checked |
| briiirussell/cybersecurity-skills `vuln-research` | https://github.com/briiirussell/cybersecurity-skills/blob/HEAD/skills/vuln-research/SKILL.md | community | 342 installs, 2026-10-22 | Defender-side CVE deep dive | Source list, reachability reasoning | For consumers of CVEs, not finders. No authorization or disclosure steps | not checked |
| openai/codex-security `vulnerability-writeup` | https://github.com/openai/codex-security/blob/HEAD/plugins/codex-security/skills/vulnerability-writeup/SKILL.md | official (vendor) | 73 installs, 2026-10-22 | Turns a finding into a verifiable report | Hypothesis first, version, attacker position, calibrated claims | Write-up stage only | not checked |
| trailofbits/skills | https://github.com/trailofbits/skills | official (established security firm) | 7.7k stars, pushed 2026-10-22 | Technique skills: c-review, variant-analysis, differential-review, fp-check, static-analysis, testing-handbook skills, patching-bugs | Best-in-class technique content | No authorization gate, no disclosure or CVE steps, no ongoing monitoring, not an end-to-end workflow | CC-BY-SA-4.0 (confirmed with `gh api` in this build) |
| morluto/rea | https://github.com/morluto/rea | community | npm `rea-agents` 6.7.0, 2026-10-18. Star counts looked implausible and were not used | MCP server plus skill for reverse engineering software you own or are authorized to examine | Local analysis, scoped disclaimer, reviewable setup | Not a methodology, disclosure or live-research skill. Setup rewrites agent config. Two skills.sh audits showed Warn | MIT |
| Seen in search only, not read: superagent-ai `security-disclosure-triage`, yaklang `recon-and-methodology`, transilienceai `hackerone`, trilwu `reporting-security-findings`, waybarrios `vuln-report` | https://skills.sh | community | 34 to 3.9K installs | Vendor-side triage, recon, report writing | n/a | Not evaluated | not checked |
| This repo: `security`, `agent-security`, `research`, `docs-lookup` | skills/ in this repository | project | local | Defensive security and OWASP, untrusted content handling, sourced research, version-correct docs | The research engine and the safety rules this skill points to | None cover the finder-side workflow | project license |

Decision: write a new skill. No official or clearly better skill covers the end-to-end loop of authorization gate, lab reproduction, minimal PoC, coordinated disclosure, post-patch write-up and ongoing live research.

Strengths adopted (ideas only, credited, no text copied):

- oh-my-openagent `security-research`: attack path before severity, falsify before reporting, local PoCs only.
- awarexone `bug-bounty` and elementalsouls `bb-methodology`: read the full scope first, confirm the engagement type, kill theoretical bugs, read disclosed reports first.
- openai `vulnerability-writeup`: hypothesis first and calibrated claim strength in the report.
- briiirussell `vuln-research`: reachability reasoning and advisory sources.

Weaknesses avoided: live-target recon tooling, very long bodies, no authorization or disclosure steps, no live research, textbook content the model already knows.

Point to rather than rebuild: trailofbits/skills for technique depth (variant analysis, C review, fuzzing and sanitizer how-tos), morluto/rea for reverse engineering of closed binaries, and the repo skills `security`, `agent-security`, `research`, `docs-lookup`, `verification-before-completion`, `debugging`.

## Fact ledger

Every row was retrieved 2026-10-22. "Origin" is the row in the research pass that read the page. Confidence uses the skill-writer labels. A page read once on a primary source is "likely", two independent sources is "confirmed".

### Authorization and law (authorization-and-law.md, SKILL.md)

| # | Claim | Source URL | Confidence | Origin |
|---|---|---|---|---|
| 1 | CISA template: unlisted means out of scope and not authorized, contact first if unsure. Managed services need vendor authorization. Good-faith research under the policy is authorized and not pursued. Conduct rules (confirm only, stop at sensitive data, no DoS or social engineering) | https://www.cisa.gov/vulnerability-disclosure-policy-template | likely | sr2 A1-A4 |
| 2 | HackerOne Gold Standard Safe Harbor: good-faith research treated as authorized while the program is active, the company cannot authorize third-party infrastructure, third parties are not bound | https://docs.hackerone.com/en/articles/8494525-gold-standard-safe-harbor-statement | likely | sr2 A5, A6 |
| 3 | Safe harbor does not change program scope. Statement is not legal advice | https://docs.hackerone.com/en/articles/8494502-safe-harbor-overview-faq | likely | sr2 A7, L12 |
| 4 | HackerOne code of conduct: read policy first, no exploitation beyond impact, hackbots and AI tools follow program rules with a human validating, notify third-party component owners first, do not contact customers' customers | https://www.hackerone.com/policies/code-of-conduct | likely | sr2 A10, A11 |
| 5 | Intigriti code of conduct: in-scope only, own accounts, limit exposure to others' data, rate limits | https://kb.intigriti.com/en/articles/5247238-community-code-of-conduct | likely | sr2 A12 |
| 6 | Bugcrowd: out-of-scope testing costs points and repeated violations cost access. Full and partial safe harbor shown on program pages | https://docs.bugcrowd.com/researchers/reporting-managing-submissions/reporting-a-bug/ and https://docs.bugcrowd.com/researchers/disclosure/disclose-io-and-safe-harbor/ | likely | sr2 A13, A14 |
| 7 | Google rules do not authorize third-party sites or customer apps on cloud domains | https://bughunters.google.com/about/rules/6625378258649088 | single-source (search excerpt, page renders in browser) | sr2 A15 |
| 8 | GitHub safe harbor: GitHub alone decides good faith, own systems only, no defense or indemnity against third-party action | https://docs.github.com/en/site-policy/security-policies/github-bug-bounty-program-legal-safe-harbor | likely | sr2 A16 |
| 9 | Apple: services must be owned by Apple or a subsidiary. Public disclosure before a fix forfeits rewards | https://security.apple.com/bounty/guidelines/ | likely | sr2 A18 |
| 10 | CFAA 1030(a)(2)(C), (e)(6), (a)(5) damage, (g) civil action | https://www.law.cornell.edu/uscode/text/18/1030 | likely | sr2 L1-L4 |
| 11 | Van Buren v. United States: gates-up-or-down, motive alone not enough, technical versus policy gate left open | https://www.law.cornell.edu/supremecourt/text/19-783 | likely | sr2 L5 |
| 12 | DOJ CFAA charging policy: decline good-faith research, internal, no civil or state effect | https://www.justice.gov/jm/jm-9-48000-computer-fraud and https://www.mofo.com/resources/insights/220525-cyber-crime-charging-policy | confirmed (policy text plus two commentaries) | sr2 L6-L8, sr3 F41 |
| 13 | DMCA 1201 exemption 37 CFR 201.40(b)(18) conditions, not a defense to the CFAA. Three-year cycle | https://www.law.cornell.edu/cfr/text/37/201.40 | likely | sr2 L9, L10 |
| 14 | EFF vulnerability reporting FAQ: risk sources, factors that raise risk, never demand payment, lawyer first in listed cases | https://www.eff.org/issues/coders/vulnerability-reporting-faq | likely | sr2 L11 |
| 15 | disclose.io: lawyer-reviewed safe-harbor framework, policy language, not legal advice | https://disclose.io/ | confirmed | sr2 L13, sr3 F40 |
| 16 | UK Computer Misuse Act 1990 has no research defence, reform under consideration | https://www.cyberupcampaign.com/news/security-minister-announces-government-is-looking-at-introducing-a-statutory-defence-to-the-computer-misuse-act | single-source (campaign group) | sr2 L15 |
| 17 | EU CRA manufacturer reporting from 2026-09-11 (24 h and 72 h), open-source stewards later. Obligation on manufacturers | https://www.mondaq.com/compliance/1843102/its-live-the-cyber-resilience-act-reporting-is-mandatory-as-of-today-11-september-2026 and https://helpnetsecurity.com/2026/09/14/enisa-cra-single-reporting-platform | likely (secondary only) | sr2 L16, sr3 F42 |

### Disclosure and CVE (disclosure-and-cve.md)

| # | Claim | Source URL | Confidence | Origin |
|---|---|---|---|---|
| 18 | Project Zero 90+30, grace period, 7 days for active exploitation | https://projectzero.google/vulnerability-disclosure-policy.html | confirmed | sr2 D9, sr3 F18 |
| 19 | CERT/CC policy: 45 days, earlier or later by circumstance | https://certcc.github.io/certcc_disclosure_policy/ | likely | sr2 D6 |
| 20 | CERT/CC reporter guidance: vendor first, reply in 24 to 48 hours, prefers PoC or patch and coordination, no CVE-only requests, self-publish without full PoC after failure | https://certcc.github.io/CERT-Guide-to-CVD/tutorials/coord_certcc/reporter/ | likely | sr2 D7, C8 |
| 21 | CERT guide: no fixed number of days, reasons to release early or hold, embargoes do not bind adversaries | https://certcc.github.io/CERT-Guide-to-CVD/howto/coordination/disclosure_timing/ | likely | sr2 D5 |
| 22 | oss-security distros list: 14 day maximum, under 7 preferred, notify upstream first | https://oss-security.openwall.org/wiki/mailing-lists/distros | likely | sr2 D11 |
| 23 | HackerOne disclosure guidelines: 30 days default, mutual agreement, 180-day last resort. Non-response is not approval | https://www.hackerone.com/terms/disclosure-guidelines and https://docs.hackerone.com/hackers/disclosure.html | confirmed | sr2 P3, sr3 F7, F8 |
| 24 | HackerOne code of conduct: formal approval before disclosure, no leverage for payout | https://www.hackerone.com/policies/code-of-conduct | likely | sr2 P4 |
| 25 | OSS-Fuzz: 90 days after notification or on fix, 14 day grace | https://google.github.io/oss-fuzz/getting-started/bug-disclosure-guidelines/ | likely | sr1 |
| 26 | EFF asks 90 days for its own reports | https://www.eff.org/issues/coders/vulnerability-reporting-faq | single-source | sr2 D12 |
| 27 | Bugcrowd names non-disclosure as the fallback, program brief overrides standard terms | https://docs.bugcrowd.com/researchers/disclosure/disclosure/ | single-source (search excerpt) | sr2 P5 |
| 28 | Intigriti: 48 hour hoarding, status requests no more than every 30 days, beg bounty prohibited, written approval to disclose | https://kb.intigriti.com/en/articles/5247238-community-code-of-conduct | likely | sr2 P7 |
| 29 | HackerOne report states and auto-close of stale Needs More Info | https://docs.hackerone.com/en/articles/8837878-how-triage-works | likely | sr2 P2 |
| 30 | Apple report content and AI-report ineligibility, reassessment | https://security.apple.com/bounty/guidelines/ | likely | sr2 P11, R3 |
| 31 | Bugcrowd report content, cannot edit after submission | https://docs.bugcrowd.com/researchers/reporting-managing-submissions/reporting-a-bug/ | likely | sr2 R2 |
| 32 | php-src SECURITY.md: GitHub advisory form or security@php.net, short reports, classes not treated as security issues | https://github.com/php/php-src/blob/master/SECURITY.md | confirmed (read by sr1, sr2 via mirror, sr3) | sr1, sr2 P18, sr3 F11 |
| 33 | GitHub private vulnerability reporting works only when maintainers enabled it. Reporter added to draft advisory | https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/privately-reporting-a-security-vulnerability | single-source (search excerpt) | sr2 P17, C4 |
| 34 | GitHub is a CNA, about 72 hours, request does not publish, no assign if another CNA covers, credit must be accepted | https://docs.github.com/en/code-security/concepts/vulnerability-reporting-and-management/about-repository-security-advisories | confirmed | sr2 C3, sr3 F10 |
| 35 | CNAs and CNA-LR, order of preference, IDs only for issues to be announced | https://www.cve.org/Resources/Roles/Cnas/CNA_Rules_v4.1.0.pdf and https://www.cve.org/Resources/Media/Archives/OldWebsite/cve/request_id.html | likely (archived page, PDF not extracted) | sr2 C1, C2, sr3 F20 |
| 36 | NVD risk-based enrichment from 2026-04-15, no NIST severity scores | https://www.nist.gov/itl/nvd and https://therecord.media/nist-to-limit-work-on-cve-entries-surge | confirmed | sr2 C9, sr3 F28 |
| 37 | CERT/CC finds a vendor unresponsive: can still coordinate and publish | https://vuls.cert.org/confluence/x/QoA9B | single-source | sr2 D8 |
| 38 | security.txt at /.well-known/security.txt | https://www.iana.org/assignments/security-txt-fields/security-txt-fields.xhtml | likely | sr2 D15 |
| 39 | CVSS v4.0 groups, labels, severity not risk, publish the vector, library worst case, 0.0 if never reached | https://www.first.org/cvss/v4-0/user-guide and https://www.first.org/cvss/v4-0/specification-document | confirmed | sr1 2.10, sr2 C11 |
| 40 | CVSS v3.1 rating bands | https://www.first.org/cvss/v3.1/specification-document | likely | sr1 2.10 |
| 41 | CWE abstraction levels, Top 25 2025 ids (787, 416, 125, 120, 476) | https://cwe.mitre.org/top25/archive/2025/2025_cwe_top25.html and https://cwe.mitre.org/documents/glossary/ | likely | sr1 2.9, 2.10 |
| 42 | OWASP Top 10 is an awareness list | https://owasp.org/Top10/2025/0x00_2025-Introduction/ | single-source (via search) | sr1 2.10 |
| 43 | Chromium severity guidelines: reachability, sandbox, interaction, controlled read size, most crashes are not vulnerabilities | https://chromium.googlesource.com/chromium/src/+/main/docs/security/severity-guidelines.md | likely | sr1 2.9 |
| 44 | MITRE CVE contract extended at short notice in 2025, later status unconfirmed | https://therecord.media/cisa-extends-cve-program-contract-with-mitre | likely | sr3 F39b, sr2 C10 |
| 45 | Curl ended its HackerOne bounty at end of January 2026 after AI-generated low-quality reports | https://www.bleepingcomputer.com/news/security/curl-ending-bug-bounty-program-after-flood-of-ai-slop-reports/ and https://thenewstack.io/drowning-in-ai-slop-reports-curl-ends-bug-bounties/ | confirmed | sr2 P15, sr3 F12 |
| 46 | Google OSS VRP paused new product reports from 2026-10-01 | https://thehackernews.com/2026/10/google-pauses-oss-product-bug-bounty.html | single-source (secondary news, fetch returned 403). Marked "reports say" in the skill | sr2 P9 |

### Techniques and lab (techniques.md, lab-and-repro.md)

| # | Claim | Source URL | Confidence | Origin |
|---|---|---|---|---|
| 47 | Source and sink model, hand tracing with a marker | https://portswigger.net/web-security/cross-site-scripting/dom-based | likely | sr1 2.1 |
| 48 | Psalm taint sources, sinks, `--taint-analysis`, `--dump-taint-graph`, escaping blind spot | https://psalm.dev/docs/security_analysis/ | likely | sr1 2.1, 2.3 |
| 49 | CodeQL path queries, supported languages, no PHP, build needed for compiled languages | https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/ and https://codeql.github.com/docs/writing-codeql-queries/creating-path-queries/ | confirmed | sr1 2.3 |
| 50 | Semgrep taint mode, function-level default, paid cross-file, PHP generally available | https://docs.semgrep.dev/writing-rules/data-flow/taint-mode/overview and https://docs.semgrep.dev/supported-languages | likely | sr1 2.3 |
| 51 | Joern code property graph, language maturity (PHP medium) | https://docs.joern.io/ | likely | sr1 2.3 |
| 52 | GitHub multi-repository variant analysis over CodeQL databases | https://docs.github.com/en/code-security/concepts/code-scanning/multi-repository-variant-analysis | single-source (search excerpt) | sr1 2.3 |
| 53 | libFuzzer: entry point, combined sanitizers, corpus, dictionary | https://llvm.org/docs/LibFuzzer.html | likely | sr1 2.4 |
| 54 | Good fuzz target properties and exec speed guidance | https://github.com/google/fuzzing/blob/master/docs/good-fuzz-target.md | likely | sr1 2.4 |
| 55 | Structure-aware fuzzing needs custom mutators and manual work | https://github.com/google/fuzzing/blob/master/docs/structure-aware-fuzzing.md | likely | sr1 2.4 |
| 56 | AFL++ successor to AFL, workflow, one sanitizer per instance, triage | https://aflplus.plus/ and https://github.com/AFLplusplus/AFLplusplus/blob/stable/docs/fuzzing_in_depth.md | confirmed | sr1 2.4, 2.5 |
| 57 | OSS-Fuzz eligibility, engines, tracker. ClusterFuzz features | https://google.github.io/oss-fuzz/faq/ and https://google.github.io/clusterfuzz/ | confirmed | sr1 2.4 |
| 58 | Big Sleep: LLM agent from a recent commit, SQLite fix before release, results experimental, harness build hid the bug | https://projectzero.google/2024/10/from-naptime-to-big-sleep.html | likely | sr1 2.4, 2.7 |
| 59 | Project Zero 2020 review: 6 of 24 exploited zero-days related to earlier public bugs, incomplete patches | https://projectzero.google/2021/02/deja-vu-lnerability.html | likely | sr1 2.7 |
| 60 | BinDiff (IDA, Ghidra, Binary Ninja through BinExport) and Diaphora | https://github.com/google/bindiff and https://github.com/joxeankoret/diaphora | confirmed | sr1 2.7 |
| 61 | IDOR method: map references, two or more test users, substitute across users | https://wstg.owasp.org/v4.2/4-Web_Application_Security_Testing/05-Authorization_Testing/04-Testing_for_Insecure_Direct_Object_References/ | likely | sr1 2.8 |
| 62 | SSRF where to look, business logic needs human context | https://portswigger.net/web-security/ssrf and https://portswigger.net/web-security/logic-flaws | likely | sr1 2.2, 2.8 |
| 63 | Parser differentials in PortSwigger's annual list, chosen by nomination, vote and expert panel | https://portswigger.net/research/top-10-web-hacking-techniques-of-2025 | likely | sr1 2.6, sr3 F36 |
| 64 | ASan: bug classes, build flags, ASAN_OPTIONS, symbolizer, 2x slowdown, first error, no static linking | https://clang.llvm.org/docs/AddressSanitizer.html | confirmed | sr1 2.5, sr3 F44 |
| 65 | UBSan categories and MSan requirements (all code instrumented, about 3x) | https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html and https://clang.llvm.org/docs/MemorySanitizer.html | likely | sr1 2.5 |
| 66 | Docker `none` network driver gives loopback only | https://docs.docker.com/engine/network/drivers/none/ | likely | sr3 F46 |
| 67 | PHP `--enable-sanitizer`, `--enable-debug`, Zend allocator hides errors, `USE_ZEND_ALLOC=0`, `USE_TRACKED_ALLOC=1` | https://github.com/php/php-src/pull/18835 , https://bugs.php.net/79781 , https://bugs.php.net/74103 | single-source, forum and tracker comments. Marked verify-first in the skill | sr1 2.5, sr3 F45 |
| 68 | php-src fuzzer targets and mbregex note | https://github.com/php/php-src/blob/master/sapi/fuzzer/README.md | likely | sr1 2.4 |
| 69 | Lab method example (source review, instrumented lab build, per-SAPI testing, crashes reproduced twice). Method only, no severity or timing taken | https://jackalsyn.com/posts/php-up-2026.html | single-source (self-reported, summarizer-read) | sr1 2.9, sr3 F21 |
| 70 | rea: MCP plus skills, `npx rea-agents setup` shows proposed changes with backups, Node 22.19 or later, tools you license yourself, official sources, scope sentence, MIT | https://github.com/morluto/rea | confirmed (README read in sr1 and again in this build) | sr1 2.11, sr3, inline |
| 71 | rea's own skill documents a `--dry-run` flag for setup | https://github.com/morluto/rea (file `.agents/skills/reverse-engineer-anything/SKILL.md`, read with `gh api` in this build) | likely | inline |
| 72 | trailofbits/skills license is CC-BY-SA-4.0 | https://github.com/trailofbits/skills (`gh api repos/trailofbits/skills`) | confirmed | inline |
| 73 | PortSwigger Academy is free with labs per topic. WSTG v4.2 stable and v5.0 in development. Hacker101, pwn.college (no challenge write-ups), CTFtime | https://portswigger.net/web-security , https://owasp.org/www-project-web-security-testing-guide/ , https://www.hacker101.com , https://pwn.college , https://ctftime.org | likely | sr3 F49-F54 |
| 74 | The Fuzzing Book is free online | https://www.fuzzingbook.org/ | likely | sr1 |
| 75 | Project Zero careers advice: public reports, study fixed bugs, adversarial reading, fix open-source bugs, CTFs | https://projectzero.google/working-at-project-zero.html | likely | sr3 F1, F2 |

### Feeds and reputation (staying-current.md)

| # | Claim | Source URL | Confidence | Origin |
|---|---|---|---|---|
| 76 | cvelistV5: CVE JSON 5, refresh about every 7 minutes, daily baseline and hourly delta zips | https://github.com/CVEProject/cvelistV5 | likely | sr3 F27 |
| 77 | GitHub Advisory Database ecosystems, filters, GraphQL API | https://github.com/advisories | likely | sr3 F29 |
| 78 | OSV aggregation, API by version or commit, OSV-Scanner | https://osv.dev | likely | sr3 F30 |
| 79 | CISA KEV CSV and JSON feeds, nomination form | https://www.cisa.gov/known-exploited-vulnerabilities-catalog | likely | sr3 F31 |
| 80 | oss-security posting rules and archives | https://oss-security.openwall.org/wiki/mailing-lists/oss-security | likely | sr3 F32 |
| 81 | ZDI batched advisories | https://www.zerodayinitiative.com/advisories/published/ | single-source | sr3 F39 |
| 82 | tl;dr sec weekly newsletter with RSS. GitHub Security Lab research and Advisory Database | https://tldrsec.com , https://securitylab.github.com | single-source each | sr3 F37, F38 |
| 83 | php-src advisories dated May, July, September, October 2026, listed through the GitHub API | `gh api repos/php/php-src/security-advisories` | likely (read directly) | sr3 F34 |
| 84 | HackerOne Signal and Impact definitions, self-closed, duplicate and informative do not count. Invitation thresholds change yearly | https://docs.hackerone.com/hackers/signal-and-impact.html and https://www.hackerone.com/blog/earning-hackerone-2025-live-hacking-invite | likely | sr3 F4-F6 |
| 85 | CFP calendars move each year | https://i.blackhat.com/BHUS26/BHUS26-CFP-Preparation-Doc.pdf , https://sessionize.com/recon-village/ | single-source (dates differ between sources, so none is hard-coded) | sr3 F15 |
| 86 | OpenSSF finder and maintainer guides, CERT Guide to CVD | https://github.com/ossf/oss-vulnerability-guide/blob/main/finder-guide.md and https://certcc.github.io/CERT-Guide-to-CVD/ | likely | sr3 F17, sr2 D1 |

## Not confirmed

| Item | Reason | What was done |
|---|---|---|
| USE_ZEND_ALLOC and USE_TRACKED_ALLOC with ASan on PHP | Tracker and PR comments only | Kept, marked verify-first, points to current php-src docs |
| CWE ids for type confusion and double free | From memory in the research pass | Cut: the skill tells the reader to look the id up on cwe.mitre.org |
| McKeeman 1998 as origin of differential testing | Memory only | Cut |
| PHPStan taint support, Progpilot and Exakat capabilities | Secondary sources | Cut. Psalm, Semgrep, CodeQL, Joern kept |
| The Art of Software Security Assessment chapter claims, publisher and year of three books | TOC fetch returned 403 | Books cut from the skill |
| Trail of Bits Testing Handbook decision rules ("Semgrep first, CodeQL for cross-file") | Derived community pages | Cut. Handbook linked as a learning resource only |
| Project Zero 2022 "at least half" figure, Black Hat 2020 root-cause technique list, Exodus patch-gapping post | Search summaries or mirrors | Cut. Patch gapping is not taught |
| Project Zero method mix (54, 37, 8 percent) | Secondary source | Cut |
| Project Zero Reporting Transparency current status | Trial, no later decision found | Cut |
| CNA Rules v4.1.0 body text, current cve.org request page | PDF not extractable, site renders in the browser | Skill says check cve.org live |
| CVE Program funding after March 2026 | No reliable source | Skill says check current status |
| NVD secondary figures (coverage percentages) | AI-assisted note | Cut. Only the Record and NIST facts used |
| Google VRP rules and the OSS VRP pause | Pages render in the browser, secondary news | Worded as "reports say, verify" |
| IBB eligibility and pay split | Primary page did not render | Cut |
| GitHub Security Lab current disclosure deadline | 2019 coverage only | Cut |
| YesWeHack central code of conduct | Not found | Cut |
| Bugcrowd Standard Disclosure Terms default for ambiguous cases | Blog and docs conflict, docs newer | Docs wording used, flagged check |
| ISO/IEC 29147 and 30111 text, FIRST PSIRT framework version | Paywalled or not fetched | Cut |
| DOJ 2017 framework PDF, justice.gov press release text | Fetch failed or empty | Policy text from the Justice Manual page used |
| Whether the 2024 DMCA renewal changed exemption conditions, next proceeding status | Not verified | Skill says check the current rule |
| Non-US law (Germany, Netherlands, Belgium, France, Australia, Canada), UK reform status, EU CRA interaction with researcher disclosure | Not researched or secondary only | Skill says other countries differ, check local law |
| rea: Unity and Godot support, maturity, independent review, star counts, skills.sh Warn audits | Not in README, not explained | Cut from the skill, maturity not claimed |
| Full Disclosure list activity, r/netsec, Hacker News, Mastodon activity | Not fetched | Listed as leads only, activity unconfirmed |
| Conference deadlines | Sources disagree | Not hard-coded |
| TryHackMe and Hack The Box free tiers, The Vulnerability Researcher's Handbook | Vendor blogs | Cut |
| Whether the jackalsyn author reported privately, and the page's publication time | Not determinable | Cited for method only |

## Left out

- The jackalsyn page's severity, version and timing claims. The page is internally inconsistent. The official php-src advisories GHSA-w8hw-w9fx-j79w (CVE-2026-109618) and GHSA-6wmf-4rv5-p3rp (CVE-2026-109619) were published 2026-10-21, rated critical, with fixes in 8.2.35, 8.3.36, 8.4.27 and 8.5.12 (read with `gh api repos/php/php-src/security-advisories`). That contradicts the page's own lower rating and non-RCE framing, which is why the skill takes no severity or timing from it and says to read the vendor advisory.
- The page's usage and download sections, which describe delivery to a live target. That is the opposite of a minimal proof, so the skill does not teach it.
- Patch-gapping technique detail. Patch work is framed only as understanding fixes and finding unpatched siblings in authorized code.
- Payload lists and per-bug-class exploitation steps. The model knows them, and PortSwigger Academy and WSTG cover them.
- Recon tool command lines. Tools change, and recon applies only to in-scope bounty assets.
- Textbook CVSS metric tables and OWASP category write-ups, which the `security` skill and the specs cover.
