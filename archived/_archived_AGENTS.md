## CURSOR instruction (copilot please ignore)

SSH and GIT: set `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"` before ssh.
If the key is locked, gpg-agent will ask for a PIN; the agent terminal has **no TTY**, so pinentry cannot show. User must push from their own terminal when the key is locked.

