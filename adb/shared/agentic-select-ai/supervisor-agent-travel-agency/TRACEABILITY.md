# Travel Agency Lab Source Traceability

Scope: Rewrite the existing single lab using the supplied notebook and the Sales Return Agent style. No notebook or manifest edits. Estimated learner time: 60 minutes across 13 tasks.

| Source | Classification and evidence | Use |
| --- | --- | --- |
| `files/SelectAI4SQL - Travel Reservation Supervisor Agent.dsnb` | Oracle-authored sample; opening Markdown identifies Oracle copyright and UPL 1.0. | Travel scenario, synthetic inventory and reservations, all 34 executable paragraphs, and explanations across 13 tasks. |
| `../build-sales-return-agent/build-sales-return-agent.md` | Oracle LiveLabs lab with Oracle copyright and documentation license. | Introduction/Objectives/Prerequisites structure, task pacing, conditional login/import and credential paths. |
| OML and OCI screenshots in `../build-sales-return-agent/images/` referenced by the lab | Oracle product UI screenshots already supplied by the Oracle LiveLabs source lab. | Shared login, import, and OCI credential navigation. Screenshots containing the Sales Return notebook name were not reused. |
| [Supervisor Agent Pattern](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/supervisor-agent.html) and [usage guidance](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/how-to-use-select-ai-supervisor-agent-teams.html) | Public Oracle documentation, checked September 21, 2026. | Supervisor attributes, worker context, sequential delegation, and Learn More links. |

The notebook's remotely linked diagram and stored execution outputs were not copied. No external source assets were introduced.

## Coverage and editorial decisions

* Task 1 covers the opening concepts and imports the supplied local notebook.
* Tasks 2–3 cover notebook data and functions (paragraphs 5–14); the stale customer-table explanation is corrected to travel tables.
* Tasks 4–5 cover credentials and profile (15–18), preserving the disabled credential cell and conditional tenancy/sandbox behavior.
* Tasks 6–10 cover tools, tasks, workers, supervisor/team, and metadata (19–29).
* Tasks 11–12 cover SQL interaction, verification, and history (30–37).
* Task 13 covers the explicit PL/SQL conversation and repeat verification/history (38–46).
* Expected results derive from the supplied seed data, not a new database execution. The lab explains that the repeated hotel change preserves the SQL example's final selection.
* The confirmation requirement is an agent instruction; the PL/SQL function has no confirmation argument. Inventory is fixed sample data, without date-based allocation.

## Validation

LiveLabs formatting checks pass for the source file and separately expanded tenancy and sandbox variants. Each variant has tasks 1–13. All 34 executable notebook paragraphs are preserved; all local image and notebook links resolve; copy and conditional tags balance.

Manual prose review: 4/5, preserving the requested Sales Return pacing. The bundled mechanical Lanham score is 1/5 because it scans SQL, prompts, markup, and technical nouns along with prose; its broad warnings are not treated as a learner-prose score. No live database execution or browser rendering was performed. Model availability and OCI environment access require validation in the target workshop environment.
