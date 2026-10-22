# Authorization and law

This is general information, not legal advice. Laws differ by country and change. Check local law, and if in doubt ask the program owner in writing and speak to a lawyer (in the US, EFF's Coders' Rights Project can help find counsel). Rules outside the US are often stricter or have no research exemption.

## Contents

- [The rule](#the-rule)
- [Authorization checklist](#authorization-checklist)
- [Scope and safe harbor in practice](#scope-and-safe-harbor-in-practice)
- [Where the method fits](#where-the-method-fits)
- [US legal anchors](#us-legal-anchors)
- [Outside the US](#outside-the-us)
- [Conduct rules platforms repeat](#conduct-rules-platforms-repeat)
- [When to stop and ask](#when-to-stop-and-ask)

## The rule

A system is authorized for testing only when its owner has said so, and the written scope and rules are the boundary of that statement. Out of scope, unlisted or third-party means not authorized. Safe harbor is a promise by the owner not to act against you. It does not make testing lawful against anyone else and it cannot extend beyond what the owner controls.

## Authorization checklist

Answer each before any hunting. If an answer is no or unknown, stop.

1. Is the target an in-scope public bug bounty asset, open-source code that will run in your own isolated lab, or a system you own?
2. Have you read the written scope and rules for this asset, and do they list it?
3. Is the work free of third-party and production systems you do not own or lack written authorization for?
4. Will you use only your own accounts and touch no real user data?
5. Do you know the disclosure channel and the program's disclosure terms?
6. For a managed service or SaaS component, did the vendor authorize testing of it? If not, it stays out of scope.

## Scope and safe harbor in practice

- CISA's vulnerability disclosure policy template treats anything not expressly in scope as out of scope and not authorized. If unsure, contact the owner before testing.
- Good-faith research that follows a program's policy is treated as authorized by that program, which agrees not to pursue legal action. HackerOne's Gold Standard Safe Harbor says this applies only while the program is active and the researcher makes a good-faith effort to follow the guidelines. It also says the company cannot authorize research on third-party infrastructure and that third parties are not bound.
- HackerOne's safe harbor FAQ says adopting safe harbor does not change the program's scope. GitHub's safe harbor says GitHub alone decides good faith, covers only GitHub's own systems, and will not defend or indemnify researchers against third-party action.
- A program cannot authorize testing of an asset it does not host. Google's rules, for example, do not authorize testing of third-party sites or of customers' apps on cloud domains. Apple requires that services be owned by Apple or a subsidiary. Newly acquired companies may have a blackout period, so read each program.
- Bugcrowd shows full or partial safe harbor status on program pages. Testing out-of-scope targets costs points and repeated violations can cost program access.
- Intigriti: test only in-scope assets, use your own accounts, limit exposure to others' personal data, and keep automation within rate limits.
- disclose.io is a lawyer-reviewed open safe-harbor framework that many programs use. Its text is policy language, not legal advice.

## Where the method fits

- Open-source code you download and run in your own lab involves no access to anyone else's system. Computer-misuse access questions are generally not the issue. Licensing, contract terms, and DMCA anti-circumvention only if you bypass access controls remain open questions. This is generally lower risk, and still not legal advice.
- Public bounty targets: stay inside the written scope, use your own accounts, stop at proof, and leave other users' data alone.
- If the finding concerns software that other people run (almost always), do not test live deployments of it to "confirm impact". Confirm in the lab only.

## US legal anchors

| Anchor | Plain summary |
|---|---|
| CFAA, 18 USC 1030 | Intentionally accessing a protected computer without authorization, or exceeding authorized access, and obtaining information, is an offense. "Exceeds authorized access" means using access you have to obtain or alter information you are not entitled to obtain or alter. Damage offenses cover impairing the integrity or availability of data, programs or systems, which is why denial of service and data modification are the classic line-crossers. Subsection (g) allows a private civil suit, so a vendor can sue even where a prosecutor will not |
| Van Buren v. United States (2021) | The Supreme Court framed CFAA liability as a "gates-up-or-down" inquiry and said improper motive alone is not enough. It left open whether the gate is only technical or also covers contractual and policy limits |
| DOJ charging policy for the CFAA (2022) | Prosecutors should decline cases of good-faith security research: accessing a computer solely for good-faith testing, investigation or correction of a flaw, in a manner designed to avoid harm, with results used primarily to promote security. Research done to extort does not qualify. It is internal guidance with no enforceable rights, and it does not address civil claims or state law |
| DMCA section 1201 exemption, 37 CFR 201.40(b)(18) | Permits circumvention for good-faith security research on a device you lawfully acquired or a system whose owner authorized the work, limited to testing, investigating or fixing a flaw, in an environment designed to avoid harm, with results used primarily to improve security. The text says it is not a defense to other laws such as the CFAA. The exemption is renewed on a three-year cycle, so check the current rule |
| EFF vulnerability reporting FAQ | Standard disclosure practice reduces but does not remove legal risk. Risk comes from the CFAA, DMCA 1201, state and foreign laws, NDAs and license terms. It rises with functional exploit code, highly detailed advisories, DRM-related research and breaching an NDA. Never demand payment or offer silence for money. Talk to a lawyer first if an NDA, DRM, non-public material or an employer objection is involved |

No other case law was reviewed. Do not state conclusions about scraping or terms-of-service-only access beyond "Van Buren left it open".

## Outside the US

- Other countries differ, and many have no research defence. Check local law.
- UK: the Computer Misuse Act 1990 has no statutory research defence. The government said in late 2025 it was considering one. Check whether it has been enacted.
- EU: the Cyber Resilience Act's manufacturer reporting of actively exploited vulnerabilities began on 2026-09-11 through ENISA's single reporting platform (24 hour early warning, 72 hour notification). That is an obligation on manufacturers, not a safe harbor for researchers. Obligations on open-source stewards start later. These dates come from trade-press and consultancy sources, so confirm them on official EU pages.
- Germany, the Netherlands, Belgium, France, Australia, Canada and others were not researched. Do not assume a rule from the US applies.

## Conduct rules platforms repeat

- Use exploits only to confirm that a vulnerability exists. No data theft, persistence or pivoting.
- If you reach sensitive data, stop and report.
- No denial of service, physical testing or social engineering unless explicitly authorized.
- Allow time to fix. Do not publish before approval.
- Do not contact a customer's customers or end users. Do not use disclosure as leverage for payment.
- Hackbots and AI tools must follow program rules, and a human validates the findings.
- Read each program policy before you engage. Submitting means accepting its rules.

## When to stop and ask

Stop and ask the user when:

- the target is not clearly in a written scope;
- the work would touch a live third-party deployment;
- a legal question goes beyond general information;
- the user asks for a weaponized exploit, mass scanning or evasion. Decline those, explain why, and offer the minimal-PoC route.
