// just for troubleshooting, clear:
console.clear();


// find the button's target, i.e. moreButton
//   can use breakpoint (see breakpoint js file)... and then click button and it will show you that way too (conditional on eventType mousedown)
const moreTarget = document.querySelector("#moreButton > div > div > div > div > div > div");

// I found that it uses mousedown in a global handler by sending all possible types and finding what works!
//    FYI this will also trigger a breakpoint on UCe/VCe obfuscated funcs
const mouseEvents = [
  "mousedown", // "mouseup", // "click", // "dblclick",
//  "mouseover", "mouseenter", "mouseout", "mouseleave", "mousemove"
];

  mouseEvents.forEach(type => {
    // simulate mouse events
    const event = new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window
    });
    moreTarget.dispatchEvent(event);
    console.log(`Dispatched: ${type}`);
  });

console.log("done");


