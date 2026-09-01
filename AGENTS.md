> AI Agent: you may suggest, but do not modify this file.

# Notes for AI agents (read this first)

> "HUMAN-APPROVAL" means, giving a "choice" and tell user to select; for AI agent without this capability, explicit user approval over text (future or past).

Git: User prefer branch name `master`.
Secrets: User has a secret manager. `rsec` lists all secret names; `rsec SECRET_NAME` fetches a secret's value. Use `rsec` in your script/program. If needed, You may run `rsec` without explicitly asking; Cursor will prompt for permission as needed.
Shell: User has fish, not bash.
Kusto task: To describe a Kusto table, do not run control cmd, use `table | take 1` instead. Always include cluster+db in your kql.
Testing: 
  - ANY non-readonly command requires HUMAN-APPROVAL, especially these with root access.
  - rsandbox is allowed without any approval. rsandbox [cmd ...] ; rsandbox sudo [cmd ...] are all allowed. Read /usr/mybin/rsandbox for port forwarding, nuke option or other details.
Code Generation:
  - Before major design decision, ask HUMAN-APPROVAL. Minor design decision or disposible test code don't need approval. Your code should match existing coding style, or minimal if no context.
  - DO NOT break code into multiple-line, unless longer than 256 char.


For microsoft azure work-related task: if you need something not found in knowledge base, you are allowed to read user personal note at ~/code/msdoc.

## CURSOR instruction (copilot please ignore)

SSH and GIT: set `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"` before any ssh auth.
If the key is locked, gpg-agent will ask for a PIN; the agent terminal has **no TTY**, so pinentry cannot show. User must push from their own terminal when the key is locked.

## VScode (github copilot) only instruction

When using the browser, if hitting robot check, you can call human to help by giving a "choice" and tell user to select "passed or failed". Google wont work, use bing.

