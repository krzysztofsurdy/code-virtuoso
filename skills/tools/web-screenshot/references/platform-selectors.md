# Platform selectors for element captures

When capturing a region instead of the whole viewport, the CSS selector matters more than the tool. This reference lists selectors for common content types and platforms, plus the checks to run before trusting one.

The selectors below were observed on live sites, and sites change markup without notice. Confirm that the chosen selector resolves to a sensible bounding box before relying on it. Treat the lists as starting points.

## Contents

- [Verification routine](#verification-routine)
- [By content type](#by-content-type)
- [Generic semantic containers](#generic-semantic-containers)
- [Multiple matches](#multiple-matches)
- [When the selector is inside a shadow DOM](#when-the-selector-is-inside-a-shadow-dom)

## Verification routine

Run these three checks every time, whichever selector you chose:

| Step | Tool | What to look for |
|---|---|---|
| **1. Element exists** | Run a `document.querySelector("<sel>")` evaluation. | Non-null result. If null, the selector is stale - fall back to a semantic container (`article`, `main`, `[role="main"]`). |
| **2. Bounding box is sane** | `getBoundingClientRect()` or the equivalent in your capture tool. | Width between 100 and viewport width. Height greater than 50. Box does not equal the whole page (which means the selector matches the wrapper, not the content). |
| **3. Scroll into view** | `scrollIntoView({block:'start'})` before the shot. | The capture should fire after a short settle delay - 200-500 ms - to let lazy-loaded content paint. |

If step 1 or 2 fails, try the next selector down the list. Vendor-specific selectors break first; semantic-HTML selectors break last.

## By content type

### Article body or blog post

| Site shape | Try first | Fallback chain |
|---|---|---|
| Marketing blog (Medium-style, Substack, Ghost) | `article` | `[role="article"]`, `main article`, `.post-content`, `.entry-content` |
| Newspaper / magazine | `article[itemtype*="Article"]` | `[itemprop="articleBody"]`, `main`, `.story-body`, `.article__body` |
| Documentation page | `main article` | `[role="main"]`, `.markdown-body`, `.content`, `#content` |
| Personal blog | `article` | `.post`, `.entry`, `main` |

### Social post

| Platform | Try first | Fallback chain |
|---|---|---|
| Reddit (new) | `shreddit-post` | `[data-testid="post-container"]`, `article[id^="post-"]` |
| Reddit (old) | `.thing.link` | `.entry`, `[data-fullname^="t3_"]` |
| X / Twitter | `article[data-testid="tweet"]` | `[role="article"][tabindex="-1"]` |
| LinkedIn (feed) | `.feed-shared-update-v2` | `[data-urn^="urn:li:activity"]`, `article` |
| LinkedIn (article) | `.reader-content` | `article`, `main` |
| Facebook (post) | `[role="article"]` | `[data-pagelet^="FeedUnit"]` |
| Mastodon | `[data-id^="status:"]` | `article.status` |
| Bluesky | `[data-testid^="postThreadItem"]` | `[data-testid="postThread"]` |

### Comment or thread

| Platform | Try first | Fallback chain |
|---|---|---|
| Reddit (top comment) | `shreddit-comment` | `[data-testid="comment"]`, `.Comment` |
| Hacker News (story + comments) | `#hnmain .fatitem` | `table.fatitem`, `#pagespace + table` |
| Hacker News (single comment) | `tr.athing.comtr` | `tr.comtr` |
| Stack Overflow (question) | `#question` | `.question`, `#mainbar #question` |
| Stack Overflow (top answer) | `.answer.accepted-answer` | `.answer:first-of-type`, `#answers .answer` |
| GitHub discussion (post) | `[data-testid="discussion-post-content"]` | `.timeline-comment`, `.markdown-body` |

### Code hosting

| Target | Try first | Fallback chain |
|---|---|---|
| GitHub repo header (name + description) | `[data-pjax="#repo-content-pjax-container"] header` | `.gh-header`, `header` |
| GitHub repo README | `article.markdown-body` | `.markdown-body`, `[data-target="readme-toc.content"]` |
| GitHub file view | `[data-testid="code-view"]` | `.blob-wrapper`, `.highlight` |
| GitHub pull-request body | `.timeline-comment` | `[data-testid="issue-body"]`, `.markdown-body` |
| GitLab merge request body | `.detail-page-description` | `.merge-request-details`, `.description` |

### Video and rich-media

| Target | Try first | Fallback chain |
|---|---|---|
| YouTube player area | `#player-container-outer` | `#player`, `ytd-watch-flexy` |
| YouTube video title + description | `#title h1, #description` | `#meta`, `#above-the-fold` |
| Vimeo player | `.player_container` | `[data-player-container]` |

### Product / pricing card

| Target | Try first | Fallback chain |
|---|---|---|
| Generic product hero | `[itemtype*="Product"]` | `.product`, `#product`, `main` |
| Pricing table | `[itemtype*="Offer"]` | `.pricing`, `.plans`, `section[id*="pricing"]` |
| App-store listing | `[data-testid="app-card"]` | `main`, `article` |

## Generic semantic containers

When all vendor-specific selectors fail, these usually exist on a well-structured page:

| Selector | Semantic meaning |
|---|---|
| `main` | The primary content of the page |
| `[role="main"]` | Explicit ARIA marker for primary content |
| `article` | Self-contained content unit (post, article, comment) |
| `[role="article"]` | Explicit ARIA marker for article content |
| `[role="region"][aria-label]` | A labelled landmark - often a hero or content section |
| `#content`, `#main`, `.content`, `.main` | Conventional id/class wrappers used by CMS templates |

If even these are missing, the page is likely a single-page-app with all content nested under a div - try `body > div > div`-level selectors only as a last resort. A fixed-position viewport capture is better than a fragile selector.

## Multiple matches

A selector that returns many elements (`article` on a feed page) needs disambiguation:

1. Add a position pseudo-class: `article:first-of-type`, `article:nth-of-type(2)`.
2. Add a content predicate via `:has()`: `article:has(h1:contains("Title"))` (Playwright/Chrome 105+).
3. Filter by visible text in the capture tool: most tools accept a `text=` qualifier.
4. Open the canonical permalink URL of the target post. The page then has a single target, and the first `article` is the right one.

Option 4 is usually the cleanest, because permalinks expose only the target item without surrounding feed noise.

## When the selector is inside a shadow DOM

Web components hide their markup under a shadow root, and `document.querySelector` at page level cannot reach inside. Two ways through:

1. **Use the host element as the capture target.** The bounding box includes the shadow content even if the inner markup is inaccessible. Works for `shreddit-post` (Reddit), `ytd-watch-flexy` (YouTube), and most custom elements.
2. **Pierce with `>>>` in Playwright / agent-browser.** Some tools accept `host-tag >>> .inner-class` syntax to step through shadow boundaries.

If neither works and the capture still misses content, switch to a viewport-based capture and let the layout do the cropping.
