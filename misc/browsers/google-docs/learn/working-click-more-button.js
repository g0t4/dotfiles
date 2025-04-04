// find the button's target, i.e. moreButton
//   can use breakpoint (see breakpoint js file)... and then click button and it will show you that way too (conditional on eventType mousedown)
//const moreTarget = document.querySelector(
//   // moreButton alone works
//   //    "#moreButton > div > div > div > div > div > div"
//   "#moreButton"
//);
//
//// *** use Keyboard Maestro run javascript action in a macro and this will work!
//
//// I found that it uses mousedown in a global handler by sending all possible types and finding what works!
////    FYI this will also trigger a breakpoint on UCe/VCe obfuscated funcs
//const mouseEvents = [
//    "mousedown", // "mouseup", // "click", // "dblclick",
//    //  "mouseover", "mouseenter", "mouseout", "mouseleave", "mousemove"
//];
//
//mouseEvents.forEach((type) => {
//    // simulate mouse events
//    const event = new MouseEvent(type, {
//        bubbles: true,
//        cancelable: true,
//        view: window,
//    });
//    moreTarget.dispatchEvent(event);
//    console.log(`Dispatched: ${type}`);
//});
//
//console.log("done");

function dispatchMouseEvents(targetSelector, mouseEvents) {
    const targets = document.querySelectorAll(targetSelector);
    if (!targets.length)
        throw Error("no target found for selector", { targetSelector });
    if (targets.length > 1)
        throw Error("too many targets found for selector", { targetSelector });

    const moreTarget = document.querySelector(targetSelector);

    mouseEvents.forEach((type) => {
        // simulate mouse events
        const event = new MouseEvent(type, {
            bubbles: true,
            cancelable: true,
            view: window,
        });
        moreTarget.dispatchEvent(event);
        console.log(`Dispatched: ${type}`);
    });
}
function dispatchMouseDownUpEvents(targetSelector) {
    const mouseEvents = ["mousedown", "mouseup"];
    return dispatchMouseEvents(targetSelector, mouseEvents);
}

dispatchMouseDownUpEvents("#moreButton");
