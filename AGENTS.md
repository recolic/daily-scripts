# Notes for AI agents (read this first)

> "HUMAN-APPROVAL" means, giving a "choice" and tell user to select; for AI agent without this capability, ask explicit approval over text.

Git: default branch is master.
Secrets: User has a secret manager. `rsec` lists all secret names (allowed without approval); `rsec SECRET_NAME` fetches a secret's value (only allowed in script/program).
Shell: User has fish, not bash.
Testing: 
  - ANY non-readonly command requires HUMAN-APPROVAL, especially those requiring sudo.
  - rsandbox [cmd ...] ; rsandbox sudo [cmd ...] are allowed without any approval. Read /usr/mybin/rsandbox for port forwarding or additional info.
Code Generation:
  - Before major design decision, ask HUMAN-APPROVAL. Minor design decision or disposible test code don't need approval. Your code should match existing coding style, or minimal if no context.
  - DO NOT break code into multiple-line, unless longer than 256 char.
  - When creating new file, start with comment `created by <model name>` (copilot IS NOT model name)

For Azure work-related task:
  - user personal note at ~/code/msdoc
  - Kusto: Prefer az-run-kql.sh because it returns csv
  - Kusto: To describe a Kusto table, use `table | take 1`. Always include cluster+db in your kql.
  - Kusto is expensive and slow. Best practice is to use several well-thought query to pull data, then local tools (such as python or binutils) for data process.

## CURSOR instruction (copilot please ignore)

SSH and GIT: set `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"` before ssh.
If the key is locked, gpg-agent will ask for a PIN; the agent terminal has **no TTY**, so pinentry cannot show. User must push from their own terminal when the key is locked.

## VScode (github copilot) only instruction

When using the browser, if hitting robot check, you can call human to help by giving a "choice" and tell user to select "passed or failed". Google wont work, use bing.

