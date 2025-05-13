var res = 1;
for (const a of document.querySelectorAll("button")) {
  if (a.textContent.includes("View Full Report")) {
    let res = a;
  }
}


let ar = [...document.querySelectorAll("button")]
   .filter(a => a.textContent.includes("View Full Report"))
//    .forEach(a => console.log(a.textContent))

for (var i = 0; i < ar.length; ++i) {
  let btn = ar[i];
  btn.click();
  // TODO: sleep 3s
  document.getElementsByClassName("share-button-download")[0].click()
  // TODO: sleep 5s
  // no need to close it. Just go ahead.
}

var global_cter = 0;

function iterator(i) {
  console.log("Writting i=" + i);
  if (i % 2 == 0) {
    let index = i/2;
    let ar = [...document.querySelectorAll("button")].filter(a => a.textContent.includes("View Full Report"));
    ar[index].click();
  }
  else {
    document.getElementsByClassName("share-button-download")[0].click()
  }
}
const interval = setInterval(function() {
   iterator(global_cter);
   global_cter++;
}, 8000);
 
 
 clearInterval(interval);

