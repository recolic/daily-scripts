// created by GitHub Copilot (model name unavailable)
const urlExceptions = [
  ["/drive.recolic.", "drive@recolic.net"],
  ["/git.recolic.", "git@recolic.net"],
  ["/mail.recolic.", "root@recolic.net"],
  ["recolic.net/blog", "blog@recolic.net"],
  ["recolic.net/qr", "shortlink@recolic.net"],
  ["recolic.net/s", "shortlink@recolic.net"],
  ["recolic.net/go", "shortlink@recolic.net"],
];
const specialDomains = {};
const domainFor = url => urlExceptions.find(([match]) => url.href.includes(match))?.[1] || specialDomains[url.hostname] || url.hostname.split(".").slice(-2).join(".");

browser.menus.create({id: "rsec", title: "rsec", contexts: ["editable"]});
browser.menus.onShown.addListener(async info => {
  const url = new URL(info.frameUrl || info.pageUrl);
  await browser.menus.update("rsec", {title: `rsec(${domainFor(url)})`, visible: ["http:", "https:"].includes(url.protocol)});
  browser.menus.refresh();
});

browser.runtime.onMessage.addListener((message, sender) => {
  if (message.type !== "rsec" || !sender.tab) return;
  return fetch(`http://localhost:3094/genpasswd/${encodeURIComponent(message.domain)}`, {cache: "no-store", credentials: "omit", redirect: "error"}).then(async response => {
    if (!response.ok) throw new Error(`rsec HTTP ${response.status}`);
    const password = await response.text();
    if (!password) throw new Error("rsec returned an empty password");
    return password;
  });
});

async function fillPassword(targetId, domain) {
  try {
    const input = browser.menus.getTargetElement(targetId);
    const writable = () => input instanceof HTMLInputElement && input.type === "password" && input.isConnected && !input.disabled && !input.readOnly;
    if (!writable()) return;
    const url = location.href;
    const password = await browser.runtime.sendMessage({type: "rsec", domain});
    if (!writable() || location.href !== url) return;
    Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set.call(input, password);
    input.dispatchEvent(new Event("input", {bubbles: true}));
    input.dispatchEvent(new Event("change", {bubbles: true}));
  } catch (error) { alert(`rsec: ${error.message}`); }
}

browser.menus.onClicked.addListener((info, tab) => {
  if (info.menuItemId !== "rsec") return;
  const domain = domainFor(new URL(info.frameUrl || info.pageUrl));
  const code = `(${fillPassword.toString()})(${JSON.stringify(info.targetElementId)}, ${JSON.stringify(domain)})`;
  browser.tabs.executeScript(tab.id, {frameId: info.frameId, code}).catch(error => console.error(`rsec: ${error.message}`));
});
