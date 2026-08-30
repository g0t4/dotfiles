# ~/.xonshrc
from xonsh.lib.lazyasd import LazyObject
import importlib

# FYI all xonsh startup files ~/.config/xonsh/rc.d/* share one namespace
#  thus you get the appearance of globals
#  this is unlike python where each module (file) has its own namespace

# * lazy loaded auto-imports
# FYI if any issues with these, just eager load them if they're small (i.e. rich is small enough)

rich = LazyObject(lambda: importlib.import_module("rich"), globals(), "rich")
inspect = LazyObject(lambda: rich.inspect, globals(), "inspect")
#   => `inspect(@)`

# * maybes
# httpx = LazyObject(lambda: importlib.import_module("httpx"), globals(), "httpx")
# np = LazyObject(lambda: importlib.import_module("numpy"), globals(), "np")
# plt = LazyObject(lambda: importlib.import_module("matplotlib.pyplot"), globals(), "plt")

# * startup modules use the following so there's no need to auto import (unless I no longer import them in other startup files):
# Path = LazyObject(lambda: importlib.import_module("pathlib").Path, globals(), "Path")
# re = LazyObject(lambda: importlib.import_module("re"), globals(), "re")
# subprocess = LazyObject(lambda: importlib.import_module("subprocess"), globals(), "subprocess")
# os = LazyObject(lambda: importlib.import_module("os"), globals(), "os")
# sys = LazyObject(lambda: importlib.import_module("sys"), globals(), "sys")
# json = LazyObject(lambda: importlib.import_module("json"), globals(), "json")


class DotableDict(dict):

    def __init__(self, dict):
        super().__init__(dict)
        self.__dict__ = self

    def __getattr__(self, name):
        try:
            return self[name]
        except KeyError:
            raise AttributeError(name)

    def __setattr__(self, name, value):
        self[name] = value

    def __delattr__(self, name):
        try:
            del self[name]
        except KeyError:
            raise AttributeError(name)


def dotable(obj):
    """
    ensure obj is dotable (dot-able)
    and by dottable I mean: `foo.bar`
    instead of annoying syntax like dict: `foo["bar"]`
    """
    if isinstance(obj, dict):
        return DotableDict(obj)
    # TODO other types that are inherently a PITA?
    return obj

