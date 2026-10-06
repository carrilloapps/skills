# Incident summary for leadership — `INC-<nnn>`

One page. Decision-oriented. No component names without a gloss, no severity jargon without its meaning, no metric without its unit.

**Incident**: `<plain-language failure>` · **Date**: `<DD Month YYYY>` · **Duration of impact**: `<duration>`
**Severity**: `SEV<n>` — `<one clause saying what that means here, e.g. "core function degraded for a subset of users">`
**Status**: `Resolved` | `Mitigated, permanent fix due <date>` | `Open`

## What happened

<Two or three sentences in plain language. What users experienced, for how long, and whether it is over. No internal service names unless glossed.>

## What it cost

| | |
|---|---|
| Users affected | `<count>` or `not measured` — `<what the figure measures>` |
| Requests or transactions affected | `<count or ratio>` |
| Data lost or incorrect | `<none / description>` |
| Financial or contractual exposure | `<none / description>` |
| Systems confirmed **not** affected | `<list>` |

## Why it was possible

<Two or three sentences on the conditions, not the people. One sentence on the triggering change. If a control held and limited the damage, say so here — leadership should know what is already working.>

## What changes

| # | Change | Type | Owner (role) | Due |
|---|--------|------|--------------|-----|
| 1 | `<change in plain language>` | prevent | `<role>` | `<date>` |
| 2 | `<change in plain language>` | detect | `<role>` | `<date>` |

## What we need from you

<Only if something is actually needed: a decision, a budget, a priority trade-off, or an accepted risk. If nothing is needed, write "Nothing — the team owns all open actions." Do not invent an ask.>

## Where the detail lives

Full postmortem: `docs/postmortems/<YYYY-MM-DD>_SEV<n>_<SLUG>_EN.md` (timeline, evidence, contributing factors, metrics).
