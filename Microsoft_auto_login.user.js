// ==UserScript==
// @name         Microsoft auto login
// @namespace    https://recolic.net/
// @version      0.10.2
// @description  Login MS account by simulating user interaction. Works for microsoft CORP account, works perfectly with automatic 2-step phone auth.
// @author       Recolic Keghart <root@recolic.net>
// @license      MIT
// @copyright    2024, recolic (https://openuserjs.org/users/recolic)
// @match        https://login.microsoftonline.com/*
// @match        https://msft.sts.microsoft.com/adfs/*
// @grant        GM.xmlHttpRequest
// @run-at       document-idle
// @updateURL https://openuserjs.org/meta/recolic/Microsoft_auto_login.meta.js
// ==/UserScript==

(function() {
'use strict';


var MY_EMAIL = 'YOUR_ALIAS@microsoft.com';
var MY_PASSWORD = 'YOUR_PASSWORD';

var MS_MODE = 202403;

// Only for Mode 202307. Download voice-to-text result through this API.
var PHONE_RECOG_API = 'https://XXX.net/api/logs/telnyx-text.php';

// Only for Mode 202403. Send msauth notification information through this API.
var MSAUTH_APP_API = 'http://msauth.XXX.xbs:30410/';

// Mode 2022  : Answer the phone, and type your PIN plus # key. It's still being used by some old MSFT page.
// Mode 202307: Answer the phone, press # key, listen for verification code, put verification code into file, and download through PHONE_RECOG_API.
// Mode 202308: Answer the phone, press # key, done.
// Mode 202311: Answer the phone, press # key, done.
//              have different web frontend compared with 202308
// Mode 202403: Need to type a 2-digits number on Microsoft Authenticator app notification, done.
//
// How to deploy phone backend for 2022,202307,202308,202311: https://git.recolic.net/-/snippets/27
// How to deploy msauth_app backend for 202403: https://git.recolic.net/-/snippets/28



////////////////////////////////////////////

function is_pick_an_account_page () {
    try {
        var cn = document.getElementById('loginHeader').childNodes;
        for(var i=0;i<cn.length;++i) {
            if(cn[i].innerHTML == "Pick an account")
                return true;
        }
        return false;
    } catch {
        return false;
    }
}
function do_pick_an_account_page () {
    var col = document.getElementsByClassName("table");
    var found = false;
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-test-id') == MY_EMAIL) {
            col[i].click(); // goto next page
            found = true;
            break;
        }
    }
    if(!found) {
        // click use other account
        console.log('Account not found. click use another account...');
        for(var i=0; i<col.length; ++i) {
            if(col[i].getAttribute('aria-labelledby') == 'otherTileText') {
                col[i].click(); // goto next page
                break;
            }
        }
    }
}

function is_signin_email_page () {
    try {
        return document.getElementsByName('loginfmt').length == 1 && document.getElementsByName('loginfmt')[0].getAttribute('type') != 'hidden';
    } catch {
        return false;
    }
}
function do_signin_email_page () {
    if (document.getElementById('loginHeader') != null && document.getElementById('loginHeader').innerHTML.includes('Enter password')) {
        // 202406 update: password input moved here
        document.getElementById('i0118').value = MY_PASSWORD;
        document.getElementById('i0118').dispatchEvent(new Event("change"))
        document.getElementById('idSIButton9').click();
        return;
    }
    document.getElementsByName('loginfmt')[0].value = MY_EMAIL;
    document.getElementsByName('loginfmt')[0].dispatchEvent(new Event("change"));
    document.getElementById('idSIButton9').click();
}

function is_signin_email_page_2 () {
    try {
        if (document.getElementById('loginMessage').innerHTML != 'Sign in')
            return false;
        return document.getElementById('usernamePage').style['display'] == 'block';
    } catch {
        return false;
    }
}
function do_signin_email_page_2 () {
    document.getElementById('userNameInput').value = MY_EMAIL;
    document.getElementById('userNameInput').dispatchEvent(new Event("change"));
    document.getElementById('nextButton').click();
}

function is_request_variants_page () {
    try {
        return false ||
            document.getElementById('idDiv_RemoteNGC_PageDescription').innerHTML.includes('We sent a sign in request to your Microsoft Authenticator app') || 
            document.getElementById('idDiv_RemoteNGC_PageDescription').innerHTML.includes("We couldn't send a notification to your phone at this time.") ||
            document.getElementById('idDiv_RemoteNGC_PageDescription').innerHTML.includes("We'll send a sign-in request to your phone to sign in") ||
            document.getElementById('idDiv_RemoteNGC_PageDescription').innerHTML.includes("Open your Authenticator app, and enter the number shown to sign in.");
    } catch {}
    try {
        return document.getElementById('idDiv_RemoteNGC_PollingDescription').innerHTML.includes("Open your Authenticator app, and enter the number shown to sign in.");
    } catch {
        return false;
    }
}
function do_request_variants_page () {
    document.getElementById('idA_PWD_SwitchToCredPicker').click();
}

function is_pre_request_page () {
    try {
        var col = document.getElementsByClassName('text-block-body');
        for(var i=0;i<col.length;++i) {
            if(col[i].outerText.includes("We'll send a sign-in request to your phone to sign in"))
                return true;
            if(col[i].outerText.includes("Your organizational policy requires you to sign in again after a certain time period."))
                return true;
        }
        return false;
    } catch {
        return false;
    }
}
function do_pre_request_page () {
    return do_request_variants_page();
}

function is_choose_a_way_page () {
    try {
        return document.getElementById('loginHeader').innerHTML == "Choose a way to sign in";
    } catch {
        return false;
    }
}
function do_choose_a_way_page () {
    var col = document.getElementsByClassName("table");
    var found = false;
    for(var i=0; i<col.length; ++i) {
        if(col[i].innerHTML.includes("Use my password")) {
            col[i].click(); // goto next page
            found = true;
            break;
        }
    }
    if(!found) {
        // click use other account
        console.log('Error: Use my password element not found. DOing nothing');
    }
}

function is_sts_auth_options_page () {
    try {
        return document.getElementById('primaryOptionsPage').style['display'] == "block";
    } catch {
        return false;
    }
}
function do_sts_auth_options_page () {
    try {
        document.getElementById('WindowsAzureMultiFactorAuthentication').click();
    } catch {
        console.log('You should not reach here. The next codeline will be removed because it should be useless. ');
        document.getElementById('FormsAuthentication').click();
    }
}

function is_sts_pswd_input_page () {
    try {
        return document.getElementById('passwordPage').style['display'] == "block";
    } catch {
        return false;
    }   
}
function do_sts_pswd_input_page () {
    document.getElementById('passwordInput').value = MY_PASSWORD;
    document.getElementById('submitButton').click();
}

function is_sts_2fa_page () {
    try {
        return document.getElementById('mfaGreeting').classList.contains('hidden') && document.getElementById('mfaGreetingDescription').innerHTML == "For security reasons, we require additional information to verify your account";
    } catch {
        return false;
    }
}
function do_sts_2fa_page () {
    console.log("do_sts_2fa_page: Assuming you are using automated phone auth. (Setup a twilio account to automatically answer the phone and type PIN). This is the only possible & easy automated login way! ")
    document.getElementById('WindowsAzureMultiFactorAuthentication').click();
}

function is_202308_2fa_select_page () {
    if(MS_MODE != 202308) return false;
    var col = document.getElementsByClassName("table");
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-value') == "TwoWayVoiceMobile") {
            return true;
        }   
    }
    return false;
}
function do_202308_2fa_select_page () {
    var col = document.getElementsByClassName("table");
    var found = false;
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-value') == "TwoWayVoiceMobile") {
            // first phone call. click it.
            col[i].click();
            found = true;
            break;
        }   
    }
    if(!found) {
        console.log('Error: new 2fa, table element with TwoWayVoiceMobile not found. DOing nothing');
    }
}

function is_202308_2fa_verify_page () {
    if(MS_MODE != 202308) return false;
    var ele = document.getElementById('idDiv_SAOTCC_Description');
    if (ele == null) return false;
    return ele.innerHTML.includes('re calling your phone');
}
function do_202308_2fa_verify_page () {
    var eleerr = document.getElementById("idSpan_SAOTCC_Error_OTC");
    if(eleerr != null && eleerr.innerText.includes("We called your phone but didn't receive the expected response")) {
        document.getElementById("signInAnotherWay").click();
    }
}

function is_202311_2fa_select_page () {
    if(MS_MODE != 202311) return false;
    var col = document.getElementsByClassName("table");
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-value') == "TwoWayVoiceMobile") {
            return true;
        }   
    }
    return false;
}
function do_202311_2fa_select_page () {
    var col = document.getElementsByClassName("table");
    var found = false;
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-value') == "TwoWayVoiceMobile") {
            // first phone call. click it.
            col[i].click();
            found = true;
            break;
        }   
    }
    if(!found) {
        console.log('Error: new 2fa, table element with TwoWayVoiceMobile not found. DOing nothing');
    }
}

function is_202307_2fa_select_page () {
    if(MS_MODE != 202307) return false;
    var col = document.getElementsByClassName("table");
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-value') == "OneWayVoiceMobileOTP") {
            return true;
        }   
    }
    return false;
}
function do_202307_2fa_select_page () {
    var col = document.getElementsByClassName("table");
    var found = false;
    for(var i=0; i<col.length; ++i) {
        if(col[i].getAttribute('data-value') == "OneWayVoiceMobileOTP") {
            // first phone call. click it.
            col[i].click();
            found = true;
            break;
        }   
    }
    if(!found) {
        console.log('Error: new 2fa, table element with OneWayVoiceMobileOTP not found. DOing nothing');
    }
}

function is_202307_2fa_verify_page () {
    if(MS_MODE != 202307) return false;
    var ele = document.getElementById('idDiv_SAOTCC_Description');
    if (ele == null) return false;
    return ele.innerHTML.includes('re calling your phone');
}
var txt_prev_elecount="";
function do_202307_2fa_verify_page () {
    var elecount = document.getElementById('idDiv_SAOTCC_Title');
    if (elecount.innerText == "Enter code") {
        elecount.innerText = "3";
        return;
    }
    if (elecount.innerText == "3") {
        elecount.innerText = "2";
        return;
    }
    if (elecount.innerText == "2") {
        elecount.innerText = "1";
        return;
    }
    if (elecount.innerText == "1") {
        elecount.innerText = "fetching API result";
        return;
    }

    var eleerr = document.getElementById("idSpan_SAOTCC_Error_OTC");
    if(eleerr != null && eleerr.innerText.includes("You didn't enter the expected verification code.")) {
        // 6 digits code is incorrect.
        if (txt_prev_elecount == elecount.innerText) {
            // give up
            document.getElementById("signInAnotherWay").click();
        }
        else {
            // Maybe transcript is incomplete yet. Wait for another round and see if elecount still change.
            txt_prev_elecount = elecount.innerText;
        }
    }

    // First 3 calls, don't do anything. wait for the phone call to complete.
    // From the 4th call, fetch the result.
    GM.xmlHttpRequest({
      method: "GET",
      url: PHONE_RECOG_API,
      onload: function(response) {
          var elecount = document.getElementById('idDiv_SAOTCC_Title');
          var apitext = (response.responseText);
          elecount.innerText = apitext;

          var apitext_cleaned = apitext.replace(/one/ig, '1').replace(/two/ig, '2').replace(/three/ig, '3').replace(/four/ig, '4').replace(/five/ig, '5').replace(/six/ig, '6').replace(/seven/ig, '7').replace(/eight/ig, '8').replace(/nine/ig, '9').replace(/zero/ig, '0').replace(/to/ig, '2').replace(/for/ig, '4').replace(/sex/ig, '6');

          var elein = document.getElementById('idTxtBx_SAOTCC_OTC');
          var digits_in_resp_text = apitext_cleaned.match(/\d/g).join("");
          var last_6digits = digits_in_resp_text.substr(-6);

          var first_or_last = Math.floor(Math.random() * 2) /* 0 or 1 */ == 0;
          if (first_or_last) {
              last_6digits = digits_in_resp_text.substr(6); // first 6 digits
          }

          if (last_6digits.length == 6) {
            // click next
            elein.value = last_6digits;
            elein.dispatchEvent(new Event("change"));
            document.getElementById('idSubmit_SAOTCC_Continue').click();
          }
      }
    });
}

function is_stay_signed_in_page () {
     try {
        var col = document.getElementsByClassName('text-title');
        for(var i=0;i<col.length;++i) {
            if(col[i].innerText.includes("Stay signed in?"))
                return true;
        }
        return false;
    } catch {
        return false;
    }
}
function do_stay_signed_in_page () {
    document.getElementById('idSIButton9').click();
}

function is_202311_protect_account_page () {
    if(MS_MODE != 202311) return false;
    var ele = document.getElementById('heading');
    if (ele == null) return false;
    return ele.innerText == "Protect your account";
}
function do_202311_protect_account_page () {
    document.getElementById('skipMfaRegistrationLink').click();
}

function is_202403_notification_sent_page () {
    var ele = document.getElementById('idDiv_SAOTCAS_Title');
    if (ele == null) return false;
    return ele.innerHTML.includes("Approve sign in request");
}
function do_202403_notification_sent_page () {
    var ele = document.getElementById('idRichContext_DisplaySign');
    var digits = ele.innerText;
    document.getElementById('idDiv_SAOTCAS_Title').innerHTML = "Waiting API"; // Block further detection
    GM.xmlHttpRequest({
      method: "GET",
      url: MSAUTH_APP_API + digits,
      onload: function(response) {
          var eleout = document.getElementById('idDiv_SAOTCAS_Description');
          var apitext = (response.responseText);
          if (eleout != null) eleout.innerText = apitext;
      }
    });
}
function is_202403_auth_fail_page () {
    var ele = document.getElementById('idDiv_SAASTO_Title');
    if (ele == null) return false;
    return ele.innerHTML.includes("We didn't hear from you");
}
function do_202403_auth_fail_page () {
    document.getElementById('idA_SAASTO_Resend').click();
}

////////////////////////////////////////////

function main () {
/* Auto generated code. Do not modify by hand. 
 *
 ************ RUN this script to generate: 

jsfile=Microsoft_auto_login.user.js
echo '
ZWNobyAnaWYoZmFsc2UpOycKZ3JlcCAnXmZ1bmN0aW9uIGlzXycgIiRqc2ZpbGUiIHwgc2VkICdz
L14uKmZ1bmN0aW9uIGlzXy8vZycgfCBzZWQgJ3MvIC4qJC8vZycgfCB3aGlsZSBJRlM9IiIgcmVh
ZCAtciBsaW5lOyBkbwogICAgZWNobyAiZWxzZSBpZihpc18kbGluZSgpKSB7Y29uc29sZS5sb2co
J2lzXyRsaW5lJyk7IGRvXyRsaW5lKCk7fSIKZG9uZQoK
' | base64 -d | source /dev/stdin

 ************ Auto generated code BEGIN **************/
if(false);
else if(is_pick_an_account_page()) {console.log('is_pick_an_account_page'); do_pick_an_account_page();}
else if(is_signin_email_page()) {console.log('is_signin_email_page'); do_signin_email_page();}
else if(is_signin_email_page_2()) {console.log('is_signin_email_page_2'); do_signin_email_page_2();}
else if(is_request_variants_page()) {console.log('is_request_variants_page'); do_request_variants_page();}
else if(is_pre_request_page()) {console.log('is_pre_request_page'); do_pre_request_page();}
else if(is_choose_a_way_page()) {console.log('is_choose_a_way_page'); do_choose_a_way_page();}
else if(is_sts_auth_options_page()) {console.log('is_sts_auth_options_page'); do_sts_auth_options_page();}
else if(is_sts_pswd_input_page()) {console.log('is_sts_pswd_input_page'); do_sts_pswd_input_page();}
else if(is_sts_2fa_page()) {console.log('is_sts_2fa_page'); do_sts_2fa_page();}
else if(is_202308_2fa_select_page()) {console.log('is_202308_2fa_select_page'); do_202308_2fa_select_page();}
else if(is_202308_2fa_verify_page()) {console.log('is_202308_2fa_verify_page'); do_202308_2fa_verify_page();}
else if(is_202311_2fa_select_page()) {console.log('is_202311_2fa_select_page'); do_202311_2fa_select_page();}
else if(is_202307_2fa_select_page()) {console.log('is_202307_2fa_select_page'); do_202307_2fa_select_page();}
else if(is_202307_2fa_verify_page()) {console.log('is_202307_2fa_verify_page'); do_202307_2fa_verify_page();}
else if(is_stay_signed_in_page()) {console.log('is_stay_signed_in_page'); do_stay_signed_in_page();}
else if(is_202311_protect_account_page()) {console.log('is_202311_protect_account_page'); do_202311_protect_account_page();}
else if(is_202403_notification_sent_page()) {console.log('is_202403_notification_sent_page'); do_202403_notification_sent_page();}
else if(is_202403_auth_fail_page()) {console.log('is_202403_auth_fail_page'); do_202403_auth_fail_page();}
/************ Auto generated code END ****************/

    else {
        console.log("Unknown page. Doing nothing...");
    }
    setTimeout(main, 4000);
}
setTimeout(main, 4000);


})();



