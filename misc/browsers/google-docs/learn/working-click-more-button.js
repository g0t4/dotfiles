console.clear();

// FYI there may be some buttons that don't work with mouse down/up
//   if so find new events
//   can use breakpoint (see breakpoint js file)... and then click button and it will show you that way too (conditional on eventType mousedown)
// *** use Keyboard Maestro run javascript action in a macro and this will work!

const moreTarget = document.querySelector("#moreButton");

// I found that it uses mousedown in a global handler by sending all possible types and finding what works!
//    FYI this will also trigger a breakpoint on UCe/VCe obfuscated funcs
const mouseEvents = [
    "mousedown", // "mouseup", // "click", // "dblclick",
    //  "mouseover", "mouseenter", "mouseout", "mouseleave", "mousemove"
    //
    //  "pointerdown", "pointerup",
    //    "pointermove", "pointerleave",
    //  "focusin", "focus", "focusout"
    //  "blur",
];

mouseEvents.forEach((type) => {
    const event = new MouseEvent(type, {
        bubbles: true,
        cancelable: true,
        view: window,
    });
    moreTarget.dispatchEvent(event);
    console.log(`Dispatched: ${type}`);
});

console.log("done");
