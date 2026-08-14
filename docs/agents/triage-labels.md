# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the right-hand column to match whatever vocabulary you actually use.

## Labels outside the triage vocabulary

These exist on this repo but are not triage roles, so no skill applies them automatically:

| Label                   | Applied by                | Meaning                                                    |
| ----------------------- | ------------------------- | ---------------------------------------------------------- |
| `in-progress`           | the loop, on claiming     | A run owns this issue; nothing else may start on it        |
| `changes-requested`     | the loop, after review    | The reviewer returned blocking findings on the pull request |
| `ready-for-human-merge` | the loop, on approval     | CI green and reviewer approved; waiting on a human to merge |
