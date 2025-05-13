function get_ele_by_class_and_inner (className, innerText) {
    var ar = document.getElementsByClassName(className);
    for(var i=0; i<ar.length; ++i) {
        if(ar[i].innerHTML.includes(innerText)) {
            return ar[i];
        }
    }
    return null;
}
