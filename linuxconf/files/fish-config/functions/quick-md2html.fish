function quick-md2html
    set head '<html lang=en><meta charset=utf-8><meta content="width=device-width,initial-scale=1"name=viewport><link href=https://recolic.cc/res/github-markdown.css rel=stylesheet><style>.markdown-body{box-sizing:border-box;min-width:200px;max-width:980px;margin:0 auto;padding:45px}@media (max-width:767px){.markdown-body{padding:15px}}</style><article class=markdown-body>'
    set tail '</article></html>'
    echo $head
    echo '<!-- markdown.css can also fetch from https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown.css -->'
    md2html --ftables # from stdin to stdout, use archlinux:md4c
    echo $tail
end
