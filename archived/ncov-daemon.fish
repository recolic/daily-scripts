#!/usr/bin/fish

while true
    set fname $HOME/tmp/hust-ncov-mark-(env TZ=Asia/Shanghai date +%j)
    set fails 0
    if not test -f $fname
        echo 'CALL HUST-NCOV'
        timeout 3m /usr/mybin/hust_ncov_submit        
        and begin
            echo 1 > $fname
            echo 'SUCCESS'
            set fails 0
        end; or begin
            set fails (math 1+$fails)
            echo "fails=$fails"
            test $fails -ge 10
                and /usr/mybin/recolic_email_notify root@recolic.net "RECOLIC NCOV NOTIFY" "hust-ncov daily auto submit has been failing for $fails times. Please fix the script!"
        end
    end
    sleep 300
end

