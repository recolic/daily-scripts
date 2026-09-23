function code2
    set -l workdir ~/tmp/.vscode2
    mkdir -p $workdir; and code --user-data-dir $workdir/user-data --extensions-dir $workdir/extensions --new-window $argv
end
