import objc
from colorama import Fore, Back, Style
from Foundation import NSArray
from AppKit import NSWorkspace
# FYI import * makes app slower to start so just import what you need from apple APIs:
from ApplicationServices import AXUIElementCopyAttributeValues, AXUIElementCopyAttributeValue, \
    AXUIElementCopyAttributeNames, AXUIElementCreateApplication, kAXFocusedUIElementAttribute, \
    kAXErrorAPIDisabled, kAXErrorActionUnsupported, kAXErrorAttributeUnsupported, kAXErrorCannotComplete,kAXErrorFailure, kAXErrorIllegalArgument, \
    kAXErrorInvalidUIElement, kAXErrorInvalidUIElementObserver, kAXErrorNoValue, kAXErrorNotEnoughPrecision, kAXErrorNotImplemented, \
    kAXErrorNotificationAlreadyRegistered, kAXErrorNotificationNotRegistered, kAXErrorNotificationUnsupported, \
    kAXErrorParameterizedAttributeUnsupported, kAXErrorSuccess

# !!! this example was primarily just to familiarize with underlying APIs used by hammerspoon...
#   and I was in search of `name` and `class` properties of AXUIElement (if they exist... turns out IIUC they don't)...
#   near as I can tell,they are synthesized from attributes (i.e. name = title,desc?, class = role desc? map(AXRole)?)
#   I wanted to check b/c class and name are key to building element specifiers in AppleScript... but aren't actually on the underlying AXUIElement itself
#      I have also check three diff ui element inspectors and they all don't show name/class beyond UIBrowser which can gen AppleScript (and clearly uses underlying attributes to build these up, or just element index)


out_arg = None # make explicit which args are out args as a reminder is all, could inline this and all is fine
def explainAXError(error):
    # https://developer.apple.com/documentation/applicationservices/axerror AXError
    # kAXErrorSuccess https://developer.apple.com/documentation/applicationservices/axerror/kaxerrorsuccess
    # FYI lookup error codes in pyobjc codebase:
    #      https://github.com/ronaldoussoren/pyobjc/blob/fee56f59b158f85618a5db691012a4c84d849fbb/pyobjc-framework-ApplicationServices/metadata/raw.HIServices/arm64-15.0.fwinfo#L149C2-L164C25
    if error == kAXErrorAPIDisabled:
        return f"API Disabled ({error})"
    elif error == kAXErrorActionUnsupported:
        return f"Action Unsupported ({error})"
    elif error == kAXErrorAttributeUnsupported:
        return f"Attribute Unsupported ({error})"
    elif error == kAXErrorCannotComplete:
        return f"Cannot Complete ({error})"
    elif error == kAXErrorFailure:
        return f"Failure ({error})"
    elif error == kAXErrorIllegalArgument:
        return f"Illegal Argument ({error})"
    elif error == kAXErrorInvalidUIElement:
        return f"Invalid UI Element ({error})"
    elif error == kAXErrorInvalidUIElementObserver:
        return f"Invalid UI Element Observer ({error})"
    elif error == kAXErrorNoValue:
        return f"No Value ({error})"
    elif error == kAXErrorNotEnoughPrecision:
        return f"Not Enough Precision ({error})"
    elif error == kAXErrorNotImplemented:
        return f"Not Implemented ({error})"
    elif error == kAXErrorNotificationAlreadyRegistered:
        return f"Notification Already Registered ({error})"
    elif error == kAXErrorNotificationNotRegistered:
        return f"Notification Not Registered ({error})"
    elif error == kAXErrorNotificationUnsupported:
        return f"Notification Unsupported ({error})"
    elif error == kAXErrorParameterizedAttributeUnsupported:
        return f"Parameterized Attribute Unsupported ({error})"
    elif error == kAXErrorSuccess:
        return f"Success ({error})"
    else:
        return f"Unknown error: {error}"

def raiseOnFailure(error, message):
    if error != kAXErrorSuccess:
        raise Exception(f"{message}: {explainAXError(error)}")

def print_indent(message, indent_level=1):
    # indent each line of the message by splitting on new line, otherwise subequent lines aren't indented to match first line
    lines = message.split('\n')
    indented_lines = [f"{'  ' * indent_level}{line}" for line in lines]
    print('\n'.join(indented_lines))

def dumpAttributes(element):
    print()
    print(Fore.BLUE + f"Attributes of focused element: {element}" + Style.RESET_ALL)
    error, attrNames = AXUIElementCopyAttributeNames(element, out_arg)
    raiseOnFailure(error, "Failed to get attribute names")
    print("type of attrNames: ", isinstance(attrNames, list))
    for attr in attrNames:
        error, value = AXUIElementCopyAttributeValue(element, attr, out_arg)
        if error == kAXErrorSuccess:
            # print_indent(f"type: {type(value)}", indent_level=1)
            if isinstance(value, NSArray) and len(value) == 0:
                print_indent(f"{attr}: ()", indent_level=1) # avoid wrapping () across two lines otherwise
            else:
                print_indent(f"{attr}: {value}", indent_level=1)
        else:
            print_indent(Fore.RED + f"{attr}: <Error {explainAXError(error)}>" + Style.RESET_ALL, indent_level=1)


def get_focused_element_attributes():
    # Get the frontmost application
    # https://developer.apple.com/documentation/appkit/nsworkspace/frontmostapplication
    frontmost_app = NSWorkspace.sharedWorkspace().frontmostApplication()
    #  returns: NSRunningApplication -  https://developer.apple.com/documentation/appkit/nsrunningapplication

    pid = frontmost_app.processIdentifier()
    print(f"pid: {pid}")
    print(f"pid: {frontmost_app.localizedName()}")

    # Create an AXUIElement for the frontmost app
    # https://developer.apple.com/documentation/applicationservices/1459374-axuielementcreateapplication
    appElement = AXUIElementCreateApplication(pid)
    # returns: https://developer.apple.com/documentation/applicationservices/axuielement
    # print("app: ", app_ref.name())
    # copy attribute names:
    # https://developer.apple.com/documentation/applicationservices/1459475-axuielementcopyattributenames
    # names is second arg (by ref) but for pyobjc, IIRC, methods return multiple
    error, namesOut = AXUIElementCopyAttributeNames(appElement, out_arg)
    # error is normally the only return type, then b/c this is pyobjc, the second arg is out so its included as second arg in return (think tuple)
    # btw explanation of in/inout args being returned in python: https://pyobjc.readthedocs.io/en/latest/core/intro.html#messages-and-functions
    # print(f"names: {namesOut}")
    # raiseOnFailure(error, "Failed to get app's attribute names for")
    dumpAttributes(appElement)

    # Copy is how you "get" an attribute's value
    #   keep in mind, attribute values aren't just primitve types... can be another AXUIElement (as is the case with focused elem)
    error, focused_element = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute, out_arg)
    raiseOnFailure(error, "Failed to get focused element")
    dumpAttributes(focused_element)

if __name__ == "__main__":
    get_focused_element_attributes()
