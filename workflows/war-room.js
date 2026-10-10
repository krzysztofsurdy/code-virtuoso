export const meta = {
  name: 'war-room',
  description: 'Structured debate for a technical decision: frame the options, collect positions, run one challenge round, and return a synthesis for you to decide',
  whenToUse: 'Architecture choices, technology selection, or design trade-offs with at least two viable options. Pass args {question, options?, constraints?}. The workflow never decides: it returns the trade-offs and you choose.',
  phases: [
    { title: 'Frame', detail: 'architect states the question, constraints, and options' },
    { title: 'Position', detail: 'four roles each argue for one option' },
    { title: 'Challenge', detail: 'each role attacks one other position, one round only' },
    { title: 'Synthesize', detail: 'architect summarizes agreement, disagreement, and risks' },
  ],
}

const input = args || {}
if (!input.question) {
  return { status: 'error', reason: 'Pass args {question: "<the decision to make>"}.' }
}

const ROLES = [
  { role: 'architect', agentType: 'agents-virtuoso:architect', lens: 'system design, maintainability, and technical debt' },
  { role: 'product-manager', agentType: 'agents-virtuoso:product-manager', lens: 'user impact, business value, and time to market' },
  { role: 'backend-dev', agentType: 'agents-virtuoso:backend-dev', lens: 'implementation complexity, developer experience, and operational burden' },
  { role: 'qa-engineer', agentType: 'agents-virtuoso:qa-engineer', lens: 'testability, risk surface, and failure modes' },
]
const ROLE_NAMES = ROLES.map(r => r.role)

const FRAME = {
  type: 'object',
  required: ['question', 'constraints', 'options'],
  properties: {
    question: { type: 'string' },
    constraints: { type: 'array', items: { type: 'string' } },
    options: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'name', 'summary'],
        properties: { id: { type: 'string' }, name: { type: 'string' }, summary: { type: 'string' } },
      },
    },
  },
}

const POSITION = {
  type: 'object',
  required: ['preferredOption', 'argument', 'risks'],
  properties: {
    preferredOption: { type: 'string' },
    argument: { type: 'string' },
    risks: { type: 'array', items: { type: 'string' } },
  },
}

const CHALLENGE = {
  type: 'object',
  required: ['target', 'weakestPoint', 'why'],
  properties: {
    target: { type: 'string', enum: ROLE_NAMES },
    weakestPoint: { type: 'string' },
    why: { type: 'string' },
  },
}

const SYNTHESIS = {
  type: 'object',
  required: ['agreements', 'disagreements', 'options'],
  properties: {
    agreements: { type: 'array', items: { type: 'string' } },
    disagreements: { type: 'array', items: { type: 'string' } },
    options: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'supporters', 'tradeoffs', 'risks'],
        properties: {
          id: { type: 'string' },
          supporters: { type: 'array', items: { type: 'string' } },
          tradeoffs: { type: 'array', items: { type: 'string' } },
          risks: { type: 'array', items: { type: 'string' } },
        },
      },
    },
  },
}

const PERSPECTIVE_ONLY = 'Answer from your domain knowledge only. Do not read files, run commands, or write files. Do not hedge: pick one option.'

phase('Frame')

const given = Array.isArray(input.options) && input.options.length > 0
  ? `Options already on the table: ${input.options.join('; ')}.`
  : 'Identify 2 to 4 realistic options.'

const frame = await agent(
  [
    'State the decision question precisely, list the known constraints, and list the options under consideration.',
    'Give each option a short id. Do not recommend anything. Do not read files or write files.',
    given,
    input.constraints ? `Known constraints: ${input.constraints}` : '',
    '',
    `Question: ${input.question}`,
  ].filter(Boolean).join('\n'),
  { label: 'Frame', phase: 'Frame', agentType: 'agents-virtuoso:architect', schema: FRAME },
)

if (!frame || frame.options.length < 2) {
  return { status: 'needs-framing', reason: 'Fewer than two viable options. Narrow the question or name the options in args.options.', frame }
}

phase('Position')

const positions = await parallel(
  ROLES.map(r => () => agent(
    [
      `You are the ${r.role} in a decision debate. Argue from ${r.lens}.`,
      'State which option you prefer and why, and list the main risks of that option.',
      PERSPECTIVE_ONLY,
      '',
      'Decision frame (JSON):',
      JSON.stringify(frame),
    ].join('\n'),
    { label: `${r.role} position`, phase: 'Position', agentType: r.agentType, schema: POSITION },
  )),
)
const stated = ROLES.map((r, i) => ({ role: r.role, ...positions[i] })).filter((_, i) => positions[i])

phase('Challenge')

const challenges = await parallel(
  ROLES.map(r => () => agent(
    [
      `You are the ${r.role}. Read every position below and name the weakest point in ONE other role's position.`,
      'Say which role you attack, quote the weak point, and explain why it fails. One challenge only.',
      PERSPECTIVE_ONLY,
      '',
      'Decision frame (JSON):',
      JSON.stringify(frame),
      '',
      'Positions (JSON):',
      JSON.stringify(stated),
    ].join('\n'),
    { label: `${r.role} challenge`, phase: 'Challenge', agentType: r.agentType, schema: CHALLENGE },
  )),
)
const challenged = ROLES.map((r, i) => ({ role: r.role, ...challenges[i] })).filter((_, i) => challenges[i])

phase('Synthesize')

const synthesis = await agent(
  [
    'Summarize the debate: where the roles agree, where they disagree, and for each option its supporters, trade-offs, and risks.',
    'Do not recommend an option. The user decides. Do not read files or write files.',
    '',
    'Decision frame (JSON):',
    JSON.stringify(frame),
    '',
    'Positions (JSON):',
    JSON.stringify(stated),
    '',
    'Challenges (JSON):',
    JSON.stringify(challenged),
  ].join('\n'),
  { label: 'Synthesis', phase: 'Synthesize', agentType: 'agents-virtuoso:architect', schema: SYNTHESIS },
)

return { status: 'awaiting-decision', frame, positions: stated, challenges: challenged, synthesis }
