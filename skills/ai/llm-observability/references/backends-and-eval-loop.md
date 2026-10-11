## Contents

- [Backends that accept OTLP](#backends-that-accept-otlp)
- [Collector in the middle](#collector-in-the-middle)
- [Check the mapping](#check-the-mapping)
- [Connect traces to eval datasets](#connect-traces-to-eval-datasets)
- [Scores on traces](#scores-on-traces)
- [Sources](#sources)

# Backends and the eval loop

Instrument once with OpenTelemetry and keep the choice of backend open. The details below were checked against vendor docs on 2026-10-21. Endpoints, headers, and regions change, so copy current values from the vendor's docs and keep keys in a secret store, never in the repository.

## Backends that accept OTLP

| Backend | How OTLP is accepted | Auth | Notes |
|---|---|---|---|
| Langfuse | HTTP endpoint at `/api/public/otel` on your host, or the signal path `/api/public/otel/v1/traces`. JSON and protobuf. gRPC is not supported | HTTP Basic with the project public and secret key. A header setting the ingestion version makes data appear in real time | Open source, self-hostable, cloud regions. Follows GenAI conventions, still evolving, and maps common attributes from other ecosystems. Its own `langfuse.*` attributes take precedence. Acquired by ClickHouse in 2026-01 |
| LangSmith | Standard `OTEL_EXPORTER_OTLP_ENDPOINT` set to the LangSmith base `/otel` URL. Do not add `/v1/traces`, the exporter appends it. Regional and self-hosted hosts differ | API key in the OTLP headers. Optional project header | Maps GenAI conventions and other vendor formats to its run fields. A child span is dropped if its parent was never exported to LangSmith |
| Phoenix (Arize) | OTLP, built on OpenTelemetry. Auto-instrumentation comes from the OpenInference project | Depends on deployment | Self-hostable. Licence is Elastic License 2.0 (source-available). Basic web analytics on by default, can be turned off |
| Braintrust | OTLP over HTTP. Traces at `/otel/v1/traces` under the data plane URL. Logs also supported | Bearer API key plus a project header | Every trace needs a root span to show in the logs table. Region must match your organization's data plane |

If a vendor is not listed, check for an OTLP endpoint in its docs. Support for gRPC varies, and some backends accept HTTP only.

## Collector in the middle

Run an OpenTelemetry Collector between your apps and the backends.

```text
app  ==OTLP==>  collector  ==+==>  backend A (LLM observability)
                  redact       |
                  tail sample  +==>  backend B (general traces, metrics)
                  transform
```

What it gives you:

- **Redaction** in one place you control, before data leaves, see [privacy-and-sampling](privacy-and-sampling.md).
- **Tail sampling** with the collector's processor.
- **Fan-out** to several backends, for example an LLM-focused tool and your existing tracing stack. One vendor documents exactly this with multiple HTTP exporters.
- **Attribute transforms** so a convention rename needs a config change, not a code change.
- **Keys and endpoints** outside application code.

Distributed tracing works the same as elsewhere: propagate trace context across services so a gateway, an agent service, and a tool service join one trace. Send both parent and child spans to the same backend, or the child may be dropped or orphaned.

## Check the mapping

Backends map your attributes to their own fields (input, output, model, usage, cost). After wiring, send one test trace with a known request and verify:

| Check | Why |
|---|---|
| Model name shows correctly | Cost lookup depends on it |
| Input, output, cached, and reasoning tokens appear as you sent them | Subset rules can differ between your data and the backend's model |
| Cost matches your own calculation | Catches a missing or wrong price entry |
| Tool spans nest under the agent span | Parent links survived the export |
| Content is absent when capture is off | Confirms the privacy default |
| Latency and time to first token fields are populated | Streaming data made it through |

Repeat after each instrumentation or backend upgrade.

## Connect traces to eval datasets

Observability and evals share one set of traces. A loop that works:

1. **Collect.** Production traces flow to the backend with feature, prompt version, and release attributes.
2. **Select.** Each week, pull a sample: random traces plus errors, slow, costly, and flagged runs. See `llm-evals` for the sampling mix.
3. **Review.** A human annotates the sample and tags failures with a name from the taxonomy.
4. **Promote.** Add confirmed failures to the regression dataset. Keep the source trace id on each case, so you can go from a failing eval back to the production run and the reverse. Redact content before copying it into a dataset.
5. **Run.** The eval harness runs the app with the same instrumentation. Tag eval traffic with an eval run id and case id. Send it to a separate project or environment so it never mixes with production metrics.
6. **Score.** Attach results to the traces as scores.
7. **Compare.** For each prompt or model version compare score, cost, latency, and step count side by side.

Why one shape matters: if offline runs emit the same spans as production, a cost or step-count regression that shows up in the eval run predicts what production will see.

## Scores on traces

Most LLM backends let you attach a score or annotation to a trace or span. Use it for:

| Score source | Example |
|---|---|
| Human label | Reviewer marks a trace pass or fail for a named failure |
| Validated judge | Online judge flags suspect traces. Use as a queue for humans, not as truth |
| Code check | Schema valid, no forbidden tool call |
| User feedback | Thumbs down, escalation, abandoned session |

Store scores with the name of the failure mode, the grader version, and whether the grader is validated. Filter traces by score to build review queues. A judge's raw score should be corrected with its measured TPR and TNR before you report a rate, see the `llm-evals` skill.

## Sources

- Langfuse OpenTelemetry integration: https://langfuse.com/docs/opentelemetry/get-started
- LangSmith, trace with OpenTelemetry: https://docs.langchain.com/langsmith/trace-with-opentelemetry
- Braintrust, OpenTelemetry integration: https://www.braintrust.dev/docs/integrations/sdk-integrations/opentelemetry
- Phoenix repository (licence, self-hosting, OpenInference): https://github.com/Arize-ai/phoenix
- ClickHouse on acquiring Langfuse: https://clickhouse.com/blog/clickhouse-acquires-langfuse-open-source-llm-observability
- OpenTelemetry sampling concepts: https://opentelemetry.io/docs/concepts/sampling/
