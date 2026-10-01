# Note for AI Agents

> To get HUMAN-APPROVAL: use `ask_user` tool; for AI agent without this tool, ask explicit approval over text.

Secrets: User has a secret manager. `rsec` lists all secret names (allowed without approval); `rsec SECRET_NAME` fetches a secret's value (only allowed in script/program).
Shell: User has fish, not bash.
Testing: 
  - ANY non-readonly command requires HUMAN-APPROVAL, especially those requiring sudo.
  - rsandbox [cmd ...] ; rsandbox sudo [cmd ...] are allowed without approval. Read /usr/mybin/rsandbox for port forwarding or additional info.
Code Generation:
  - Before major design decision, ask HUMAN-APPROVAL. Minor design decision or disposible test code don't need approval. Your code should match existing coding style, or minimal if no context.
  - DO NOT break code into multiple-line, unless longer than 256 char.
  - When creating new file, start with comment `created by <model name>` (copilot IS NOT model name)

For Azure work-related task:
  - user personal note at ~/code/msdoc
  - Kusto: Prefer az-run-kql.sh which returns csv
  - Kusto: To describe a Kusto table, use `table | take 1`. Always include cluster+db in your kql.
  - Kusto is expensive and slow. Best practice is to use several well-thought query to pull data, then local tools for data process.

## for VScode (github copilot)

`browser` tool: if hitting robot check, use `ask_user`. Google wont work, use bing.

