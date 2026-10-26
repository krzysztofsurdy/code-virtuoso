---
type: llm
focus: last_message
---

PASS if the reply does all of these: (1) says to read and annotate real or realistic traces first and build a named failure taxonomy before choosing graders, (2) replaces the 1 to 5 score with binary pass or fail checks tied to one specific failure each, (3) prefers code checks on the final state of the world for the refund flow (for example the refund record exists with the right amount) over judging the text, (4) says every LLM judge must be validated against human labels on a held-out split and reports TPR and TNR, (5) says BERTScore or generic helpfulness scores are not a quality measure.
FAIL if the reply keeps the 1 to 5 score or BERTScore as the gate, or does not mention validating the judge against human labels.
