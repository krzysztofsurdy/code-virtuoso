# Writing levers

Three habits that change how a model reads instructions, plus a glossary that feeds the first one. They apply to any prompt, rules file, skill, spec or ticket. The skill's size and placement rules decide what to include and where. These decide how each line is worded.

## Contents

- [Leading words](#leading-words)
- [Steer with positive terms](#steer-with-positive-terms)
- [The no-op test](#the-no-op-test)
- [Glossary](#glossary)
- [Quick checks](#quick-checks)

## Leading words

A model ties a word to the behavior, code and documents that word appeared with. A word used the same way in a rule, a spec, a test name and a class name pulls all of those together. The same idea under three names gives three weaker signals, and the model may treat them as three different things.

Pick one word per concept and reuse it everywhere: prompts, rules files, specs, tickets, code identifiers, test names, commit messages.

Drift looks like this:

| Place | Wording |
|---|---|
| AGENTS.md | "Never delete a customer record." |
| Spec | "WHEN a user closes their account THEN the profile is purged." |
| Code | `AccountRemover::wipe()` |

Three words (customer, user, account) and three verbs (delete, purge, wipe) for two concepts. An agent asked to "delete a customer" may not connect the rule to the code that does it.

Fixed:

| Place | Wording |
|---|---|
| AGENTS.md | "Never erase a customer." |
| Spec | "WHEN a customer closes their account THEN the customer is erased." |
| Code | `CustomerEraser::erase()` |

Rules of thumb:

- Choose the word the domain experts or the existing code already use. Do not invent a new one.
- When a concept gets a new name, rename it everywhere in one change. A half-renamed term is worse than either name.
- A word that means two things in your project (for example "order" for a purchase and for a sort order) needs two words.
- Keep the word the same across languages in the stack: the column, the API field, the type and the UI label.

## Steer with positive terms

Reading "do not X" makes X part of the context. The model has to represent the banned idea to avoid it, and a prohibition can raise its odds, especially in a long window where the "do not" is far from the point of use. The wanted behavior, stated directly, gives the model something to do.

| Prohibition | Positive form |
|---|---|
| "Never use `var_dump` for debugging." | "Debug with the logger at debug level." |
| "Do not write long functions." | "Keep each function under 30 lines and split by responsibility." |
| "Don't mock the database in tests." | "Run tests against a real test database." |
| "Never commit to main." | "Work on a feature branch and open a pull request." |

Use a prohibition when:

- No single positive instruction covers it (a security boundary, a file that must not be edited). State the rule once, name the reason, and back it with a hook, a permission or a test so the text is not the only guard. See `hooks-and-guardrails`.
- The model keeps doing the unwanted thing and you have seen it. Pair the prohibition with the replacement: "Do not edit `generated/`. Change the schema in `api/schema.yaml` and run `make generate`."

Avoid listing the banned behaviors one by one in the always-on file. A list of bad examples is a list of ideas to remember.

## The no-op test

Before adding a line, ask: would a capable model do this without being told? If yes, the line does nothing. It still costs tokens on every turn and dilutes the lines that matter.

Typical no-ops:

| Line | Why it does nothing |
|---|---|
| "Write clean, readable code." | Every model already aims for this and the line has no checkable content. |
| "Use meaningful variable names." | Same. |
| "Think step by step." | Current models reason on their own. |
| "This is a Symfony project." | The composer file and directory layout say so. |
| "Run the tests before finishing." | Usually implied. Keep it only if you have seen the agent skip it, and then name the command. |

A line passes when it carries something the model cannot infer: an exact command, a convention that differs from the default, a decision with a reason, a trap seen in this repository.

Apply the test twice: once when writing a line, and once when reviewing a file that has grown. For each line, name the mistake the model would make without it. No mistake, no line. This is the same rule as "smallest high-signal set" in the main skill, applied one line at a time.

## Glossary

A project glossary is the source of leading words. It is a short file that names each domain concept once and lists the words not to use for it.

Keep it at `GLOSSARY.md` (or `docs/glossary.md`), and reference it from the always-on file with one line. Each entry has a definition and an _Avoid_ list:

```markdown
## Customer

A person or company with an active contract. Holds one or more accounts.

_Avoid_: user, client, member

## Erase

Remove a customer's personal data permanently, as required by a deletion request.

_Avoid_: delete, purge, wipe, remove
```

Guidelines:

- One sentence of definition. Say what the term is, not how it is built.
- List the synonyms the team or the model actually drifts into. A long speculative _Avoid_ list is a no-op.
- Include only terms specific to the domain. Common words and framework vocabulary stay out.
- Treat the glossary as binding for new text: specs, tickets, tests, identifiers and commit messages use the listed word.
- When a term changes, update the glossary first and rename the rest in the same change.
- If a project has none, extract one from the existing code and docs: count which names the code already uses for each concept and keep the most common as the leading word.

The glossary is not an overview. It does not describe architecture or list every class. It is a lookup table that makes the wording of everything else consistent.

## Quick checks

- [ ] Each concept has one name across rules, docs, code and tests
- [ ] A glossary exists for domain terms, with _Avoid_ lists for the synonyms that drift
- [ ] Rules say what to do. Prohibitions that remain name the replacement and have a guard
- [ ] Every line names a mistake the model would make without it
