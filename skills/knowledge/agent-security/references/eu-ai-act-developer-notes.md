## Contents

- [Scope of these notes](#scope-of-these-notes)
- [Article 50 duties](#article-50-duties)
- [Dates](#dates)
- [What to build](#what-to-build)
- [Sources](#sources)

## Scope of these notes

These notes help a team that ships an LLM or agent feature to users in the EU find the transparency work early. They are not legal advice. Check the final text and your counsel's reading, and re-verify dates: the Digital Omnibus changed several of them in 2026.

## Article 50 duties

| Paragraph | Owner | Duty | Main exceptions |
|---|---|---|---|
| 50(1) | Provider | Design AI systems that interact directly with people so the people are told they are dealing with an AI system | Obvious to a reasonably well-informed person. Systems authorized by law for criminal law enforcement |
| 50(2) | Provider of systems that generate synthetic audio, image, video, or text | Mark outputs in a machine-readable format so they are detectable as artificially generated or manipulated. Solutions must be effective, interoperable, robust, and reliable as far as technically feasible | Assistive standard editing, or no substantial change to the input. Law enforcement authorization |
| 50(3) | Deployer of emotion recognition or biometric categorization | Inform the people exposed about how the system operates, and process personal data under EU data protection law | Some law enforcement uses. Ancillary biometric categorization that is strictly necessary |
| 50(4) | Deployer | Disclose that deep fake image, audio, or video was generated or manipulated. Disclose that AI-generated text published to inform the public on matters of public interest is AI-generated | Artistic, creative, satirical, or fictional works need only a light disclosure. Text that went through human review or editorial control by someone who holds editorial responsibility |
| 50(5) | Whoever owes the duty | Give the information clearly and in a distinguishable way at the latest at first interaction or exposure, and meet accessibility requirements | None stated |
| 50(7) | Commission | Encourage codes of practice on detecting, marking, and labelling AI-generated content | Not a developer duty |

A provider builds or places the system on the market. A deployer uses it under its own authority. A team that builds a feature on a third-party model is usually both a deployer of the model and a provider of the feature, so check which hat applies to each duty.

## Dates

| Date | What |
|---|---|
| 2 August 2026 | Article 50 transparency duties apply |
| 2 December 2026 | Grace period for the marking duty ends, for providers of generative systems already on the market before 2 August 2026. Systems placed on the market after 2 August 2026 have no grace period |
| 2 December 2027 | Standalone high-risk (Annex III) requirements apply, moved by the Digital Omnibus, Regulation (EU) 2026/1744 |
| 2 August 2028 | High-risk requirements for AI embedded in products under Annex I apply |

The Omnibus entered into force on 27 July 2026 according to the Goodwin alert cited below. It left the substance of Article 50 alone and moved the high-risk dates.

## What to build

| If the feature | Do this |
|---|---|
| Is a chatbot or voice agent that talks to the public | Say it is an AI at the start of the first interaction, in text that screen readers can read. Skip it only where it is obvious |
| Generates images, audio, video, or text for others | Embed machine-readable provenance (metadata, watermark, or both) in outputs, and test that it survives your export path |
| Produces realistic synthetic people or voices | Add a visible disclosure when you publish it as a deployer |
| Publishes AI-written text on public-interest topics | Record the human review and who holds editorial responsibility, or label the text as AI-generated |
| Uses emotion recognition or biometric categorization | Stop and get legal review. Other parts of the Act and GDPR apply |

Keep a short record: which Article 50 duties apply to the feature, which role you hold, how the disclosure or marking works, and where it was tested. It makes an audit or a customer question a ten-minute task.

## Sources

- https://artificialintelligenceact.eu/article/50/ (article text)
- https://www.goodwinlaw.com/en/insights/publications/2026/08/alerts-technology-dpc-eu-ai-act-transparency-obligations-now-in-force (dates and Omnibus changes)
