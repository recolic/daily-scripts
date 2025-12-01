// ==UserScript==
// @name         Auto‑Close msftvpn-alt pages
// @match        https://*.msftvpn-alt.ras.microsoft.com/*
// @match        https://msftvpn-alt.ras.microsoft.com/*
// @grant        none
// ==/UserScript==

(function() {
    setTimeout(function() {
        window.close();
    }, 5000);
})();

