function pdf-compress-imgonly
set fname $argv[1]
rm -f /tmp/tmp.pdf
gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -q -o /tmp/tmp.pdf $fname
mv /tmp/tmp.pdf $fname
end
