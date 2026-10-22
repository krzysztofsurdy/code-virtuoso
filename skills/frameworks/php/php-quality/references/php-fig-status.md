# PHP-FIG standards status

Status as listed on the PHP-FIG site, checked 2026-10-22. PSR numbers never change and accepted PSRs are frozen, but status changes (a PSR can become Deprecated), so open https://www.php-fig.org/psr/ before stating a status in a review or an instruction file.

## Contents

- [PSR status](#psr-status)
- [PER status](#per-status)
- [Using this table](#using-this-table)
- [Sources](#sources)

## PSR status

| PSR | Title | Status | Notes |
|---|---|---|---|
| 0 | Autoloading Standard | Deprecated | Use PSR-4 |
| 1 | Basic Coding Standard | Accepted | PER-CS requires it |
| 2 | Coding Style Guide | Deprecated | PSR-12 "extends, expands and replaces" it |
| 3 | Logger Interface | Accepted | |
| 4 | Autoloading Standard | Accepted | |
| 5 | PHPDoc Standard | Draft | Not a usable standard yet |
| 6 | Caching Interface | Accepted | |
| 7 | HTTP Message Interface | Accepted | |
| 8 | Huggable Interface | Abandoned | |
| 9 | Security Advisories | Abandoned | |
| 10 | Security Reporting Process | Abandoned | |
| 11 | Container Interface | Accepted | |
| 12 | Extended Coding Style Guide | Accepted | Listed as Accepted, but PER Coding Style 3.1 states it extends, expands and replaces PSR-12. Target PER-CS |
| 13 | Hypermedia Links | Accepted | |
| 14 | Event Dispatcher | Accepted | |
| 15 | HTTP Handlers | Accepted | |
| 16 | Simple Cache | Accepted | |
| 17 | HTTP Factories | Accepted | |
| 18 | HTTP Client | Accepted | |
| 19 | PHPDoc tags | Draft | |
| 20 | Clock | Accepted | |
| 21 | Internationalization | Draft | |
| 22 | Application Tracing | Draft | |

The index at the time of checking had no PSR-23.

## PER status

| PER | Current release | Notes |
|---|---|---|
| Coding Style | 3.1 | "Extends, expands and replaces PSR-12". Requires PSR-1. Editor Larry Garfield, sponsor Chris Tankersley per the PER index. Earlier releases 1.0 (a direct equivalent of PSR-12), 2.0 and 3.0 have migration documents |

A PER is a meta document with several releases that can change over time, as opposed to a PSR that is frozen once accepted. The PER index at the time of checking listed only Coding Style.

## Using this table

- Correct stale claims in older material: PSR-2 is deprecated, PSR-0 is deprecated, and PSR-5, PSR-19, PSR-21 and PSR-22 are drafts, not standards.
- A PSR listed as Accepted can still be superseded in practice. PSR-12 is the case that matters for code style: the status field has not changed, but the PER says it replaces PSR-12.
- When a project's instructions say "PSR-12", read that as "a PSR-12 style". New text should say PER-CS and the revision.
- Interface PSRs (3, 6, 7, 11, 13 to 18, 20) are runtime contracts. Their status does not change how you format code.

## Sources

| Fact | URL |
|---|---|
| PSR index and statuses | https://www.php-fig.org/psr/ |
| PSR-12 | https://www.php-fig.org/psr/psr-12/ |
| PER index | https://www.php-fig.org/per/ |
| PER Coding Style 3.1 | https://www.php-fig.org/per/coding-style/ |
