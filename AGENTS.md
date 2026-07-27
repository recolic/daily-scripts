> AI Agent: you may suggest, but do not modify this file.

# Notes for AI agents (read this first)

> "HUMAN-APPROVAL" means, for vscode github copilot, giving a "choice" and tell user to select; for others, explicit user approval over text (future or past).

Git: User prefer branch name `master`.
Secrets: User has a secret manager. `rsec` lists all secret names; `rsec SECRET_NAME` fetches a secret's value. Use `rsec` in your script/program. If needed, You may run `rsec` without explicitly asking; Cursor will prompt for permission as needed.
Shell: User has fish, not bash.
Kusto task: To describe a Kusto table, do not run control cmd, use `table | take 1` instead. Always include cluster+db in your kql.
Code/Shell: DO NOT break code into multiple-line, unless longer than 256 char.
Testing: DO NOT install extra software or run anything as root, unless explicitly approved by user with text (or vscode/copilot choice box).
Code Generation: Before major design decision, please ask HUMAN-APPROVAL. Minor design decision or disposible test code don't need approval. Your code should match existing coding style, or minimal if no context.

For microsoft azure work-related task: user has personal note at ~/code/msdoc. read-only access is allowed without confirm.

## CURSOR only instruction

SSH and GIT: set `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"` before any ssh auth.
If the key is locked, gpg-agent will ask for a PIN; the agent terminal has **no TTY**, so pinentry cannot show. User must push from their own terminal when the key is locked.

## VScode (github copilot) only instruction

When using the browser, if hitting robot check, you can call human to help by giving a "choice" and tell user to select "passed or failed". Google wont work, use bing.

