---
type: llm
focus: last_message
---

PASS if the reply flags all of these on login.html with a severity for each: (1) the inputs have no programmatic label and only a placeholder (blocker level, highest severity); (2) autocomplete="off" on the form is a defect, not a security measure, because it removes autofill and does not stop password managers, and the fields should carry valid tokens such as email or username and current-password (WCAG 1.3.5); (3) the onpaste="return false" handler on the password field blocks paste and password managers and fails WCAG 3.3.8 Accessible Authentication; (4) input:focus { outline: none } removes the visible focus indicator. It must rank the autocomplete="off" issue below the missing labels and the paste block.
FAIL if the reply treats autocomplete="off" as good practice or ignores it, misses the paste block, misses the focus outline, gives no severity per finding, or ranks autocomplete="off" as a top-severity blocker.
