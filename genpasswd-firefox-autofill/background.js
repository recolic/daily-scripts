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

browser.menus.create({id: "genpasswd", title: "genpasswd", contexts: ["editable"]});
browser.menus.onShown.addListener(async info => {
  const url = new URL(info.frameUrl || info.pageUrl);
  await browser.menus.update("genpasswd", {title: `genpasswd(${domainFor(url)})`, visible: ["http:", "https:"].includes(url.protocol)});
  browser.menus.refresh();
});

browser.runtime.onMessage.addListener(async (message, sender) => {
  if (message.type !== "genpasswd" || !sender.tab) return;
  const request = {cache: "no-store", credentials: "omit", redirect: "error"};
  const optionsResponse = await fetch("https://recolic.net/p/domain_options.js", request);
  if (!optionsResponse.ok) throw new Error(`domain options HTTP ${optionsResponse.status}`);
  const options = new Function(`${await optionsResponse.text()}\nreturn domain_option_map;`)();
  const args = (options.get(message.domain) || "").trim().split(/\s+/).filter(Boolean);
  const path = [message.domain, ...args].map(encodeURIComponent).join("/");
  const response = await fetch(`http://localhost:3094/genpasswd/${path}`, request);
  if (!response.ok) throw new Error(`genpasswd HTTP ${response.status}`);
  const password = await response.text();
  if (!password) throw new Error("genpasswd returned an empty password");
  return password;
});

async function fillPassword(targetId, domain) {
  try {
    const input = browser.menus.getTargetElement(targetId);
    const writable = () => input instanceof HTMLInputElement && input.isConnected && !input.disabled && !input.readOnly;
    if (!writable()) return;
    const url = location.href;
    const password = await browser.runtime.sendMessage({type: "genpasswd", domain});
    if (!writable() || location.href !== url) return;
    Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set.call(input, password);
    input.dispatchEvent(new Event("input", {bubbles: true}));
    input.dispatchEvent(new Event("change", {bubbles: true}));
  } catch (error) { alert(`genpasswd: ${error.message}`); }
}

browser.menus.onClicked.addListener((info, tab) => {
  if (info.menuItemId !== "genpasswd") return;
  const domain = domainFor(new URL(info.frameUrl || info.pageUrl));
  const code = `(${fillPassword.toString()})(${JSON.stringify(info.targetElementId)}, ${JSON.stringify(domain)})`;
  browser.tabs.executeScript(tab.id, {frameId: info.frameId, code}).catch(error => console.error(`genpasswd: ${error.message}`));
});
