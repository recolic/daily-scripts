function code3
    set -l workdir ~/tmp/.vscode3
    mkdir -p $workdir; and code --user-data-dir $workdir/user-data --extensions-dir $workdir/extensions --new-window $argv
end
