
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

// USAGE:
//   dispatchMouseDownUpEvents("#moreButton");

