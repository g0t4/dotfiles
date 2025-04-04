
// this is the code that handles click events (or at least logs them)...
//   this is how I discovered it might be mousedown (hadn't crossed my mind that it wasn't just click!)
//   set a conditional breakpoint (i.e. eventType == "mousedown")
//     => then click an item
//     => find the targetElement for generating clicks yourself
//   or just logging breakpoint that logs all params
//     => logs all events (mouse move too, so its chatty)
//

UCe.prototype.handleEvent = function(a, c, e) {
    var f = c.target
      , g = Date.now();
    VCe(this, {
        eventType: a,
        event: c,
        targetElement: f,
        eic: e,
        timeStamp: g,
        eia: void 0,
        eirp: void 0,
        eiack: void 0
    })
}
;
function VCe(a, c) {
    if (a.Lp)
        a.Lp(c);
    else {
        c.eirp = !0;
        var e;
        (e = a.D) == null || e.push(c)
    }
}
