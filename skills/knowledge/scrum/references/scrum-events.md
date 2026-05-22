# Scrum Events

Every Scrum event is a formal opportunity to inspect and adapt. Events create regularity and minimize the need for ad-hoc meetings. Skipping events or exceeding timeboxes erodes the empirical process.

---

## The Sprint

The Sprint is the container for all other events. Sprints are fixed-length iterations of one month or less. New Sprints begin immediately after the previous Sprint concludes.

**Key rules:**
- No changes that endanger the Sprint Goal are permitted
- Quality standards (Definition of Done) remain constant
- Scope may be clarified and renegotiated with the Product Owner as the team learns more
- Only the Product Owner has authority to cancel a Sprint (when the Sprint Goal becomes obsolete)
- Shorter Sprints reduce risk, generate faster feedback, and limit cost of going in the wrong direction

---

## Sprint Planning

Initiates the Sprint by establishing what will be done and how. The entire Scrum Team collaborates.

**Timebox:** 8 hours maximum for a 1-month Sprint. Proportionally shorter for shorter Sprints.

### Topic 1: Why Is This Sprint Valuable?

The Product Owner proposes how the product could increase value and importance in this Sprint. The Scrum Team collaborates to define the Sprint Goal.

**Facilitation tips:**
- Product Owner comes prepared with prioritized backlog items and their connection to the Product Goal
- Ask: "What is the single most important outcome we can deliver this Sprint?"
- The Sprint Goal must be finalized before planning concludes
- Avoid letting the team jump to "how" before agreeing on "why"

### Topic 2: What Can Be Done This Sprint?

Developers select items from the Product Backlog for the Sprint. The team discusses which items can be completed within the Sprint.

**Facilitation tips:**
- Base selection on past performance (velocity), upcoming capacity (holidays, on-call), and the Definition of Done
- Developers make the final call on how much they can take on - the PO does not dictate quantity
- If an item is too large, break it down or negotiate a smaller slice with the PO
- Refine items enough that the team is confident they understand the work

### Topic 3: How Will the Work Get Done?

Developers plan how to create an Increment that meets the Definition of Done. Items are decomposed into tasks, typically one day or smaller.

**Facilitation tips:**
- Only Developers determine how work gets done - the PO and SM do not dictate implementation
- Create a delivery plan visible to the whole team (board, task breakdown)
- Identify dependencies and risks early
- Do not plan every task in detail - just enough to start confidently

### Sprint Planning Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| PO dictates what and how much | Developers own capacity decisions |
| No Sprint Goal defined | Always start with "why" before "what" |
| Planning takes all day | Timebox strictly; refine the backlog before planning |
| Team commits to more than capacity | Use historical velocity, not optimism |
| Items not refined before planning | Maintain a healthy backlog with items ready 2 sprints ahead |

---

## Daily Scrum

A 15-minute event for the Developers to inspect progress toward the Sprint Goal and produce an actionable plan for the next day of work.

**Timebox:** 15 minutes, same time and place every day.

### Structure Options

The Daily Scrum is for the Developers. They choose the structure. Common formats:

**Three Questions (traditional):**
1. What did I do yesterday that helped the team meet the Sprint Goal?
2. What will I do today to help the team meet the Sprint Goal?
3. Do I see any impediment that prevents me or the team from meeting the Sprint Goal?

**Walk the Board:**
- Start from the rightmost column (closest to Done) and move left
- Focus on: What is blocked? What needs help? What can move forward today?
- More effective for teams that lose focus with round-robin updates

**Sprint Goal Focus:**
- "Are we on track to meet the Sprint Goal?"
- If yes: brief updates, move on
- If no: what do we need to change today?

### Daily Scrum Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Status report to the SM or PO | Redirect focus to peer coordination |
| Exceeds 15 minutes | Timebox strictly; take detailed discussions offline |
| Problem-solving during the standup | Identify problems, schedule follow-ups after |
| People report on tasks, not progress toward goal | Anchor every update to the Sprint Goal |
| Skipping when things are "going well" | The value is in daily inspection; do not skip |

---

## Sprint Review

The Scrum Team presents Sprint results to key stakeholders and collaborates on what to do next. This is a working session, not a presentation or demo.

**Timebox:** 4 hours maximum for a 1-month Sprint.

### Structure

1. **Sprint Goal recap** - Did we meet it? What was the outcome?
2. **Demonstrate the Increment** - Show working software, not slides
3. **Discuss what happened** - What changed during the Sprint? What was learned?
4. **Inspect the Product Backlog** - Based on progress and new information, what should come next?
5. **Collaborate on next steps** - Stakeholders and team discuss emerging opportunities, market changes, budget

### Facilitation Tips

- Invite stakeholders who have a genuine interest in the Sprint Goal
- Include the Sprint Goal in the invitation so stakeholders can assess relevance
- Let Developers demonstrate their own work
- Encourage stakeholder questions and feedback - this is the primary value
- Capture feedback as Product Backlog items or adjustments to existing items
- Avoid turning it into a sign-off ceremony - it is a collaboration session

### Sprint Review Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| PowerPoint demo instead of working software | Demonstrate the actual Increment |
| Only the PO presents | Developers present their own work |
| No stakeholder attendance | Send targeted invitations with Sprint Goal; make it valuable to attend |
| Rubber-stamp approval | Actively solicit feedback and tough questions |
| Skipped "because nothing changed" | Always hold the review - even a failed Sprint has learnings |

---

## Sprint Retrospective

The team inspects the previous Sprint regarding individuals, interactions, processes, tools, and their Definition of Done. The goal is to identify improvements and plan actions.

**Timebox:** 3 hours maximum for a 1-month Sprint.

### Retrospective Formats

#### Start-Stop-Continue

The simplest and most common format. Three columns:

| Start | Stop | Continue |
|---|---|---|
| Things we should begin doing | Things that are not helping | Things that are working well |

Each team member contributes items to each column. Group similar items, discuss, and pick 1-3 actions.

#### Mad-Sad-Glad

Emotional check-in format. Useful when team morale or interpersonal dynamics need attention.

| Mad | Sad | Glad |
|---|---|---|
| Frustrating situations | Disappointing outcomes | Positive experiences |

#### 4Ls (Liked, Learned, Lacked, Longed For)

Structured reflection covering positive experiences, new knowledge, gaps, and wishes.

| Liked | Learned | Lacked | Longed For |
|---|---|---|---|
| What went well | New insights | What was missing | What we wish we had |

#### Sailboat

Visual metaphor. Draw a sailboat:
- **Wind** (what propels us forward)
- **Anchor** (what holds us back)
- **Rocks** (risks ahead)
- **Island** (our goal/destination)

Good for teams that respond to visual facilitation.

### Facilitation Tips

- Vary the format every few sprints to avoid staleness
- Create psychological safety - no blame, focus on systems not individuals
- Timebox each phase (gather data, discuss, decide on actions)
- Limit actions to 1-3 per retrospective - fewer, concrete actions beat a long wish list
- Track previous action items - start each retro by reviewing what was committed last time
- The Scrum Master participates as a team member, not just a facilitator

### Retrospective Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Same complaints every retro, nothing changes | Track actions and follow through; if nothing changes, escalate |
| Blame individuals | Focus on processes and systems; establish ground rules |
| Skipped "because we're too busy" | The retro is how you get less busy - it improves the process |
| Only negative feedback | Explicitly include a "what went well" phase |
| Actions are vague ("communicate better") | Make actions specific: who, what, by when |
| Management attends and team self-censors | Management should not attend unless explicitly invited by the team |
