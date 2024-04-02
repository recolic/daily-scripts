<?php
function show_page()
{
    echo('hostname last-update(utc) status');
    $handle = fopen("status", "r");
    if ($handle) {
        while (($line = fgets($handle)) !== false) {
            echo("<p>$line</p>");
        }
        fclose($handle);
    } else {
        die('open status file failed.');
    } 
}

if($_SERVER['REQUEST_METHOD'] == 'POST')
{
    $name = $_POST['name'];
    $token = $_POST['token'];
    if(preg_match("/\b[A-Za-z0-9_\.-]*\b/", $name) == 0)
    {
        echo('Invalid hostname.');
        http_response_code(403);
        exit(0);
    }
    if(preg_match("/\b[A-Za-z0-9]*\b/", $token) == 0)
    {
        echo('Invalid token format.');
        http_response_code(403);
        exit(0);
    }
    exec("./.keepalive.py $name $token | tee /tmp/alivesrv.log", $cstdout, $ret);
    if($ret != 0)
    {
        foreach($cstdout as $outLine)
            echo($outLine);
	http_response_code(403);
        die('write to db failed.');
    }
}
else
{
    show_page();
}
?>
