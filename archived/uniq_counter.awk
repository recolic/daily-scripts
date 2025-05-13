#!/bin/env awk


{
    if($1 == last) {
        ++cter;
    }
    else {
        print last, cter;
        cter = 1;
    }
    last = $1;
}

END {
    print last, cter
    print "done"
}
