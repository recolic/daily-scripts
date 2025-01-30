function gitacp
set msg $argv[1]
git add -A ; and git commit -m ".$msg" ; git push
end
