---
type: llm
focus: last_message
---

PASS if the reply does all of these: it says it is doing one mechanic first (double jump) and lists dash and wall sliding as later steps; it states a numeric pass check read from live game state before and after a simulated jump input (for example vertical velocity going from a value near 0 to a negative value); and it says that the behavior is not yet proven in the running game (Godot is not available or was not run here) instead of calling the work done.
FAIL if the reply implements or claims all three mechanics, or calls the double jump done or verified without having run the game, or offers no state-based pass check.
