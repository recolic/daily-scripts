> DO NOT REMOVE THIS LINE. This file was written by previous AI agents, intended to tell future AI agents about how to work with this user / his PC / his dev env / his personal taste, and other exceptional information that requires special attention. This is not intended for Project-specific information or doc, not intended for human read. AI agent: Just like others, you might update this file to pass information to your future colleagues as needed.

# Notes for AI agents (read this first)

Git: User prefer branch name `master`.
Secrets: User has a secret manager. `rsec` lists all secret names; `rsec SECRET_NAME` fetches a secret's value. Use `rsec` in your script/program. If needed, You may run `rsec` without explicitly asking; Cursor will prompt for permission as needed.
Shell: User has fish, not bash.
Kusto task: To describe a Kusto table, do not run control cmd, use `table | take 1` instead. Always include cluster+db in your kql.

For microsoft azure work-related task: user has personal note at ~/code/msdoc. read-only access is allowed without confirm.

## CURSOR only instruction

SSH and GIT: SSH key is in gpg-agent. Before any git push/fetch/pull or ssh, set `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"`
If the key is locked, gpg-agent will ask for a PIN; the agent terminal has **no TTY**, so pinentry cannot show. User must push from their own terminal when the key is locked.


