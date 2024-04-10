set -o errexit

rm -f /tmp/*.wtl || echo 1
brname=`git rev-parse --abbrev-ref HEAD`
git pull
cp linux/hdtests/HDTestAutomation_Overlake.wtl /tmp/
git checkout main
git pull
git checkout "$brname"
git merge main || echo 1
mv /tmp/HDTestAutomation_Overlake.wtl linux/hdtests/
git add -A
git commit -m merge_auto

