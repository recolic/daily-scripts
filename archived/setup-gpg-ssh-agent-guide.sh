
# Keygrip of E3933636. Change this when you change new yubikey. 
echo 93AC57E30E88111EC71D9215A1B436AFE705C71C > ~/.gnupg/sshcontrol
gpg-connect-agent reloadagent /bye

# Done. Add this to your fish startup file. 
# set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)

