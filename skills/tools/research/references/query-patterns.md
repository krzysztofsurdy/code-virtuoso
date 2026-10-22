## Contents

- [Rules for every query](#rules-for-every-query)
- [Official docs and specs](#official-docs-and-specs)
- [Versions and changes](#versions-and-changes)
- [Comparisons](#comparisons)
- [Best practice and recommendations](#best-practice-and-recommendations)
- [Recent events and news](#recent-events-and-news)
- [Forums and community signal](#forums-and-community-signal)
- [Errors and symptoms](#errors-and-symptoms)
- [When a query fails](#when-a-query-fails)

# Query patterns

Search tools differ in syntax. The shapes below work on most. Operators such as `site:` and quoted phrases are widely supported, but check the tool before relying on them. Placeholders are in angle brackets.

## Rules for every query

- Short first: 2-5 words to see what exists, then add words to narrow. A long natural-language question often returns worse results than its keywords.
- Never run the same query twice. Change a word, a source, or the shape.
- Put the exact string in quotes when you have one (an error message, a flag, a config key).
- Add the version when it matters, and the year when you want recent material. Use the year from the environment, not from memory.
- Keep private data out. Replace paths, hostnames, customer names and tokens before searching.
- Prefer one concept per query. Two concepts in one query match pages about neither.
- Use domain filters to reach a tier: the vendor domain for tier 1, `github.com` for source and issues.

## Official docs and specs

| Goal | Shape | Example |
|---|---|---|
| Find the docs page for a feature | `<product> <feature> documentation` | `postgres partial index documentation` |
| Restrict to the vendor | `site:<docs-domain> <term>` | `site:symfony.com messenger retry strategy` |
| Find the spec | `<standard> RFC <topic>` or `<topic> specification` | `RFC 9110 conditional requests` |
| Find the API reference for a version | `<package> <version> <symbol>` | `django 5.1 QuerySet.bulk_create` |
| Check for machine-readable docs | `<docs-domain>/llms.txt` | fetch the URL directly |
| Find the source | `site:github.com <org>/<repo> <symbol>` | read the code, not the summary |

## Versions and changes

| Goal | Shape | Example |
|---|---|---|
| Latest release | `<product> releases` or `<product> changelog` | read the repository releases page, not an article |
| What changed between versions | `<product> upgrade <old> to <new>` | `symfony upgrade 7.3 to 7.4` |
| Is a feature deprecated | `<product> <feature> deprecated` | then confirm in the changelog |
| Support window | `<product> end of life` or `<product> support policy` | an official lifecycle page is tier 1 |
| What is installed here | read the lockfile and installed source | no web search needed |

For "latest", fetch the project's release page or package registry entry and note its date. Do not infer the latest version from an article.

## Comparisons

| Goal | Shape | Example |
|---|---|---|
| Find direct comparisons | `<A> vs <B>` | `vitest vs jest` |
| Find migration experience | `migrating from <A> to <B>` or `switched from <A> to <B>` | practitioner reports with reasons |
| Find limits of one option | `<A> limitations` or `<A> problems at scale` | then check each against the docs |
| Find the criteria | `how to choose <category>` | collect the criteria, then score the options yourself |
| Find usage figures | `<A> downloads` or `<category> survey <year>` | use package registry stats and surveys with stated method |

Method: set the criteria first (fit with constraints, maturity, maintenance activity, ecosystem, cost, migration effort). Look up each option on each criterion in its own primary source. A single "A vs B" article is a lead, and vendor-written comparisons favor the vendor.

## Best practice and recommendations

| Goal | Shape | Example |
|---|---|---|
| Find the official guidance | `<product> best practices` with the vendor domain | `site:docs.aws.amazon.com lambda best practices` |
| Find the standard | `<topic> OWASP cheat sheet`, `<topic> NIST guideline` | standards bodies rank above blogs |
| Find what practitioners run | `<topic> in production` or `<topic> lessons learned` | engineering blogs with numbers |
| Check it is still recommended | `<practice> deprecated`, `<practice> no longer recommended`, `<practice> anti-pattern <year>` | then look for the vendor changelog |
| Find the reasoning | `why <practice>` or `<practice> trade-offs` | reasons let you judge fit for the constraints |

"Best practice" has no single source. Report who recommends it (vendor, standards body, practitioners), under what conditions, and where they disagree.

## Recent events and news

| Goal | Shape | Example |
|---|---|---|
| Latest on an event | `<subject> <event> <month year>` | use the month and year from the environment |
| Primary announcement | `site:<company-domain> announcement <topic>` or the vendor's blog and status page | cite it over the articles about it |
| Date check | open the page and read the date line and the update line | search snippets show stale or wrong dates |
| Corroboration | search for the same claim in a second outlet | check they do not both cite the same original |

For breaking topics, say that the story may still change and give the retrieval date.

## Forums and community signal

| Goal | Shape | Example |
|---|---|---|
| Known issues | `site:github.com <org>/<repo> issues <symptom>` | read the thread to the end, maintainers often close with the answer |
| Design intent | `site:github.com <org>/<repo> discussions <topic>` | maintainer replies are primary for behavior |
| Practitioner opinion | `<topic> reddit`, `<topic> hacker news` | opinions are leads. Look for people who show their setup |
| Q&A | `<exact error or question> stackoverflow` | check the answer date and the version it covers |

Weigh by evidence, not votes: commands, versions, output, links to the docs. Note the date, because old accepted answers are often out of date.

## Errors and symptoms

Search the error class and the library, not the full stack trace.

- Good: `"SQLSTATE[23000] Duplicate entry" doctrine upsert`
- Bad: the whole trace with file paths, hostnames and ids.

Strip: file paths, usernames, hostnames, IPs, ids, tokens, SQL with real data. Keep: the error code and message template, the library and version, the operation.

## When a query fails

| Symptom | Fix |
|---|---|
| Results are all the same page or its copies | Change the angle: search a phrase from the primary, or go straight to the vendor site |
| Results are SEO listicles | Add `site:` for the vendor, the standards body, or `github.com` |
| Results are old | Add the version or year, check the changelog, search the deprecation instead |
| Nothing relevant | Use the term the vendor uses (check their docs headings), drop jargon you guessed, try a broader term |
| Too many results | Add the version, the feature name in quotes, or a distinguishing word |
| Paywalled or blocked page | Look for the primary, an official summary, or an archived copy. Say if you could not read it |
| A claim has no source | Mark it Unverified. Do not search the same claim a fourth time |

After three failed shapes for one sub-question, stop. Report it as not found with the queries tried.
