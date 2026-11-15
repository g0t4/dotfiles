"""Small public-AppKit bridge; preserves native traffic lights and window geometry."""

import ctypes
from functools import lru_cache

from PySide6.QtGui import QColor


@lru_cache(maxsize=1)
def runtime():
    lib = ctypes.CDLL("/usr/lib/libobjc.A.dylib")
    lib.objc_getClass.argtypes = [ctypes.c_char_p]
    lib.objc_getClass.restype = ctypes.c_void_p
    lib.sel_registerName.argtypes = [ctypes.c_char_p]
    lib.sel_registerName.restype = ctypes.c_void_p
    return lib


def send(receiver, selector, result=ctypes.c_void_p, types=(), values=()):
    lib = runtime()
    # Separate typed function pointers avoid mutating objc_msgSend's global ABI.
    function = ctypes.CFUNCTYPE(result, ctypes.c_void_p, ctypes.c_void_p, *types)(
        ("objc_msgSend", lib)
    )
    return function(receiver, lib.sel_registerName(selector.encode()), *values)


def native_window(widget):
    # QWidget.winId is the NSView on Qt's Cocoa platform.
    return send(int(widget.winId()), "window")


def color_titlebar(widget, background):
    window = native_window(widget)
    if not window:
        return
    lib = runtime()
    name = send(
        lib.objc_getClass(b"NSString"),
        "stringWithUTF8String:",
        types=(ctypes.c_char_p,),
        values=(b"NSAppearanceNameDarkAqua",),
    )
    appearance = send(
        lib.objc_getClass(b"NSAppearance"),
        "appearanceNamed:",
        values=(name,),
        types=(ctypes.c_void_p,),
    )
    color = QColor(background)
    native_color = send(
        lib.objc_getClass(b"NSColor"),
        "colorWithSRGBRed:green:blue:alpha:",
        types=(ctypes.c_double,) * 4,
        values=(color.redF(), color.greenF(), color.blueF(), 1.0),
    )
    send(
        window,
        "setAppearance:",
        result=None,
        types=(ctypes.c_void_p,),
        values=(appearance,),
    )
    send(
        window,
        "setBackgroundColor:",
        result=None,
        types=(ctypes.c_void_p,),
        values=(native_color,),
    )
    send(
        window,
        "setTitlebarAppearsTransparent:",
        result=None,
        types=(ctypes.c_bool,),
        values=(True,),
    )
