# Pack all dependency into one directory

rm -rf release
pip install -r req.txt --prefix release --ignore-installed
cp daemon.py release/

pkg_path=`cd release && find . -type d -name site-packages`
echo "#/bin/bash
PYTHONPATH=$pkg_path python3 daemon.py "'"$@"'"
" > release/entry.sh
chmod +x release/entry.sh

