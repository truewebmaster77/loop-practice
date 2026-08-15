---
name: report-a-bug
description: File a bug report against this project's issue tracker. Use when you have found something broken — a wrong result, a crash, an error — and you are not the person who is going to fix it. Produces one well-formed GitHub issue and stops.
---

# Report a bug

You have found something wrong. Your job is to describe it accurately and stop. Something else
will reproduce it, work out the cause, and propose a fix; a human decides whether that fix goes
ahead.

**Do not fix it. Do not open a pull request. Do not apply any label except the one below.** A
report is a description, not a repair. If you have already changed code, say so in the report and
leave the change out of it.

## 1. Check it is not already known

    gh issue list --state all --search "<a few words from the symptom>"

Search by what it *does*, not by the words you would use. "Accented characters vanish from URLs"
and "letters go missing from links" are the same bug. If you find it, add what you know as a
comment on that issue instead of filing a new one, and stop.

## 2. Reproduce it, and shrink it

This is the part that matters most. A report with an exact reproduction gets fixed; a report
without one gets a round of questions first.

- Find the smallest input that shows the problem. If a 400-word document triggers it, find out
  whether three words do.
- Run it and record the **exact** output — copy it, do not paraphrase it. `"caf-life-in-paris"` is
  a bug report; "the slug looked wrong" is a conversation.
- Note whether it happens every time or only sometimes.

If you genuinely cannot reproduce it, say so plainly and report what you observed anyway. An
honest "seen once, could not reproduce" is useful. A guess dressed as a reproduction is not.

## 3. Do not diagnose

Resist this. You will often be able to see the cause, and saying so is usually a mistake:

- A stated cause anchors everyone who reads it. If you are wrong, the wrong thing gets fixed.
- The triage step reproduces the bug against the current code and finds the cause itself, from
  evidence rather than from your reading of it.
- Your view of the code may be out of date; the tracker's view never is.

If you are confident you know the cause, put it at the very bottom under **Possible cause**,
phrased as a guess. Never in the summary, never in the title.

## 4. File it

Use the repository's issue form if you can — it asks for exactly these fields. From the command
line:

```bash
gh issue create --label needs-triage \
  --title "<what is wrong, in plain words, no cause and no fix>" \
  --body "$(cat <<'EOF'
### What happened?

<the wrong behaviour, with the exact output quoted>

### What did you expect instead?

<one sentence>

### How can someone else see it happen?

1. <step>
2. <step>
3. <what appears>

Smallest input that shows it: `<the exact input>`

### Does it happen every time?

<every time / sometimes / seen once>

### Where were you?

<version, operating system, browser — whatever you know>
EOF
)"
```

**The `needs-triage` label is required and is the only label you may apply.** It is what starts
the work. Without it the issue sits there and nobody sees it.

**Never apply `ready-for-agent`.** That label authorises an agent to change the code, and applying
it is a human maintainer's decision. An agent that files a report and also authorises the work has
removed the only checkpoint in the system.

## File as a person, not as a bot

Use the `gh` sign-in of the human you are working for. The triage step deliberately refuses to run
for reports filed by a bot identity, because agents triggering each other is how a loop with no
brakes gets built. If your report is filed under a bot or app account it will sit there untouched,
so if you are unsure whose credentials you hold, check with `gh auth status` before filing.

## 5. Title it properly

The title is what a maintainer scans. Describe the symptom, from the user's side.

- Good: `Word count says 1 for an empty document`
- Good: `Export silently fails for titles ending in a full stop`
- Bad: `Fix trim() in wordCount` — that is a proposed fix, and it may be the wrong one
- Bad: `Bug in slugify` — says nothing a maintainer can act on

## 6. Then stop

Post the issue and report the number to whoever asked you. Do not start work on it, do not watch
it, and do not comment further unless you learn something new.

## One report, one problem

If you found three unrelated things, file three issues. A single issue containing several problems
cannot be closed, cannot be reviewed as one change, and will usually get partly fixed.
