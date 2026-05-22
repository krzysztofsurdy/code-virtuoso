# Anti-Patterns Guide

Common Scrum Master anti-patterns that undermine team effectiveness. Each anti-pattern includes symptoms, consequences, root cause, and a correction strategy. Recognizing these patterns early prevents them from becoming entrenched.

---

## Anti-Pattern Categories

| Category | Description |
|---|---|
| **Role confusion** | The SM takes on responsibilities that belong to other roles |
| **Over-protection** | The SM shields the team so much they become disconnected |
| **Under-challenge** | The SM avoids uncomfortable conversations or lets poor practices slide |
| **Process rigidity** | The SM treats scrum rules as sacred instead of adapting to context |
| **Metric misuse** | The SM uses metrics to control rather than to inform |

---

## Role Confusion Anti-Patterns

### The Project Manager in Disguise

**Symptoms**: SM assigns tasks to individuals, tracks hours, reports status to management, creates Gantt charts, asks "when will this be done?" instead of "what is blocking you?"

**Consequences**: Team loses self-management capability. Developers wait to be told what to do. The SM becomes a bottleneck for all decisions.

**Root cause**: The SM has a project management background and defaults to command-and-control. Or the organization expects the SM to be a project manager with a new title.

**Correction**:
1. Stop assigning tasks - let the team self-assign during Sprint Planning
2. Replace status tracking with Sprint Goal progress tracking
3. Coach the team to report their own progress in the Daily Scrum
4. Push back on management requests for individual status reports - offer team-level Sprint Goal progress instead
5. Use a delegation board to make explicit which decisions belong to the team

### The Technical Lead

**Symptoms**: SM makes technical decisions, reviews all code, decides on architecture, overrides developer choices on implementation approach.

**Consequences**: Developers defer all technical decisions to the SM. Technical debt accumulates in areas the SM does not review. Innovation is suppressed.

**Root cause**: The SM is the most experienced developer on the team and defaults to technical authority.

**Correction**:
1. Explicitly hand technical decisions to the development team
2. If asked for a technical opinion, respond with a coaching question: "What are the trade-offs you see?"
3. Encourage the team to establish their own technical practices and standards
4. If the team truly lacks technical capability, advocate for training or an architect role rather than filling the gap yourself

### The Secretary

**Symptoms**: SM takes notes for the team, updates the board for them, sends reminders for every event, books all meetings, manages the calendar.

**Consequences**: The team becomes passive. Administrative tasks pile up on the SM. If the SM is absent, nothing happens.

**Root cause**: The SM wants to be helpful and defaults to administrative support. The team is happy to let someone else handle logistics.

**Correction**:
1. Rotate administrative responsibilities among team members
2. Set up automated reminders instead of sending them manually
3. Coach the team to own their own board updates
4. If a team member forgets to update the board, ask them to do it rather than doing it yourself

---

## Over-Protection Anti-Patterns

### The Bubble Wrapper

**Symptoms**: SM intercepts all communication with the team, prevents stakeholders from talking to developers directly, filters all information before sharing with the team, says no to every request from outside.

**Consequences**: The team becomes isolated from business context. Developers do not understand why they are building what they are building. Stakeholders feel blocked and find workarounds. The SM becomes a communication bottleneck.

**Root cause**: The SM interprets "protect the Sprint" as "prevent all external contact." Or the team experienced disruption in the past and the SM overcorrected.

**Correction**:
1. "Protect the Sprint" means protecting focus on the Sprint Goal, not preventing all communication
2. Allow stakeholders to attend Sprint Reviews and provide feedback directly
3. Coach the team on how to handle ad-hoc requests: acknowledge, add to the backlog, discuss in refinement
4. Be a filter for urgency, not for information - the team needs context to make good decisions

### The Hero

**Symptoms**: SM resolves every impediment personally, works overtime to clear blockers, never asks for help, takes on tasks outside their role to "keep the Sprint on track."

**Consequences**: SM burns out. Team never learns to resolve their own problems. When the SM is unavailable, impediments pile up. The team's self-management muscle atrophies.

**Root cause**: The SM has a strong sense of personal responsibility and equates team success with personal effort.

**Correction**:
1. For team-level impediments, ask: "How would you approach this?" before stepping in
2. Track which impediments the team resolved themselves vs which the SM resolved
3. Set a target: each Sprint, the team should resolve a higher percentage of impediments independently
4. Delegate impediment resolution to team members when possible
5. Accept that some impediments will take longer when the team resolves them - the learning is worth the delay

---

## Under-Challenge Anti-Patterns

### The Conflict Avoider

**Symptoms**: SM ignores tensions between team members, does not address repeated violations of working agreements, lets dysfunctional behavior slide because "the team will work it out."

**Consequences**: Unresolved conflicts fester and damage trust. Working agreements become meaningless. Quiet team members disengage. Toxic behaviors become normalized.

**Root cause**: The SM is uncomfortable with confrontation or lacks skills in conflict facilitation.

**Correction**:
1. Address conflicts early when they are small - waiting makes them harder
2. Use objective observations: "I noticed X happened. What was the impact?" rather than accusations
3. Refer to working agreements: "We agreed to Y. What happened here?"
4. Facilitate a structured conversation between conflicting parties using the COIN model: Context, Observation, Impact, Next steps
5. Practice - conflict facilitation is a skill that improves with use

### The Comfortable Enabler

**Symptoms**: SM does not challenge the team when velocity plateaus, accepts low Sprint Goal ambition, does not address recurring retrospective themes, lets the team stay in their comfort zone.

**Consequences**: The team stops improving. Retrospectives become routine without impact. Mediocre becomes the standard. High performers leave.

**Root cause**: The SM values team harmony over team growth. Or the SM does not have a clear picture of what "better" looks like.

**Correction**:
1. Track improvement trends - show the team their trajectory
2. Ask: "Are we getting better? How do we know?"
3. Introduce stretch goals: "What would world-class look like for this team?"
4. Bring external perspectives - share how other teams approach similar challenges
5. Challenge gently but persistently: "We have talked about this in three retrospectives. What is different this time?"

---

## Process Rigidity Anti-Patterns

### The Scrum Police

**Symptoms**: SM insists on following every scrum rule exactly as written, rejects any adaptation, corrects terminology pedantically, treats the Scrum Guide as law.

**Consequences**: The team resents scrum because it feels rigid and bureaucratic. Practical improvements are blocked because they do not match the Scrum Guide. The team complies but does not buy in.

**Root cause**: The SM is newly certified and interprets scrum literally. Or the SM uses rules as a source of authority.

**Correction**:
1. Understand the purpose behind each scrum rule before enforcing it
2. Ask: "What problem does this rule solve? Is there a better way to solve that problem in our context?"
3. Follow the scrum principle of inspect-and-adapt - if a practice is not working, experiment with alternatives
4. Focus on outcomes: are we delivering value incrementally and improving continuously?

### The Ceremony Robot

**Symptoms**: Events happen on schedule but lack energy or purpose. The retrospective uses the same format every time. Sprint Planning follows a rigid script. Participants go through the motions.

**Consequences**: Events become a chore. Participation drops. Insights stop surfacing. The team sees scrum events as overhead rather than value.

**Root cause**: The SM has a routine that works and does not adapt it. Or the SM lacks a repertoire of facilitation techniques.

**Correction**:
1. Rotate retrospective formats - see the facilitation techniques reference
2. Start events with an unexpected question or activity to reset energy
3. Ask the team: "Is this event valuable to you? What would make it more valuable?"
4. Skip optional elements when the team does not need them - adapt the event to the Sprint context
5. Bring data to events - concrete numbers create engagement that routines do not

---

## Metric Misuse Anti-Patterns

### The Velocity Optimizer

**Symptoms**: SM treats velocity as a performance metric, compares velocity across teams, pressures the team to increase velocity each Sprint, celebrates velocity increases without checking quality.

**Consequences**: Story point inflation. Team games the system. Quality drops as the team rushes to increase output. Velocity becomes meaningless for planning.

**Root cause**: Management asks for velocity reports as a productivity measure. The SM does not push back on this misuse.

**Correction**:
1. Velocity is a planning tool, not a performance metric - use it only for Sprint capacity forecasting
2. Never compare velocity across teams - different teams use different scales
3. Track outcome metrics instead: Sprint Goal completion rate, escaped defects, cycle time
4. Push back on management requests for velocity as a KPI - explain why it is counterproductive
5. If velocity increases, ask: "Is quality also improving?" Check escaped defects and rework rate

### The Dashboard Obsessive

**Symptoms**: SM creates elaborate dashboards with dozens of metrics, spends more time updating charts than coaching the team, presents metrics the team does not understand or care about.

**Consequences**: Metrics become overhead. The team feels surveilled. The SM spends time on measurement instead of improvement. Important signals get lost in noise.

**Root cause**: The SM equates visibility with effectiveness. Or management demands extensive reporting.

**Correction**:
1. Limit to 3-5 metrics that the team finds useful for their own improvement
2. Ask the team: "Which of these metrics help you make better decisions?"
3. Automate metric collection where possible - manual tracking is unsustainable
4. Review metrics in retrospectives, not in separate reporting meetings
5. Drop any metric that has not influenced a decision in the last month

---

## Anti-Pattern Assessment

Use this checklist to audit your own behavior each Sprint:

- [ ] I did not assign tasks to individual team members
- [ ] I did not make technical decisions that belong to the developers
- [ ] I addressed at least one uncomfortable truth this Sprint
- [ ] I asked coaching questions more often than I gave directives
- [ ] I allowed the team to struggle with a problem before stepping in
- [ ] I did not use velocity as a performance metric
- [ ] I adapted at least one event format or approach this Sprint
- [ ] I tracked whether the team is becoming more self-managing
- [ ] I escalated organizational impediments rather than absorbing them silently
- [ ] I sought feedback on my own effectiveness as a Scrum Master
