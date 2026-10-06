# Team Safety — Shared Tools, Communication, Sensitive Data, Data Authority

Rules for anything the agent does that other people will see or depend on. They apply at every autonomy level.

---

## 1. Shared docs and tracker safety

1. **No destructive edits without approval of the exact change.** Replacing, overwriting, or deleting shared content (pages, tickets, comments, boards) is N0 by default; at most N3 with the exact before/after shown and approved.
2. **Back up before editing** — keep the previous version (export or copy into `.memory/local/agentic-agile/backups/<date>-<slug>.md`) before any approved edit of shared content.
3. **Resolve IDs at runtime** — look up page, ticket, board, and channel IDs from the capability in the session; never reuse an ID from memory or from an old file.
4. **No bulk operations** — one item per approved payload. A batch is a list of payloads, each visible and approved.
5. **Append over replace** — prefer adding a section or comment to rewriting someone else's text.

---

## 2. Team communication

1. **Draft first** — every message to a shared channel is a draft shown to the user; sending is N3 with the exact text approved.
2. **No mass mentions** — never `@channel`, `@here`, `@all`, or equivalents. Mention the owner.
3. **Breaking changes are announced before merge**, to the consumers named in the design, with the migration note.
4. **Never broadcast a live vulnerability.** Route it privately to the security owner and, when installed, to `sar-cybersecurity` for assessment. Public mention only after the fix ships and the owner agrees.
5. **An automated alert is a lead, not a conclusion.** Report it with its source and what was verified; do not announce a cause the evidence does not support.

---

## 3. Sharing sensitive data

1. Prefer not sharing: link to the system that owns the data instead of copying it.
2. If it must be shared, use an **encrypted channel for the content** and a **second, different channel for the key or passphrase**.
3. Transcript PII is redacted before anything leaves `.memory/local/` ([`transcripts.md`](transcripts.md)).
4. For file or text encryption, `sar-cybersecurity` documents an optional tool route (`frameworks/capabilities.md` in that skill). This skill does not duplicate it.

---

## 4. Data-domain authority

"Centralize the data" hides four separate decisions. Name them separately in any spec or decision that touches data:

| Decision | Question |
|----------|----------|
| **Governance** | Who defines the meaning, quality rules, and lifecycle of this data? |
| **Access** | Who may read it, through which interface, with what audit? |
| **Hosting** | Where does it physically live and who operates that system? |
| **Write authority** | Which single system is allowed to change it? |

- **System of record** (where writes happen) ≠ **system of analysis** (warehouse, semantic layer, reports). A report never becomes the place where data is corrected.
- **Federated pattern** — each domain keeps governance and write authority; shared access goes through a published contract (schema, semantic layer metric, API). The agent proposes this split as **Proposed**; the domain owners decide.
- Proper nouns and identifiers taken from transcripts are verified against the system of record before they appear in any published artifact.
