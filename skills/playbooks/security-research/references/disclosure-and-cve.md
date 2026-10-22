# Disclosure, CVE and the report

Coordinated disclosure means you report privately first, give the vendor time to fix, and publish after the fix. The numbers below are anchors that real programs use. The program brief or the vendor's policy always overrides them, and policies change, so confirm the current text in the live-research step.

## Contents

- [Disclosure pipeline](#disclosure-pipeline)
- [Embargo anchors](#embargo-anchors)
- [Choosing the private channel](#choosing-the-private-channel)
- [The CVE and CNA path](#the-cve-and-cna-path)
- [Classify before you report](#classify-before-you-report)
- [Report template](#report-template)
- [Triage and duplicates](#triage-and-duplicates)
- [Unresponsive vendor](#unresponsive-vendor)
- [Mistakes that cost trust](#mistakes-that-cost-trust)

## Disclosure pipeline

1. Confirm authorization and scope before touching anything. For open source, work only in your local lab on code you obtained legitimately.
2. Reproduce with a minimal proof and stop there. Do not weaponize, and do not test live third-party instances.
3. Check duplicates and known issues: the project tracker, the advisory databases, CVE search, prior write-ups. Check the project's security policy and threat model for whether the class is in scope.
4. Find the private channel (next section).
5. Send a complete report and state your intended disclosure timeline in the first message, so nobody is surprised.
6. Let the vendor triage and validate. Answer questions. Do not nag: platform norms are roughly one status request per 30 days.
7. Agree on the embargo and CVE handling. Platform rules and the program brief override the anchors below.
8. The vendor fixes and releases. Verify the fix in your lab. Check the advisory for accuracy: affected and fixed versions, and credit.
9. The CVE is published. Get written approval where the program requires it.
10. Publish your write-up after the fix and after the agreed delay, with exploit detail limited to what readers need.

## Embargo anchors

| Anchor | Rule |
|---|---|
| Project Zero (90+30) | The vendor has 90 days to patch. If it patches in that window, details are published 30 days after the patch reaches users. If unpatched, details are published at day 90. A grace period exists. Active exploitation shortens the deadline to 7 days |
| CERT/CC | Public disclosure 45 days after the initial report regardless of patch availability. It can move earlier for active exploitation or later for hard-to-fix core components |
| oss-security distros list | Maximum embargo 14 days, shorter than 7 days preferred, and do not ask for longer. Notify upstream first so a fix exists |
| HackerOne default | A Resolved report becomes public 30 days after a disclosure request if neither side objects. Under the Mutual Agreement setting, a 180-day last-resort rule applies if the security team does not respond to a formal request despite follow-ups at least every 30 days |
| OSS-Fuzz | Reports go public 90 days after notification or on fix, with a 14 day grace period if a patch is committed to ship |
| EFF | Asks 90 days before public discussion for its own reports |
| Program brief or vendor policy | Overrides all of the above. Bugcrowd's docs name non-disclosure as the fallback when a brief is silent (check the current page) |

CERT/CC's guide says there is no single right number of days. Release early when exploitation is active, the vendor is unresponsive or acting in bad faith, or adversaries are likely to find it. Hold longer for good-faith progress, safety-critical impact or late-found dependencies. Embargoes do not bind adversaries, and you should not tease partial details.

## Choosing the private channel

In order of preference:

1. The program page on a platform (HackerOne, Bugcrowd, Intigriti, YesWeHack, or a vendor program such as Google, Microsoft or Apple). Use its disclosure request process for any later publication.
2. The repository's security policy file and GitHub private vulnerability reporting (Security tab, "Report a vulnerability"), which works only when the maintainers enabled it. php-src, for example, takes reports through a GitHub private advisory form with security@php.net as the fallback.
3. A `security.txt` file at `/.well-known/security.txt`, which names a contact.
4. A coordinator such as CERT/CC when no contact exists. It usually replies in 24 to 48 hours, prefers reports with a PoC or patch and a request for active coordination, and generally will not take a request that only wants a CVE ID.

If none of these is enabled, ask the maintainers for a private contact. Do not open a public issue with the details. For third-party components, notify the component owner in good faith before reporting elsewhere unless the program says otherwise.

## The CVE and CNA path

CVE IDs come from CVE Numbering Authorities (CNAs): vendors, open-source projects, coordinators and bug bounty platforms, each with a defined scope. CNA of last resort (CNA-LR) assigns for issues no other CNA covers. Check cve.org for the current rules and request pages, because the site is rendered in the browser and some older pages are archived.

1. Report privately first. Do not request an ID for something that has not been reported, or that will never be public.
2. Find the CNA that covers the product: the project's own CNA, a platform or coordinator CNA, or GitHub where it is the covering CNA. Otherwise use the CNA-LR through MITRE's request form after notifying the vendor.
3. Prefer asking the maintainer to publish a GitHub repository security advisory and request the CVE through GitHub. GitHub is a CNA that usually answers in about three days. Requesting an ID does not publish the advisory, and GitHub will not assign one if another CNA already covers the project. With private vulnerability reporting, you are added to the draft advisory as a collaborator and credited user, and you must accept the credit for it to show.
4. Prepare the record data: title, a concise description (component, class, condition, impact), affected and fixed versions, CWE, CVSS vector and score, references (advisory, fix commit, release notes) and the credit line.
5. Reserved IDs stay private until the advisory is public.
6. After publication, check the record on cve.org. Corrections go to the CNA that issued the CVE.

NVD changed in 2026: NIST moved to risk-based enrichment, so only CVEs in CISA's Known Exploited Vulnerabilities catalog, in federal government software or in critical software are enriched, and NIST stopped adding its own severity scores. Supply a CVSS vector and a CWE yourself, and confirm the current NVD policy on nvd.nist.gov. MITRE's CVE contract was extended at short notice in 2025, so check the CVE Program's current status instead of assuming one feed is permanent.

## Classify before you report

- CWE: pick a Base-level weakness where you can. Pillar, Class, Base and Variant are the abstraction levels, and chains and composites describe related weaknesses. The OWASP Top 10 is an awareness list, not a taxonomy for CVE records, so use CWE ids there.
- CVSS: write the version and the vector, for example `CVSS:4.0/...` or `CVSS:3.1/...`, and say which metric groups you scored. CVSS v4.0 has Base, Threat, Environmental and Supplemental groups and labels such as CVSS-B and CVSS-BT. CVSS v3.1 ratings run None 0.0, Low 0.1 to 3.9, Medium 4.0 to 6.9, High 7.0 to 8.9, Critical 9.0 to 10.0. Check which version the program or CNA wants.
- CVSS measures severity, not risk. For libraries assume reasonable worst-case use, do not carry impact past what the bug reliably gives, and score a bug the product never reaches as 0.0. Say what each metric assumes (for example, "needs the prefork SAPI").
- Overclaiming severity is a top friction in triage. Show the attack path before you assert severity, and use the vendor's rubric where one exists (Chromium's severity guidelines are a worked example).

## Report template

- Title: class, component and effect, for example "Use-after-free in `<component>` via `<trigger>` leads to `<effect>`".
- Summary: two or three sentences, what it is and why it matters.
- Affected: product, versions or commit range, required configuration, and whether it is the default.
- Environment: exact build, OS, compiler flags and sanitizer. For memory bugs, include the ASan output.
- Reproduction: numbered, deterministic and self-contained, with the smallest input or script, expected versus actual behavior, and crash or output evidence.
- Root cause: file, function, line or commit, and why the code is wrong.
- Impact: a realistic attack scenario with preconditions, who is affected and what is gained. Be honest about limits, such as "requires local code execution" or "requires a non-default setting".
- Severity: CVSS vector and score with one line of justification per metric, and the CWE.
- Remediation: a suggested patch or direction, and a test case.
- Disclosure: your timeline, whether you want a CVE, credit preference and contact.
- Not included: weaponized exploit chains, real user data, steps that need testing a third party's live system.

Keep it short and complete. Apple asks for observed versus expected behavior, the bypassed mechanism, the attack path and numbered steps. Bugcrowd advises steps in the order someone must follow, and notes that a report cannot be edited after submission. PHP asks for short reports with a minimal reproducer. Unvalidated AI-generated reports are ineligible on Apple's program and are blamed for curl's decision to end its bounty.

## Triage and duplicates

- HackerOne report states: New, Needs More Info, Triaged, Resolved. Closures: Duplicate, Informative, Not Applicable, Spam. Answer Needs More Info quickly, because stale ones auto-close.
- Duplicate means the same root cause was reported earlier or is already known. The first complete, actionable report usually wins.
- Search known issues, advisories and the program's disclosed reports before you file.
- Argue severity with evidence through the platform's process, not with inflated CVSS.

## Unresponsive vendor

1. Document every attempt with dates.
2. Follow up and restate your deadline.
3. Try alternate contacts: `security.txt`, other maintainers, platform mediation.
4. Escalate to a coordinator such as CERT/CC, which can coordinate and publish a note without the vendor.
5. If the vendor stays silent and its behavior is unreasonable, publishing after your stated deadline is the accepted last resort. Give mitigation-level detail without a full PoC.
6. On a platform program, use its disclosure request process. Non-response or rejection is not approval, and going around the platform can mean removal.

## Mistakes that cost trust

- Testing out of scope or on a third party.
- Denial of service, load testing or heavy automated scanning.
- Touching real user data.
- Going public, or posting a PoC video, before approval or the fix. Apple makes early public disclosure forfeit all rewards.
- Demanding payment, threatening disclosure for a bounty, or sending unsolicited reports that ask for money. Extortion has criminal exposure and means permanent bans.
- Submitting unvalidated AI or scanner output, theoretical issues, or batches of low-effort reports.
- Skipping the project's security policy, so the report is outside its threat model.
- Skipping reproduction, overstating severity, vague titles, missing versions.
- Contacting customers, end users or the press instead of the program.
- Hoarding findings past program norms (Intigriti says about 48 hours) or chaining findings to inflate a payout.
- Opening a public issue or posting about it instead of using the private channel.
- Breaking the confidentiality of a private program.
