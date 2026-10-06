# Incident Registry — `.memory/postmortem-writing/incidents.json`

Versioned team state: the list of incidents, their severity, their metrics, and the state of their actions. One file per project.

## Schema

```json
{
  "schemaVersion": 1,
  "incidents": [
    {
      "id": "INC-003",
      "date": "2026-10-06",
      "slug": "CHECKOUT-DB-POOL-EXHAUSTION",
      "title": "Checkout unavailable from database connection pool exhaustion",
      "severity": "SEV2",
      "severityInitial": "SEV3",
      "systemsAffected": ["checkout-api", "orders-db"],
      "detectedAt": "2026-10-06T14:12:03Z",
      "stabilizedAt": "2026-10-06T15:47:00Z",
      "resolvedAt": "2026-10-07T09:20:00Z",
      "timeToDetectMin": 7,
      "timeToMitigateMin": 95,
      "timeToResolveMin": 1148,
      "report": "docs/postmortems/2026-10-06_SEV2_CHECKOUT-DB-POOL-EXHAUSTION_EN.md",
      "sarFinding": null,
      "actions": [
        {
          "id": "A-01",
          "type": "prevent",
          "tracesTo": "CF-1",
          "owner": "platform lead",
          "due": "2026-10-13",
          "verification": "A PR with 40 x 6 fails the pipeline check",
          "state": "Open",
          "reviewOn": "2026-10-20"
        }
      ],
      "status": "Open",
      "lessons": ["L-1", "L-2", "L-3"]
    }
  ]
}
```

## Field definitions

| Field | Owner | Rule |
|-------|-------|------|
| `id` | Agent (on creation) | `INC-<nnn>`, sequential, **permanent** — never reused, never renumbered |
| `date` | Agent | Incident start date, ISO |
| `slug` | Agent | SCREAMING-KEBAB-CASE, matches the report filename |
| `title` | Agent | Names the failure, not the fix |
| `severity` | Agent | Final `SEV1`–`SEV4` from the rubric |
| `severityInitial` | Agent | Only when reclassified; otherwise `null` |
| `systemsAffected` | Agent | Array of service names |
| `detectedAt`, `stabilizedAt`, `resolvedAt` | Agent | ISO 8601 UTC, or `null` when unknown or pending |
| `timeToDetectMin`, `timeToMitigateMin`, `timeToResolveMin` | Agent | Integer minutes, or `null` when `not measured` — **never** an estimate |
| `report` | Agent | Project-relative path to the EN report |
| `sarFinding` | Agent | SAR finding ID when the cause is a security defect, else `null` |
| `actions[]` | Mixed | `id`, `type`, `tracesTo`, `owner`, `due`, `verification` are agent-written; **`state` and `reviewOn` are team-managed** |
| `status` | **Team** | `Open` · `Closed`. The agent writes `Open` on creation and never changes it |
| `lessons` | Agent | Lesson IDs exported for devils-advocate |

## Update rules

1. **Add** a new incident with `status: "Open"` and every action `state: "Open"`.
2. **Never delete** an entry. A superseded incident keeps its row; corrections go in the report's revision history.
3. **Never modify** `status`, an action's `state`, or an action's `reviewOn` once written — those belong to the team. On a later run the agent reads them and reports what is overdue.
4. **Update** `severity` (keeping `severityInitial`), `resolvedAt`, and the metrics when new evidence arrives, and record the reason in the report.
5. **Metrics are measured or `null`.** A `null` is the honest value and the input to a `detect` action.
6. **No extra fields** beyond the schema. Bump `schemaVersion` only through a skill release.
7. **Sort** by `date` descending, so the newest incident is first.

## Validation — after every write

Re-read the file and confirm:

1. It parses as valid JSON against the schema above.
2. No duplicate `id`.
3. Every `status`, action `state`, and action `reviewOn` from the previous version is unchanged.
4. No entry from the previous version is missing.
5. Sort order is correct.

If any check fails, fix the file before writing the report's final version.

If the existing file does **not** parse, never overwrite it: leave it untouched, write the new registry to `incidents.recovered.json` beside it (ignored by the `.memory/` rule), and state in Out of scope & limitations that the team must reconcile the two files.

## Seeding

If the registry does not exist but reports do (for example, public mode on another machine where the registry is not versioned), read the **Registry snapshot** of the most recent report in the directory and import its rows, keeping `id`, `status`, and action state.
