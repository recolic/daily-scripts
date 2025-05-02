# Defined in - @ line 2
function gb2312-to-utf8
	for fl in $argv
        iconv -c -f "GB18030" -t "UTF-8//TRANSLIT" $fl -o $fl
    end
end
