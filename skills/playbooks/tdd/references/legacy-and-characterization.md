# Legacy code and characterization tests

Code without tests cannot be changed safely, because nothing tells you what you broke. The fix is to pin current behavior first, then change it. A characterization test (a term from Michael Feathers, "Working Effectively with Legacy Code") records what the code does today, whether or not that is correct.

## Contents

- [Procedure](#procedure)
- [Finding a seam](#finding-a-seam)
- [Writing the test](#writing-the-test)
- [Safe first moves](#safe-first-moves)
- [Pitfalls](#pitfalls)

## Procedure

1. Name the change you need to make and the code it will touch.
2. Find the nearest seam where you can call that code and observe its result.
3. Write characterization tests that cover the paths the change will touch.
4. Run them and check they pass against the unchanged code.
5. Make the change with the normal loop (red, green, refactor).
6. Keep the characterization tests that still describe wanted behavior. Delete or rewrite those that describe behavior you meant to change, and say so.

## Finding a seam

| Situation | Seam to try |
|---|---|
| Pure logic buried in a large function | Call the whole function with realistic input and assert the result |
| Code reads the clock, random numbers, or environment | Pass them in through a parameter or constructor with the current value as the default |
| Code calls a database or HTTP service directly | Test at the public entry point with a real test database or a fake of the client, or extract the call behind a small interface |
| Code writes to a file or sends output | Capture the output (temp directory, stream, spy) and assert on it |
| Only a UI or HTTP route exercises it | Drive it through that route in an integration test |
| Constructor does heavy work | Add a second constructor or factory that takes the dependencies, leaving the old one in place |

Make only the smallest edit needed to create the seam, and make it without changing behavior. Prefer edits the compiler or type checker can verify, such as extracting a parameter.

## Writing the test

1. Call the code with a realistic input. Use data copied from production logs or fixtures, with personal data removed.
2. Assert something wrong on purpose, such as an empty string or `0`, and run. The failure shows the actual output.
3. Copy the actual output into the assertion. Run again: it passes.
4. Read the assertion. If it records an obvious bug, add a comment or ticket reference saying the current behavior is believed wrong, and keep the assertion until someone fixes it on purpose.
5. Repeat with an edge case: empty input, boundary, invalid value, error path.

Step 2 is the red of a characterization test: it proves the test can fail and that you are looking at real output.

For large outputs (reports, rendered templates, serialized payloads), a snapshot or approval test does the same job. Review the snapshot once by hand and commit it.

## Safe first moves

These changes are low risk once the seam is covered:

- Rename a variable or function
- Extract a method or function
- Introduce a parameter with a default equal to the old value
- Replace a magic number with a named constant
- Delete code that tests and a search both show is unused

Do each as its own step, run the tests after each, and keep behavior changes in separate commits. See `refactoring` for the catalog.

## Pitfalls

| Pitfall | Better |
|---|---|
| Trying to cover the whole module first | Cover only the paths the change touches |
| Fixing bugs you find while characterizing | Record them, fix them in a separate change |
| Asserting on timestamps, ids, or ordering that vary | Fix the clock and seed, or assert on stable parts of the output |
| Refactoring to make testing easier before any test exists | Make the minimum seam edit, then test, then refactor |
| Treating characterization tests as the specification | They describe the past. New behavior is specified by a spec and new tests |
