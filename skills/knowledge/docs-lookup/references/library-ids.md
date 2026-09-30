# Context7 library IDs

Known-good IDs for common sources. All were checked on 2026-10-21 against `GET https://context7.com/api/v2/context?libraryId=<id>&query=overview&type=txt` and returned HTTP 200 with content.

IDs change when a source is re-indexed or renamed. If an ID returns 404 `library_not_found`, re-resolve by name (`resolve-library-id`, `npx ctx7 library <name> "<question>"`, or `GET /api/v2/libs/search?libraryName=<name>&query=<question>`) and update your notes. Do not guess a replacement ID.

## Picking the right entry

1. Read the installed version from the lockfile.
2. If a row below has a per-version ID that matches, use it. Otherwise use the "current" row.
3. After the first query, check the `Source:` URL in the snippet. It should name the version you expect (for example `/en/6.1/` or `7.4` in the path). If not, switch IDs.

## PHP and Symfony

| Source | ID | Status | Notes |
|---|---|---|---|
| Symfony docs, current | `/websites/symfony_doc_current` | Verified | Official symfony.com site. Tracks the latest stable docs |
| Symfony docs, pinned | `/symfony/symfony-docs/__branch__X.Y` | Verified for 7.4 and 8.0 (6.4 is listed) | Official repository, one branch per minor. Use the branch that matches `composer.lock`. Check the resolve result for the branches currently indexed |
| Symfony docs, 7.4 site | `/websites/symfony_doc_7_4` | Resolves | Also exists for 6.4 (`_6_4`). Ranks above `current` by benchmark score. Trap: use it only when the project is on 7.4 |
| PHP manual | `/websites/php_net_manual_en` | Verified | English php.net manual. Not version-split: check the "Changelog" table on each function page for the PHP version you target |
| Composer | `/websites/getcomposer_doc` | Verified | getcomposer.org docs |
| Rector | `/websites/getrector` | Verified | getrector.com documentation |

## Python and AI frameworks

| Source | ID | Status | Notes |
|---|---|---|---|
| Django, one version | `/websites/djangoproject_en_6_1` | Verified | Pattern: `/websites/djangoproject_en_<major>_<minor>`. `_5_2` also resolves. Pick the minor from `uv.lock`, `poetry.lock` or `requirements*.txt` |
| LangChain | `/websites/langchain_oss` | Verified | docs.langchain.com open-source docs, Python and JavaScript. Pass `language` to avoid mixing them |
| Deep Agents | `/websites/langchain_oss_python_deepagents` | Verified | Python Deep Agents section of the LangChain docs |
| Vercel AI SDK | `/vercel/ai` | Verified | Official repository. Version-pinned IDs follow `/vercel/ai/<version>` when the resolve result lists them |

## Standards and protocols

| Source | ID | Status | Notes |
|---|---|---|---|
| MCP specification | `/websites/modelcontextprotocol_io_specification_2026-07-28` | Verified | The date is the spec revision. A newer revision gets a new ID: re-resolve when the project targets a different revision |
| OWASP Top 10 | `/owasp/top10` | Verified | Official OWASP repository |
| WCAG | `/w3c/wcag` | Verified | Official W3C repository |

## Adding to this list

Add an entry only after the ID returns content and the `Source:` URL points to the vendor's own site or repository. Record the date checked. Prefer `/websites/<official-domain>...` or `/<official-org>/<repo>`.
