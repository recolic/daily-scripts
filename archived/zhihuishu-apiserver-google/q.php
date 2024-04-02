<?php

// Usage: set tiku api to this php, and set timeout to 16s. (16000)

if ($_SERVER["REQUEST_METHOD"] == "POST")
{
	$q = $_POST["question"];

    exec("timeout 15s ./do.sh '$q' 2>errlog", $cstdout);
    // print_r($cstdout);
    if(empty($cstdout)) {
        echo '{"code":1,"data":"NO_ANSWER","msg":""}';
    }
    else {
        foreach($cstdout as &$outLine) {
            echo '{"code":1,"data":"' . $outLine . '","msg":"FROM REALTIME GOOGLE"}';
            break; // only return first line. naive script
        }
    }
    // echo '{"code":1,"data":"正确","msg":""}';
}
else {
    echo '{"code":-1,"data":"POST ONLY","msg":"POST ONLY"}';
}
?>
