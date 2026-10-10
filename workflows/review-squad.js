export const meta = {
  name: 'review-squad',
  description: 'Review a change from three independent angles (zero context, spec compliance, full context) and return one triaged report',
  whenToUse: 'Before merging a significant change. Pass args {target, criteria?, deep?}: target names the change (branch, PR, or commit range), criteria holds acceptance criteria when they exist, deep adds a structural smell scan.',
  phases: [
    { title: 'Independent reviews', detail: 'cold reviewer, acceptance verifier, optional refactor scout' },
    { title: 'Lead review', detail: 'full-context reviewer merges and triages all reports' },
  ],
}

const input = args || {}
const target = input.target || 'the current branch compared with the default branch'
const criteria = typeof input.criteria === 'string' ? input.criteria.trim() : ''

const FINDING = {
  type: 'object',
  required: ['severity', 'title', 'detail'],
  properties: {
    file: { type: 'string' },
    line: { type: 'integer' },
    severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
    title: { type: 'string' },
    detail: { type: 'string' },
    suggestion: { type: 'string' },
  },
}

const FINDINGS = {
  type: 'object',
  required: ['findings'],
  properties: { findings: { type: 'array', items: FINDING } },
}

const CRITERIA_MATRIX = {
  type: 'object',
  required: ['criteria'],
  properties: {
    criteria: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'text', 'status', 'evidence'],
        properties: {
          id: { type: 'string' },
          text: { type: 'string' },
          status: { type: 'string', enum: ['PASS', 'FAIL', 'PARTIAL', 'UNTESTED'] },
          evidence: { type: 'string' },
        },
      },
    },
    outOfScope: { type: 'array', items: { type: 'string' } },
  },
}

const TRIAGED = {
  type: 'object',
  required: ['summary', 'findings'],
  properties: {
    summary: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'title', 'detail', 'foundBy', 'disposition'],
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          title: { type: 'string' },
          detail: { type: 'string' },
          suggestion: { type: 'string' },
          foundBy: { type: 'array', items: { type: 'string' } },
          disposition: { type: 'string', enum: ['fix', 'discuss', 'defer', 'dismiss'] },
        },
      },
    },
    criteriaMatrix: CRITERIA_MATRIX.properties.criteria,
  },
}

phase('Independent reviews')

const coldBrief = [
  `Review this change: ${target}.`,
  'Get the diff yourself with git. Review only what the diff shows.',
  'Do not read specs, README files, docs, or tickets, and do not ask what the change is for.',
  'Report bugs, unsafe patterns, unclear code, and missing tests that are visible from the code alone.',
].join(' ')

const verifierBrief = [
  `Check this change against the acceptance criteria below: ${target}.`,
  'Get the diff yourself with git. Give each criterion a status (PASS, FAIL, PARTIAL, UNTESTED) with file-level evidence.',
  'List changes that no criterion asks for under outOfScope. Do not read project docs.',
  '',
  'Acceptance criteria:',
  criteria,
].join('\n')

const scoutBrief = [
  `Scan the files touched by this change for structural problems: ${target}.`,
  'Report smells, duplication, and complexity hotspots as findings. Name the refactoring technique in the suggestion.',
].join(' ')

const jobs = [
  { key: 'cold', run: () => agent(coldBrief, { label: 'Cold review', phase: 'Independent reviews', agentType: 'agents-virtuoso:cold-reviewer', schema: FINDINGS }) },
]
if (criteria) {
  jobs.push({ key: 'acceptance', run: () => agent(verifierBrief, { label: 'Acceptance check', phase: 'Independent reviews', agentType: 'agents-virtuoso:acceptance-verifier', schema: CRITERIA_MATRIX }) })
} else {
  log('No acceptance criteria given: running the two-reviewer variant without the acceptance check.')
}
if (input.deep) {
  jobs.push({ key: 'scout', run: () => agent(scoutBrief, { label: 'Smell scan', phase: 'Independent reviews', agentType: 'agents-virtuoso:refactor-scout', schema: FINDINGS }) })
}

const results = await parallel(jobs.map(j => j.run))
const reports = Object.fromEntries(jobs.map((j, i) => [j.key, results[i]]))

phase('Lead review')

const leadBrief = [
  `You lead the review of this change: ${target}. Run your own full review (correctness, SOLID, security, performance, smells, tests) with full project context.`,
  'Then merge your findings with the reports below into one list.',
  'Rules: merge duplicates into one finding and record every source in foundBy (use "reviewer", "cold-reviewer", "acceptance-verifier", "refactor-scout"). When sources disagree on severity, keep the higher one.',
  'Give each finding a disposition: fix (must address), discuss (needs human judgment), defer (out of scope), or dismiss (false positive, say why in detail).',
  'Copy the acceptance criteria matrix into criteriaMatrix when one was provided. Write a short summary with the merge recommendation.',
  '',
  'Reports from the other reviewers (JSON, null means the reviewer failed):',
  JSON.stringify(reports),
].join('\n')

const report = await agent(leadBrief, { label: 'Lead review', phase: 'Lead review', agentType: 'agents-virtuoso:reviewer', schema: TRIAGED })

return { target, reviewersRun: Object.keys(reports).filter(k => reports[k]), report }
