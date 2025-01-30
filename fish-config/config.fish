if test -d /usr/mymsbin
    set -gx PATH /usr/mymsbin $PATH
end
if test -d /usr/mybin
    set -gx PATH /usr/mybin $PATH
end
if test -d /opt/rocm/bin
    set -gx PATH $PATH /opt/rocm/bin
end
set -gx EDITOR vim

# Microsoft PAT and git-credentials
if test $hostname = RECOLICMPC ; or test $hostname = RECOLICPC
    # Must use --no-config to avoid infinite loop
    set -gx pat (env DONT_REGEN_EXPIRED_TOKEN=1 fish --no-config /usr/mymsbin/patnew.fish)
    and begin
        set -gx devops_header "Authorization: Basic "(printf ":%s" "$pat" | base64 -w0)
        echo "https://bensl:$pat@msazure.visualstudio.com" > ~/.git-credentials
        # Deprecated MS_GITHUB# https://bensl_microsoft:$R_SEC_GITHUB_EMU_TOKEN@github.com
    end
end

# RECOLICPC
set -gx PYTORCH_ROCM_ARCH gfx1032
set -gx HSA_OVERRIDE_GFX_VERSION 10.3.0

# Bug fix: scripts/init-dev-env.sh: Couldn't find a valid ICU package installed on the system
set -x DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1

# Bug fix: valgrind debuginfod error
set -x DEBUGINFOD_URLS "https://debuginfod.archlinux.org"
set -x G_SLICE always-malloc

set -x GOPATH /home/recolic/go
set -gx PATH $GOPATH/bin $PATH
type thefuck > /dev/null 2>&1 ; and thefuck --alias shit | source

set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)

# fundle plugin 'tuvistavie/fish-ssh-agent'
# if status --is-login
# 	set PATH $PATH /usr/bin /sbin
# end
# source /usr/share/autojump/autojump.fish
# eval (python -m virtualfish)
# # nix
# if test -d $HOME/.nix-profile; and test -d /nix
#    source ~/.config/fish/nix.fish
# end
#set -x WINEDEBUG '-all'

