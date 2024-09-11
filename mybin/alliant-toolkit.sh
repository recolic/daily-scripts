#!/bin/bash

function csv2html () {
    #!/bin/bash
    # Script to convert a *simple* CSV file into an HTML table
    # Will fail if field data contains comma or newlines
    #
    # USAGE: bash csv2html.sh CSV_FN [BORDER_WIDTH] > OUTPUT_HTML_FN
    
    # usage (){
    #     echo "USAGE: $0 CSV_FN [BORDER_WIDTH] > OUTPUT_HTML_FN"
    #     echo "Examples:"
    #     echo "$0 /tmp/input.csv > /tmp/output.html"
    #     echo "$0 /tmp/input.csv 1 > /tmp/output.html  # add a border"
    # }
    
    [[ $# -lt 1 ]] && usage && exit 1
    [[ $1 == "-h" ]] || [[ $1 == "--help" ]] && usage && exit 1
    
    CSV_FN=$1
    if [[ $# -eq 2 ]]; then
        echo "<table border=\"$2\">"
    else
        echo '<table border="1" style="border-collapse: collapse;">'
    fi
    
    head -n 1 "$CSV_FN" | \
        sed -e 's/^/<tr><th>/' -e 's/,/<\/th><th>/g' -e 's/$/<\/th><\/tr>/'
    tail -n +2 "$CSV_FN" | \
        sed -e 's/^/<tr><td>/' -e 's/,/<\/td><td>/g' -e 's/$/<\/td><\/tr>/'
    echo "</table>"
}

function prev_month () {
    local database_="
feb:jan
mar:feb
apr:mar
may:apr
jun:may
jul:jun
aug:jul
sep:aug
oct:sep
nov:oct
dec:nov
jan:dec"
    echo "$database_" | grep -i "^$1:" | cut -d : -f 2 | tr 'a-z' 'A-Z' || return 1
}

function alliant_csv_filter () {
    #!/bin/bash
    what=$1
    l_fname="$2"
    
    [[ $1 = "" ]] || [[ $2 = "" ]] && echo "Usage: $0 <CN/other> <fname>" && exit 1
    
    if [[ $what = CN ]]; then
        cat "$l_fname" | grep '^Date' # title line
        cat "$l_fname" | grep -E 'CN"|(CN *|ALP.*)CREDIT"'
    elif [[ $what = other ]]; then
        cat "$l_fname" | grep -vE 'CN"|(CN *|ALP.*)CREDIT"' | grep -v PAYMENT-ONLINE
    else
        echo "Usage: $0 <CN/other> <fname>" && exit 1
    fi
}

function alliant_csv_calc () {
    #!/bin/bash
    [ ! -f "$1" ] && echo "Usage: $0 <alliant.csv>" && exit 1
    
    ## calc sum
    
    cat "$1" | sed 's/\$0.00/NUL/g' | # strip 0.00 fees
        sed -E 's/\(\$([0-9]*\.[0-9][0-9])\)/$-\1/g' | # replace ($1.11) to $-1.11
        grep -o '\$[0-9-]*\.[0-9][0-9]' | # grep all price tags
        tr -d '$' | # remove leading dollar sign
        tr '\n' '+' | # join strings
        sed 's/+$//' > /tmp/.altmp # remove tail plus sign
    
    expr_=`cat /tmp/.altmp`
    res=`python -c "print('%.2f' %  ($expr_)  )"`
    echo "$expr_ = $res"
    
    ## calc 2.5 discount
    
    expr_="$res * 0.975"
    res=`python -c "print('%.2f' %  ($expr_)  )"`
    echo "$expr_ = $res"
}

function alliant_oneclick () {
    fname="$1"
    month="$2"
    budget_cny="$3"
    type md2html || ! echo "md2html not available. DO pacman -S md4c" || exit 1
    [[ ! -f $fname ]] || [[ $month = "" ]] || [[ $budget_cny = "" ]] && echo "
Prog Usage:
1. Export Alliant 60d history as CSV file
2. Download Alliant statement
3. Delete all unrelated Tx from CSV file (DO NOT delete the title line)
4. Run this script like
     alliant_oneclick 1.csv JUN 7000
5. Send resulting HTML as email
" && exit 1

    ## start working
    alliant_csv_filter CN "$fname" > /tmp/.alliant-1.csv || return $?
    alliant_csv_filter other "$fname" > /tmp/.alliant-other.csv || return $?
    alliant_csv_calc /tmp/.alliant-1.csv > /tmp/.alliant-tx.txt || return $?
    csv2html /tmp/.alliant-1.csv > /tmp/.alliant-h2.html || return $?

    total_cost_usd=`cat /tmp/.alliant-tx.txt | tr -d ' ' | cut -d = -f 2 | head -n 1` || return 1
    disct_cost_usd=`cat /tmp/.alliant-tx.txt | tr -d ' ' | cut -d = -f 2 | tail -n 1` || return 1
    usd_cny_rate=`curl -s https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json | jq .usd.cny` || usd_cny_rate=7.1
    disct_cost_cny=`python -c "print('%i' % ($disct_cost_usd * $usd_cny_rate))"` || return 1
    final_bud_cny=`python -c "print($budget_cny - $disct_cost_cny)"` || return 1
    prev_month=`prev_month "$month"` || ! echo "invalid month" || return 1

    ## Prep output
    echo "
This is the statement for your Alliant VISA Credit Card.

**Please report any suspicious or unauthorized transaction immediately.**
" | md2html > /tmp/.alliant-h1.html

    echo "
(original document attached)

> $(cat /tmp/.alliant-tx.txt | head -n 1)

Your total spending (after applying special budget credit) in this billing $total_cost_usd USD.  
After applying 2.5% cashback, you need to pay $total_cost_usd * 0.975 = $disct_cost_usd USD.

$disct_cost_usd USD ($disct_cost_cny CNY) will be deduced from your $month budget.  
**Your $month budget is $final_bud_cny CNY** , which will be paid through cash.

Please be aware that this is an auto-generated email, and there may be unintentional errors.  
Thanks for using Recolic Payment Service.
" | md2html > /tmp/.alliant-h3.html

    echo '
<footer style="font-size: 12px; color: grey; text-align: center; line-height: 1.5; padding: 10px 0;">
  The information contained in this communication from the sender is confidential. It is intended solely for use by the recipient and others authorized to receive it. If you are not the recipient, you are hereby notified that any disclosure, copying, distribution or taking action in relation of the contents of this information is strictly prohibited and may be unlawful.<br />
  Please note that the emails you receive from us regarding your credit card statement are service notifications required by Alliant Credit Union Agreement and Credit Card Accountability Responsibility & Disclosure Act. These emails cannot be unsubscribed from, and they do not fall under spam protection laws related to marketing emails.<br />
  Digitally signed: Recolic Networking (root@recolic.net)
</footer>' > /tmp/.alliant-h4.html
    
    cat /tmp/.alliant-h1.html /tmp/.alliant-h2.html /tmp/.alliant-h3.html /tmp/.alliant-h4.html > /tmp/.alliant-all.html
    cp /tmp/.alliant-1.csv /tmp/river-statement-$prev_month.csv

    echo ">>>
EMAIL DONE! (Use Thunderbird -> Insert -> HTML)
  Title:  Your $prev_month Statement and $month Budget
  Content:    /tmp/.alliant-all.html
  Attachment: /tmp/river-statement-$prev_month.csv
>>>
Also check non-CNY cost: /tmp/.alliant-other.csv"
}

"$@"

