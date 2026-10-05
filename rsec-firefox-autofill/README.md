<!-- created by GitHub Copilot (model name unavailable) -->
# BUILD

```bash
## with fresh Ubuntu 24.04
## after git clone with correct branch, from repository root...
sudo apt update
sudo apt install -y git zip nodejs npm
cd rsec-firefox-autofill

# build: no compilation or dependencies needed
zip -j -q rsec-firefox-unsigned.xpi manifest.json background.js
echo "Build completed. XPI available at rsec-firefox-unsigned.xpi (use firefox-developer-edition + xpinstall.signatures.required=false in about:config)"

# optional: prod-signed, unlisted (requires Mozilla API credentials and review)
export WEB_EXT_API_KEY=$(rsec MOZ_EXT_JWT_ISSUE)
export WEB_EXT_API_SECRET=$(rsec MOZ_EXT_JWL_SECRT)
npx --yes --package=node@22 --package=web-ext@10 web-ext sign --source-dir . --ignore-files README.md '*.xpi' 'web-ext-artifacts/**' --channel unlisted --artifacts-dir web-ext-artifacts
unset WEB_EXT_API_KEY WEB_EXT_API_SECRET
echo "Signed XPI, if signing succeeded, is available in web-ext-artifacts/"
```

# rsec Firefox Autofill

Right-click a password input and choose `rsec(example.com)`. The extension fetches `http://localhost:3094/genpasswd/example.com` and fills only that input. The API must return the password as plain text; whitespace is preserved. No submission, storage, username filling, or Firefox password-manager integration.

For temporary installation, open `about:debugging#/runtime/this-firefox`, click **Load Temporary Add-on**, and select `manifest.json`. This installation lasts until Firefox restarts. For permanent installation, install the unsigned XPI in Developer Edition with signature enforcement disabled, or install the signed XPI in ordinary Firefox. Signature enforcement cannot normally be disabled in release Firefox.

In `background.js`, `urlExceptions` maps URL substrings to API identifiers (first match wins), otherwise `specialDomains` overrides the default last-two-label hostname rule.

The menu also appears on other editable fields, but clicking it there does nothing and does not call the API. Firefox-protected pages cannot be filled. The clicked input must remain connected, writable, and a password input, and its document URL must not change while waiting. Errors during the request appear in an alert; injection errors appear in the extension console.

The service must already be running. Firefox may still offer to save the filled password; disable its password saving if unwanted. The website can read a filled password. Keep the localhost service protected against arbitrary website requests; this extension does not provide server-side authentication or access control.
