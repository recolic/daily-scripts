# Note for AI Agents

> To get HUMAN-APPROVAL: use `ask_user` tool; for AI agent without this tool, ask explicit approval over text.

Secrets: Use `rsec` for all secret management.
Shell: User has fish, not bash.
Code Generation:
  - DO NOT break code into multiple-line, unless longer than 256 char.
  - When creating new file, start with comment `created by <model name>` (copilot IS NOT model name)

Approval (match first rule):
  Design:
    - (is major decision) and (affected file count > 3) and (is not test): need HUMAN-APPROVAL
    - others: ALLOWED
  Run command:
    - rsandbox [cmd ...] ; rsandbox sudo [cmd ...] ; rsec : ALLOWED
    - rsec SECRET_NAME: NOT ALLOWED
    - rsec SECRET_NAME in script without printing secret out: ALLOWED
    - (is not readonly) or (sudo): need HUMAN-APPROVAL
  Modify code:
    - inside current dir: ALLOWED
  Everything else:
    - Use common sense. Only ask HUMAN-APPROVAL when necessary.
  

For Azure work-related task:
  - user personal note at ~/code/msdoc
  - Kusto: Prefer az-run-kql.sh which returns csv
  - Kusto: To describe a Kusto table, use `table | take 1`. Always include cluster+db in your kql.
  - Kusto is expensive and slow. Best practice is to use several well-thought query to pull data, then local tools for data process.

## for VScode (github copilot)

`browser` tool: if hitting robot check, use `ask_user`. Google wont work, use bing.

