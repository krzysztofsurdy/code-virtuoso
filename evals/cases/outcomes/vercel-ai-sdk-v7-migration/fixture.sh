#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/app/api/chat
cat > package.json <<'JSON'
{
  "name": "support-chat",
  "private": true,
  "dependencies": {
    "@ai-sdk/openai": "^3.0.0",
    "@ai-sdk/react": "^3.0.0",
    "ai": "^6.0.312",
    "next": "^16.0.0",
    "react": "^19.0.0",
    "zod": "^4.1.8"
  }
}
JSON
cat > src/app/api/chat/route.ts <<'TS'
import { openai } from '@ai-sdk/openai';
import { convertToModelMessages, stepCountIs, streamText, tool, type UIMessage } from 'ai';
import { z } from 'zod';

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json();

  const result = streamText({
    model: openai('gpt-4.1'),
    system: 'You are a support agent. Be brief.',
    messages: convertToModelMessages(messages),
    tools: {
      refund: tool({
        description: 'Refund an order',
        inputSchema: z.object({ orderId: z.string(), amount: z.number() }),
        needsApproval: true,
        execute: async ({ orderId, amount }) => ({ orderId, refunded: amount }),
      }),
    },
    stopWhen: stepCountIs(8),
    experimental_telemetry: { isEnabled: true },
    onFinish: ({ usage }) => console.log(usage),
  });

  return result.toUIMessageStreamResponse();
}
TS
