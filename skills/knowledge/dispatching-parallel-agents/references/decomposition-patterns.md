# Decomposition Patterns

How to split work into independent units for parallel subagent execution. Each pattern fits a different task shape. The wrong pattern creates artificial dependencies or wastes agent capacity.

---

## Contents

- [Fan-out / Fan-in](#fan-out--fan-in)
- [Pipeline](#pipeline)
- [Scatter-gather](#scatter-gather)
- [Specialist-per-concern](#specialist-per-concern)
- [Map-reduce](#map-reduce)
- [Choosing the right pattern](#choosing-the-right-pattern)

## Fan-out / Fan-in

The most common dispatch pattern: one orchestrator sends work to N subagents, waits for all to complete, and synthesizes results.

### Shape

```
Orchestrator ---> Agent A ---> Result A ---|
             |                             |
             +--> Agent B ---> Result B ---+--> Synthesis
             |                             |
             +--> Agent C ---> Result C ---|
```

### When to use

- N independent tasks with no data dependencies between them
- All tasks can start immediately with information the orchestrator already has
- Results need to be combined into a single deliverable

### Decision criteria

- Can each task complete without knowing any other task's result? If yes, fan-out works.
- Do all tasks need the same input preparation? If input prep is expensive, do it once before dispatch.
- Is N reasonable (3-7)? Beyond 7, consider whether some tasks should be grouped.

### Examples with project agents

**Multi-area investigation:**
```
Orchestrator -> Investigator("How does the auth subsystem work?")
             -> Investigator("How does the payment subsystem work?")
             -> Investigator("How does the notification subsystem work?")
          <- Merged findings document with cross-references
```

**Parallel review:**
```
Orchestrator -> Reviewer("Review src/Auth/ for SOLID compliance")
             -> Reviewer("Review src/Payment/ for SOLID compliance")
             -> Reviewer("Review src/Notification/ for SOLID compliance")
          <- Consolidated review with severity-ranked findings
```

**Coverage analysis:**
```
Orchestrator -> Test Gap Analyzer("Analyze test coverage for module A")
             -> Test Gap Analyzer("Analyze test coverage for module B")
             -> Test Gap Analyzer("Analyze test coverage for module C")
          <- Prioritized list of missing tests across all modules
```

### Synthesis responsibilities

The orchestrator must:
- Deduplicate findings that appear in multiple agent outputs
- Resolve contradictions (Agent A says X is safe, Agent B says X is risky)
- Order results by priority or severity
- Identify cross-cutting concerns that no single agent noticed

---

## Pipeline

Sequential stages where the output of one stage feeds the next. Parallelism happens within each stage, not across stages.

### Shape

```
Stage 1: [Agent A, Agent B] ---> Combined Stage 1 Output
Stage 2: [Agent C, Agent D] ---> Combined Stage 2 Output  (uses Stage 1 output)
Stage 3: [Agent E]          ---> Final Output              (uses Stage 2 output)
```

### When to use

- Work has clear phase dependencies (understand before design, design before implement)
- Each phase can be parallelized internally even though phases are sequential
- Quality gates exist between phases (review before proceeding)

### Decision criteria

- Is there a natural ordering where later work depends on earlier work? If yes, pipeline.
- Can you parallelize within each stage? If each stage is a single task, this is plain sequential execution.
- Are there quality gates? Pipelines support stop/go decisions between stages.

### Examples with project agents

**Feature delivery pipeline:**
```
Stage 1 (Define):    Product Manager -> Requirements document
Stage 2 (Design):    Architect -> API contracts + component design
Stage 3 (Build):     [Backend Dev(API), Frontend Dev(UI)] -> Working code
Stage 4 (Validate):  [QA Engineer, Reviewer] -> Quality report
```

Stages 1 and 2 are sequential (single agent each). Stage 3 fans out to two agents working in isolated worktrees. Stage 4 fans out to two read-only agents.

**Investigation-to-implementation pipeline:**
```
Stage 1 (Investigate): [Investigator(area-A), Investigator(area-B)]
Stage 2 (Plan):        Architect (receives merged investigation findings)
Stage 3 (Implement):   [Implementer(component-1), Implementer(component-2)]
Stage 4 (Review):      Reviewer (reviews both worktree branches)
```

### Stage transition rules

- The orchestrator reviews stage output before starting the next stage
- If stage output reveals the decomposition was wrong, re-plan rather than push forward
- Each stage's agents receive only the synthesized output of the previous stage, not raw agent results

---

## Scatter-gather

Send the same question or task to multiple specialists who approach it from different angles. Merge the best insights from each response.

### Shape

```
Same question ---> Specialist A (security lens)   ---> Perspective A ---|
              |                                                         |
              +--> Specialist B (performance lens) ---> Perspective B --+--> Merged view
              |                                                         |
              +--> Specialist C (correctness lens) ---> Perspective C ---|
```

### When to use

- A problem benefits from multiple perspectives
- Each specialist has a distinct evaluation framework
- You want a full analysis without sequential bias (where the first analysis anchors later ones)

### Decision criteria

- Would different specialists notice different things? If all would find the same issues, scatter-gather wastes agents.
- Is the question well-defined enough that all specialists can work from the same input? If the question is ambiguous, sequential clarification is better.
- Do the perspectives complement each other? Security, performance, and correctness reviews are complementary. Three security reviews are redundant.

### Examples with project agents

**Multi-dimensional code review:**
```
Same code -> Reviewer (correctness and SOLID)
          -> Refactor Scout (code smells and complexity)
          -> Test Gap Analyzer (missing test coverage)
      <- Consolidated report: bugs, smells, and coverage gaps ranked together
```

**Architecture assessment:**
```
Same design doc -> Architect (evaluates trade-offs and boundaries)
               -> Reviewer (evaluates implementation feasibility)
               -> Migration Planner (evaluates migration risk)
           <- Unified assessment with go/no-go recommendation
```

### Synthesis challenge

Scatter-gather produces the most overlap. The orchestrator must:
- Weight perspectives (a security finding may outrank a style finding)
- Reconcile conflicting assessments
- Avoid double-counting issues found by multiple specialists

---

## Specialist-per-concern

Assign each agent a distinct concern or dimension of the task. Unlike scatter-gather, agents work on different aspects of the same codebase rather than the same aspect from different angles.

### Shape

```
Codebase ---> Agent A (security audit)     ---> Security findings
         |                                       |
         +--> Agent B (dependency audit)    ---> Dependency findings    ---> Unified report
         |                                       |
         +--> Agent C (performance profiling) -> Performance findings
```

### When to use

- A full assessment requires expertise across multiple domains
- Each concern has its own investigation methodology
- Results are additive (security findings + dependency findings = more complete picture)

### Decision criteria

- Are the concerns distinct? If "security audit" and "dependency audit" examine the same files for the same things, combine them.
- Does each concern require different tools or approaches? If yes, specialist-per-concern is appropriate.
- Is there a natural specialist for each concern? Map concerns to available agent types.

### Examples with project agents

**Pre-release health check:**
```
Codebase -> Dependency Auditor (CVE checks, outdated packages)
         -> Refactor Scout (code quality hotspots)
         -> Test Gap Analyzer (coverage gaps)
         -> Reviewer (SOLID and security review of changed files)
     <- Release readiness report with findings by category
```

**Migration readiness assessment:**
```
Migration files -> Migration Planner (risk classification, rollback paths)
Application code -> Reviewer (schema compatibility check)
Test suite -> Test Gap Analyzer (migration-related test coverage)
         <- Migration execution plan with risk assessment
```

---

## Map-reduce

Split a large input into chunks, process each chunk with the same operation, then merge results. The "map" is the parallel processing; the "reduce" is the synthesis.

### Shape

```
Large input -> Chunk 1 -> Agent A -> Result 1 ---|
            -> Chunk 2 -> Agent B -> Result 2 ---+--> Reduce (merge)
            -> Chunk 3 -> Agent C -> Result 3 ---|
```

### When to use

- The same operation must be applied to a large dataset or many files
- Processing order does not matter
- Results can be merged mechanically (counts, lists, categorized findings)

### Decision criteria

- Is the operation the same for each chunk? If different chunks need different handling, use specialist-per-concern instead.
- Can chunks be defined without overlap? If splitting creates boundary issues (e.g., a function spanning two file chunks), adjust chunk boundaries.
- Is mechanical merging sufficient, or does synthesis require judgment? Map-reduce works best with structured, mergeable outputs.

### Examples with project agents

**Large-scale refactoring assessment:**
```
50 source files -> [Refactor Scout(files 1-10), Refactor Scout(files 11-20), ...]
              <- Merged smell report with frequency counts and file locations
```

**Multi-module test gap analysis:**
```
8 modules -> [Test Gap Analyzer(module 1-2), Test Gap Analyzer(module 3-4), ...]
         <- Combined gap report sorted by priority
```

### Reduce strategy

- Concatenate lists (all findings from all chunks)
- Deduplicate entries that appear at chunk boundaries
- Aggregate counts and statistics
- Sort by a consistent criterion (severity, file path, priority)

---

## Choosing the right pattern

| Question | If yes | If no |
|---|---|---|
| Are all tasks independent with no shared state? | Fan-out / Fan-in | Consider Pipeline |
| Does work have clear sequential phases? | Pipeline | Fan-out or Scatter-gather |
| Do you want multiple perspectives on the same thing? | Scatter-gather | Specialist-per-concern |
| Does each agent own a distinct domain? | Specialist-per-concern | Fan-out |
| Is it the same operation on different data chunks? | Map-reduce | Fan-out or Specialist |

### Pattern combinations

Real workflows often combine patterns:

- **Pipeline with fan-out stages**: Sequential phases where some phases parallelize internally
- **Fan-out then map-reduce**: Dispatch investigators, then map-reduce their findings into a summary
- **Scatter-gather into pipeline**: Multiple perspectives feed into a sequential decision pipeline

Apply the right pattern at each level of the workflow instead of forcing the whole task into one pattern.
