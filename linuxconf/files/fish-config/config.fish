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

# RECOLICPC
set -gx PYTORCH_ROCM_ARCH gfx1032
set -gx HSA_OVERRIDE_GFX_VERSION 10.3.0

### Reset this flag while building different proj
# Bug fix: GFT: en-US is an invalid culture identifier
set -x DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 0
# Bug fix: VFP: Couldn't find a valid ICU package installed on the system
# set -x DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1

# Bug fix: valgrind debuginfod error
set -x DEBUGINFOD_URLS "https://debuginfod.archlinux.org"
set -x G_SLICE always-malloc

set -x GOPATH /home/recolic/go
set -gx PATH $GOPATH/bin $PATH
type thefuck > /dev/null 2>&1 ; and thefuck --alias shit | source

set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
set -gx NugetMachineInstallRoot /mnt/windows_pkgs

function fish_command_not_found
    # do nothing
    echo Command not found 1>&2
end

if fish --version | grep ' 4' > /dev/null
    bind ctrl-c cancel-commandline
end

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

