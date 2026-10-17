export const meta = {
  name: 'TODO-team',
  description: 'TODO: what the team delivers, in one sentence',
  whenToUse: 'TODO: when to run it and the args it takes, for example {target, criteria?}',
  phases: [
    { title: 'Work', detail: 'TODO: which agents run and what each returns' },
    { title: 'Review', detail: 'TODO: which agent merges or checks the results' },
  ],
}

const input = args || {}
if (typeof input.target !== 'string' || !input.target.trim()) {
  return { status: 'error', reason: 'args.target is required' }
}

const FINDINGS = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'title', 'detail'],
        properties: {
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          title: { type: 'string' },
          detail: { type: 'string' },
        },
      },
    },
  },
}

phase('Work')

const results = await parallel([
  () => agent(`TODO: full brief for the first agent. Target: ${input.target}.`, {
    label: 'First agent',
    phase: 'Work',
    agentType: 'agents-virtuoso:TODO-agent-name',
    schema: FINDINGS,
  }),
  () => agent(`TODO: full brief for the second agent. Target: ${input.target}.`, {
    label: 'Second agent',
    phase: 'Work',
    agentType: 'agents-virtuoso:TODO-agent-name',
    schema: FINDINGS,
  }),
])

const reports = results.filter(Boolean)
if (reports.length === 0) {
  return { status: 'blocked', reason: 'every agent in the Work phase failed' }
}

phase('Review')

const report = await agent(
  `TODO: lead brief. Merge the reports below into one list.\n${JSON.stringify(reports)}`,
  { label: 'Lead review', phase: 'Review', agentType: 'agents-virtuoso:TODO-agent-name', schema: FINDINGS },
)

return { status: 'approved', target: input.target, report }
