// DOL helper: run this script in 富人区, to keep refreshing until $150 job.

function getElementByText(txt) {
  for (const a of document.querySelectorAll("a")) {
    if (a.textContent.includes(txt)) {
      return a;
    }
  }
  return null;
}
function getElementByTextDiv(txt) {
  for (const a of document.querySelectorAll("div")) {
    if (a.textContent.includes(txt)) {
      return a;
    }
  }
  return null;
}

function click_if_exist(txt) {
  var s = getElementByText(txt);
  if (s != null) {
    s.click()
    return true
  }
  return false;
}
function deny_if_exist(divtxt) {
  if (getElementByTextDiv(divtxt) != null) {
    return click_if_exist("拒绝")
  }
}

var stop = true;

function iteration() {
  if (stop) return;
  if (click_if_exist("敲其中一间房子")) return;
  if (click_if_exist("去下一家")) return;
  if (click_if_exist("询求工作")) return;
  if (click_if_exist("回怼对方")) return;
  if (click_if_exist("(1) 回应")) return;
  if (click_if_exist("(1) 离开")) return;
  if ( (!getElementByText("切换到反抗行动")) && (! getElementByTextDiv("你听到身后"))  ) {
    if (click_if_exist("(1) 继续")) return;
  }
  if (click_if_exist("(2) 攻击欺凌者")) return;
  if (click_if_exist("(2) 推开")) return;
  if (click_if_exist("(1) 无视")) return;
  if (click_if_exist("(2) 无视")) return;
  if (deny_if_exist("让你和我一起喝茶")) return;
  if (deny_if_exist("帮我的胸减减负")) return;
  if (deny_if_exist("帮我们除4个小时的草")) return;
  if (deny_if_exist("我需要取回我阁楼里的一件传家宝")) return;
  if (deny_if_exist("如果我可以拍一些关于你的小穴的照片")) return;
  if (deny_if_exist("如果你填补缺失的客人的空缺")) return;
  if (deny_if_exist("召来三只猫")) return;
  if (deny_if_exist("反正它也盖不住其他衣物，你不妨就什么也不穿吧")) return;
  if (deny_if_exist("给我看点好东西，我不会让你吃亏的")) return;
  if (deny_if_exist("买你身上的内衣")) return;
}

function main () {
  iteration();
  setTimeout(main, 500);
}
setTimeout(main, 500);
