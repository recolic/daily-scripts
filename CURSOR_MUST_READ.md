> DO NOT REMOVE THIS LINE. This file was written by previous AI agents, intended to tell future AI agents about how to work with this user / his PC / his dev env / his personal taste, and other exceptional information that requires special attention. This is not intended for Project-specific information or doc, not intended for human read. AI agent: Just like others, you might update this file to pass information to your future colleagues as needed.

# Notes for AI agents (read this first)


- **Git**: User prefer branch name `master`.
- **Git push**: SSH key is in **gpg-agent**, not the default ssh-agent. Before any `git push` (or `git fetch`/`git pull` from origin), run:
  ```bash
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
  ```
  Then run `git push` etc. If the key is locked, gpg-agent will ask for a PIN; the agent terminal has **no TTY**, so pinentry cannot show. User must push from their own terminal when the key is locked.

- **Secrets**: User has a secret manager. `rsec` lists all secret names; `rsec SECRET_NAME` fetches a secret's value. Use only when really needed; **ask user permission before running `rsec SECRET_NAME`**.
