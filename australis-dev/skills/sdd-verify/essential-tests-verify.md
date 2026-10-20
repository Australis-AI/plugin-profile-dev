# Essential tests — verify phase

Applies when your prompt says `TEST RUNNER: <command>. ESSENTIAL TESTS ONLY.` Read it together
with `${CLAUDE_PLUGIN_ROOT}/skills/sdd-verify/SKILL.md`. The policy is the one in
`${CLAUDE_PLUGIN_ROOT}/skills/sdd-apply/essential-tests.md`: tests protect what a person cannot see
by using the app.

## Evidence per criterion

| The criterion is about | ✅ needs | Without it |
|---|---|---|
| A permission, data integrity, a business rule, or the bug being fixed | A test that covers it and passed in this run's battery | CRITICAL |
| What the user sees: copy, layout, a screen, a message | Nothing from verify: mark it **"a ver en la app"**; the orchestrator checks it with the app running at the gate | Not a finding |

A missing test for something the user sees is never a finding.

## Check the tests that exist

Only the test files created or modified by this change:
- Calls production code and asserts a concrete value. A tautology, an assertion without production
  code, or assertions in a loop over a list that could be empty: CRITICAL.
- `toBeDefined()` or `not.toBeNull()` alone, snapshot-only tests, CSS class assertions: WARNING.
- A test for copy, layout or styling: WARNING, *"test that costs more than it protects"*; suggest
  deleting it.

No coverage report, no test-layer distribution, no TDD compliance table.

## Report — in the technical part of `verify.md`

```markdown
### Tests
- Essential behaviours: <n>; covered by a passing test: <n>
- To check with the app running at the gate: <criteria, or "none">
- Test quality: <findings, or "OK">
```

Nothing of this goes into the gate block.
