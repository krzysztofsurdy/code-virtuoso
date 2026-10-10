export const meta = {
  name: 'development-team',
  description: 'Deliver a feature from a ticket: requirements, design, readiness gate, parallel backend and frontend implementation in worktrees, integration, QA sign-off',
  whenToUse: 'End-to-end delivery of a feature that spans backend and frontend. Pass args {ticket, backendOnly?}. The run stops at the first failed gate and returns what blocked it, so re-run after you resolve it. Worktrees branch from the default branch unless the worktree.baseRef setting is "head".',
  phases: [
    { title: 'Requirements', detail: 'product manager writes acceptance criteria' },
    { title: 'Design', detail: 'architect defines contract and tasks' },
    { title: 'Readiness gate', detail: 'plan auditor checks requirements, design, and tasks line up' },
    { title: 'Implementation', detail: 'backend and frontend developers in separate worktrees' },
    { title: 'Integration', detail: 'merge both branches and run the full suite' },
    { title: 'QA sign-off', detail: 'QA engineer verifies every criterion' },
  ],
}

const input = args || {}
if (!input.ticket) {
  return { status: 'error', reason: 'Pass args {ticket: "<ticket text or id>"}.' }
}
const backendOnly = Boolean(input.backendOnly)

const REQUIREMENTS = {
  type: 'object',
  required: ['criteria', 'scope', 'nonGoals', 'openQuestions'],
  properties: {
    criteria: { type: 'array', items: { type: 'string' } },
    scope: { type: 'string' },
    nonGoals: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
}

const DESIGN = {
  type: 'object',
  required: ['contract', 'dataModel', 'tasks'],
  properties: {
    contract: { type: 'string' },
    dataModel: { type: 'string' },
    adr: { type: 'string' },
    tasks: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'owner', 'description', 'files', 'criteria'],
        properties: {
          id: { type: 'string' },
          owner: { type: 'string', enum: ['backend', 'frontend'] },
          description: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
          criteria: { type: 'array', items: { type: 'string' } },
        },
      },
    },
  },
}

const GATE = {
  type: 'object',
  required: ['verdict', 'gaps'],
  properties: {
    verdict: { type: 'string', enum: ['READY', 'NEEDS WORK', 'NOT READY'] },
    gaps: { type: 'array', items: { type: 'string' } },
  },
}

const DELIVERY = {
  type: 'object',
  required: ['branch', 'commits', 'tasksDone', 'tasksBlocked', 'testsPassing'],
  properties: {
    branch: { type: 'string' },
    commits: { type: 'array', items: { type: 'string' } },
    tasksDone: { type: 'array', items: { type: 'string' } },
    tasksBlocked: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'reason'],
        properties: { id: { type: 'string' }, reason: { type: 'string' } },
      },
    },
    testsPassing: { type: 'boolean' },
  },
}

const INTEGRATION = {
  type: 'object',
  required: ['branch', 'merged', 'testsPassing', 'notes'],
  properties: {
    branch: { type: 'string' },
    merged: { type: 'boolean' },
    testsPassing: { type: 'boolean' },
    notes: { type: 'string' },
  },
}

const SIGNOFF = {
  type: 'object',
  required: ['approved', 'results', 'bugs'],
  properties: {
    approved: { type: 'boolean' },
    results: {
      type: 'array',
      items: {
        type: 'object',
        required: ['criterion', 'status', 'evidence'],
        properties: {
          criterion: { type: 'string' },
          status: { type: 'string', enum: ['PASS', 'FAIL', 'UNTESTED'] },
          evidence: { type: 'string' },
        },
      },
    },
    bugs: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'title', 'detail'],
        properties: {
          severity: { type: 'string', enum: ['P0', 'P1', 'P2', 'P3'] },
          title: { type: 'string' },
          detail: { type: 'string' },
        },
      },
    },
  },
}

phase('Requirements')

const requirements = await agent(
  [
    'Analyse this ticket and write acceptance criteria in Given/When/Then form.',
    'State scope and non-goals. List open questions only when a missing answer would change the design.',
    'Do not edit files.',
    '',
    `Ticket: ${input.ticket}`,
  ].join('\n'),
  { label: 'Requirements', phase: 'Requirements', agentType: 'agents-virtuoso:product-manager', schema: REQUIREMENTS },
)

if (!requirements) {
  return { status: 'failed', stage: 'Requirements' }
}
if (requirements.openQuestions.length > 0) {
  return { status: 'needs-clarification', stage: 'Requirements', openQuestions: requirements.openQuestions, requirements }
}

phase('Design')

const design = await agent(
  [
    'Design the solution for the requirements below. Define the API contract, data model changes, and component boundaries.',
    'Write an ADR text only if the design introduces a new pattern.',
    'Split the work into tasks. Each task has one owner (backend or frontend), the exact files it may touch, and the acceptance criteria it satisfies.',
    'No file may appear in more than one task. Do not edit files.',
    backendOnly ? 'This is backend-only work: every task is owned by backend.' : '',
    '',
    'Requirements (JSON):',
    JSON.stringify(requirements),
  ].filter(Boolean).join('\n'),
  { label: 'Design', phase: 'Design', agentType: 'agents-virtuoso:architect', schema: DESIGN },
)

if (!design) {
  return { status: 'failed', stage: 'Design', requirements }
}

const tasks = backendOnly ? design.tasks.filter(t => t.owner === 'backend') : design.tasks
const owners = ['backend', 'frontend'].filter(o => tasks.some(t => t.owner === o))
const seen = new Map()
const overlaps = []
for (const t of tasks) {
  for (const f of t.files) {
    if (seen.has(f) && seen.get(f) !== t.owner) overlaps.push(f)
    seen.set(f, t.owner)
  }
}
if (overlaps.length > 0) {
  return { status: 'blocked', stage: 'Design', reason: 'Backend and frontend tasks share files, so they cannot run in parallel worktrees.', files: overlaps, design }
}

phase('Readiness gate')

const gate = await agent(
  [
    'Gate mode: we are about to start implementation. Check that the requirements, the design, and the task list line up.',
    'Trace every acceptance criterion to a design element and a task. Report contradictions and untestable criteria.',
    '',
    'Requirements (JSON):',
    JSON.stringify(requirements),
    '',
    'Design and tasks (JSON):',
    JSON.stringify({ ...design, tasks }),
  ].join('\n'),
  { label: 'Readiness gate', phase: 'Readiness gate', agentType: 'agents-virtuoso:plan-auditor', schema: GATE },
)

if (!gate || gate.verdict !== 'READY') {
  return { status: 'blocked', stage: 'Readiness gate', gate, requirements, design }
}

phase('Implementation')
log('Developers work in worktrees. Each branch starts from the default branch unless the worktree.baseRef setting is "head".')

const developerBrief = owner => [
  `You are the ${owner} developer. Implement only the ${owner} tasks below with strict TDD: write a failing test, make it pass, refactor, and commit after each green test.`,
  'Touch only the files listed for your tasks. Follow the API contract exactly. If the contract cannot work, stop and report the task as blocked with the reason instead of changing it.',
  'Commit your work on your worktree branch. Report the branch name and the commit hashes.',
  '',
  'API contract:',
  design.contract,
  '',
  'Data model:',
  design.dataModel,
  '',
  `Your tasks (JSON):`,
  JSON.stringify(tasks.filter(t => t.owner === owner)),
].join('\n')

const deliveries = await parallel(
  owners.map(owner => () => agent(developerBrief(owner), {
    label: `${owner} developer`,
    phase: 'Implementation',
    agentType: owner === 'backend' ? 'agents-virtuoso:backend-dev' : 'agents-virtuoso:frontend-dev',
    isolation: 'worktree',
    schema: DELIVERY,
  })),
)
const delivered = owners.map((owner, i) => ({ owner, delivery: deliveries[i] }))
const incomplete = delivered.filter(d => !d.delivery || d.delivery.tasksBlocked.length > 0 || !d.delivery.testsPassing)
if (incomplete.length > 0) {
  return { status: 'blocked', stage: 'Implementation', delivered, requirements, design }
}

phase('Integration')

const integration = await agent(
  [
    'Create an integration branch from the default branch and merge the branches below into it, one at a time, running the full test suite after each merge.',
    'If a merge conflicts, stop and report it in notes. Do not resolve logic conflicts.',
    'Report the integration branch name.',
    '',
    'Branches:',
    JSON.stringify(delivered.map(d => ({ owner: d.owner, branch: d.delivery.branch }))),
  ].join('\n'),
  { label: 'Integration', phase: 'Integration', isolation: 'worktree', schema: INTEGRATION },
)

if (!integration || !integration.merged || !integration.testsPassing) {
  return { status: 'blocked', stage: 'Integration', integration, delivered }
}

phase('QA sign-off')

const signoff = await agent(
  [
    `Verify the integrated feature on branch ${integration.branch} against every acceptance criterion below.`,
    'Run the tests, check each criterion with evidence, and report bugs with a severity (P0 to P3).',
    'Approve only when every criterion passes and no P0 or P1 bug is open. Do not fix bugs.',
    '',
    'Acceptance criteria (JSON):',
    JSON.stringify(requirements.criteria),
  ].join('\n'),
  { label: 'QA sign-off', phase: 'QA sign-off', agentType: 'agents-virtuoso:qa-engineer', schema: SIGNOFF },
)

return {
  status: signoff && signoff.approved ? 'approved' : 'needs-fixes',
  integrationBranch: integration.branch,
  signoff,
  delivered,
  next: 'Run the review-squad workflow on the integration branch, then open the pull request.',
}
