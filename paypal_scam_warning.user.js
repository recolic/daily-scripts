// ==UserScript==
// @name         Warning PayPal Conversion Rate Scam
// @namespace    https://recolic.net/
// @version      1.3
// @description  Generate scam warning if PayPal conversion rate text is found. Please clear Settings->Security->Blacklisted Pages before use.
// @author       Recolic Keghart <root@recolic.net>
// @license      MIT
// @copyright    2026, recolic (https://openuserjs.org/users/recolic)
// @match        https://www.paypal.com/*
// @grant        none
// ==/UserScript==


(function () {
    'use strict';

    function modifyButtonText() {
        const buttons = document.querySelectorAll('button');
        buttons.forEach(btn => {
            if (btn.innerText && btn.innerText.includes("Complete Purchase")) {
                btn.innerText = "WARNING! WARNING! DID YOU DISABLE CONVERSION??? Click here to pay";
                btn.style.color = 'red'; // makes it obvious
            }
        });
    }

    function checkPage() {
        const elements = document.querySelectorAll('span');
        for (const el of elements) {
            if (el.innerText && el.innerText.includes("PayPal's conversion rate:")) {
                if (!el.innerText.includes("Scam Warning")) {
                    el.innerText = "Scam Warning!!! Disable this before pay!! " + el.innerText;
                    el.style.color = 'red'; // makes it obvious
                }
                modifyButtonText();
                return;
            }
        }
    }

window.addEventListener('load', () => {
    checkPage();                 // run once after page fully loads
    setInterval(checkPage, 1000); // keep checking in background
});

})();

