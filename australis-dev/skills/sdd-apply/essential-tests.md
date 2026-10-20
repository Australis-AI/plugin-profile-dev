# Essential tests — apply phase

Applies when your prompt says `TEST RUNNER: <command>. ESSENTIAL TESTS ONLY.` It replaces the
implementation part of Step 3 of `${CLAUDE_PLUGIN_ROOT}/skills/sdd-apply/SKILL.md`; everything else
there (branch check, tasks, commits per work unit, `apply-progress.md`, the envelope) still
applies.

## What gets a test, and what does not

Tests protect what a person cannot see by using the app. What the user can see is checked with
the app running and by the user at the "Esto anda" gate: a test for it costs time and tokens, and
breaks with every design change.

| Write a test | Do not write a test |
|---|---|
| **Permissions:** who can read or change what (authorization in server actions, route handlers and the API; row-level security through the live check) | Copy, labels, layout, styling, colors |
| **Data integrity:** nothing saved wrong, lost or duplicated; what must never change once signed or published | That a component renders, or that a button exists |
| **Business rules with logic:** amounts, totals, dates, states and their transitions, validation | Plain create, read, update or delete with no rule on top |
| **The bug being fixed:** one test that fails before the fix | What the framework or a library already guarantees |
| An invariant named in the issue's technical constraints | Implementation details: CSS classes, internal state, call counts |

When in doubt, ask: *would the user notice this broke by using the app?* If yes, no test. If no,
test it.

## The cycle, for each essential behaviour

1. Write the test first, against code that does not do it yet.
2. Write the code until it passes. Run only that test file, never the whole suite: the full
   battery runs once, in verify.
3. One test per behaviour is the default. Add a second case only when the rule has a real
   boundary (a limit, a rounding, an empty case that is itself a rule), never to fill a quota.
4. Before modifying a file that already has tests, run them once. A failure there is
   pre-existing: report it, do not fix it.

## A test that counts

It calls the production code, asserts a concrete expected value, and would fail if the behaviour
broke. Never write:
- tautologies (`expect(true).toBe(true)`) or assertions that call no production code;
- assertions inside a loop over a list that could be empty;
- `toBeDefined()` or `not.toBeNull()` alone, without the value;
- assertions on CSS classes, internal state or how many times a mock was called.

If a test needs more mocks than assertions, the logic is in the wrong place: extract it to a pure
function and test that, with no mocks.

## Report — in `apply-progress.md`

```markdown
## Tests
| Behaviour | Test | Result |
|---|---|---|
| <permission, rule or invariant> | `path/to/file.test.ts` — <test name> | passed |

Checked with the app running instead of a test: <criteria about what the user sees, or "none">
```
