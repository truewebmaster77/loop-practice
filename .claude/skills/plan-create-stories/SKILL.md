---
name: plan-create-stories
description: Decomposes a PRD into well-formed, engineer-ready tickets — Jira issues or GitHub issues. Use after a PRD exists, to turn its phases and user stories into a structured backlog. Works for a new codebase (MVP scope) or an existing one (epic scope).
argument-hint: <prd-path> --platform <jira|github> [--project KEY] [--epic KEY] [--milestone NAME]
---

> **Adapted for this repository.** Originally from
> [coleam00/skills](https://github.com/coleam00/skills) by Cole Medin, MIT licensed.
> Changed so its output feeds the build loop here: tickets land on `needs-triage`
> and only a human ever applies `ready-for-agent`. See `docs/agents/` for how the
> loop consumes them.


# Create Stories: PRD → Ticket Backlog

## Overview

Turn a finished PRD into a backlog of small, well-formed tickets. Each
Implementation Phase in the PRD becomes a group of tickets; each User Story
becomes one or more tickets with explicit acceptance criteria.

This skill is platform-agnostic by design — the **`--platform` flag** decides
whether the backlog lands in Jira or in GitHub Issues. Everything before that
flag (reading the PRD, decomposing it, writing acceptance criteria) is
identical.

## Arguments

| Argument | Required | Meaning |
|----------|----------|---------|
| `<prd-path>` | yes | Path to the PRD produced by `plan-create-prd` |
| `--platform` | yes | `jira` or `github` — where the tickets are created |
| `--project` | jira only | Jira project key (e.g. `HELP`) |
| `--epic` | jira only | Jira epic key to parent the tickets under (e.g. `HELP-1`) |
| `--milestone` | github only | optional GitHub milestone to attach issues to |

If `--platform` is missing, **stop and ask** — do not guess.

## Workflow

### 1. Read and decompose the PRD
- Read `<prd-path>` in full.
- Walk the **Implementation Phases** section. Each phase is a ticket group.
- Walk the **User Stories** section. Each story maps to one ticket (split if it
  hides more than ~a day of work).
- For every ticket, draft:
  - **Title** — imperative, specific (`Add token refresh endpoint`, not `Auth`).
  - **Description** — what and why, linked back to the PRD phase.
  - **Acceptance criteria** — a checklist a reviewer can verify.
  - **Phase label** — which PRD phase it belongs to.
- Keep tickets small. A ticket that can't be described in one screen is two
  tickets.

### 2. Confirm the plan before creating anything
Print the proposed ticket list (titles + phase grouping) and the target
platform. This is the checkpoint — creating real tickets is not reversible in
one click.

### 3. Create the tickets — branch on `--platform`

**`--platform jira`:**
- Use the Atlassian MCP server.
- Create each ticket under `--epic` in `--project`.
- Map: PRD phase → a label or the epic; acceptance criteria → the description.
- Capture each created issue key.

**`--platform github`:**
- Use the `gh` CLI: `gh issue create --title "..." --body "..." --label needs-triage [--label phase-N] [--milestone "..."]`.
- Put acceptance criteria in the issue body as a markdown checklist, under a
  heading `## Acceptance criteria`. The heading matters — the triage station
  reads it to tell a specification apart from a bug report.
- **Always apply `needs-triage`.** In this repository that label is what starts
  the work; a ticket without it is invisible and will sit untouched forever.
- **Never apply `ready-for-agent`.** That label authorises an agent to change
  the code, and applying it is a human's decision. A tool that both writes the
  ticket and authorises it has removed the only checkpoint in the system.
- Apply a `phase-N` label per PRD phase as well (create it if missing with
  `gh label create`).
- Capture each created issue number/URL.

### 4. Report
- A table: ticket title → phase → created key/number/URL.
- The PRD path the backlog was generated from.
- Next step: each ticket is now on the triage queue. A human reads the drafted
  brief and applies `ready-for-agent` to the ones that should be built.

## Quality Checks

- ✅ Every ticket traces back to a PRD phase or user story
- ✅ Every ticket has verifiable acceptance criteria
- ✅ Tickets are small (≤ ~1 day of work)
- ✅ The correct platform was used and every create succeeded
- ✅ Phase grouping is preserved (labels/epic) so the backlog stays navigable

## Notes

- Greenfield vs brownfield changes the PRD's *scope* (MVP vs next epic), not
  this skill — `plan-create-stories` runs the same either way.
- Never create tickets without the step-2 confirmation.
- If a phase is too vague to decompose, stop and flag it — that's a PRD gap,
  not a ticket-writing problem.
