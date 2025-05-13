var w = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
w.Open("GET", WScript.Arguments(0), false);
w.Send();
b = new ActiveXObject("ADODB.Stream");
b.Type = 1;
b.Open();
b.Write(w.ResponseBody);
b.SaveToFile("o.bin");




cscript /nologo wget.js http://example.com
