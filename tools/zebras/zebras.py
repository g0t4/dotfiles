"""Live SDR exposure zebras over the primary macOS display."""

from __future__ import annotations

import argparse
import os
import signal
import sys

import AppKit
import Foundation
import numpy as np
import objc
import Quartz
import ScreenCaptureKit as SCK


def zebra_pixels(
    bgra: np.ndarray, under: int, over: int, phase: int = 0
) -> tuple[np.ndarray, float, float]:
    """Return a transparent BGRA stripe image and the two flagged percentages.

    Underexposure uses Rec. 709 luma on displayed 8-bit RGB. Overexposure
    flags any displayed RGB channel close to clipping.
    """
    b = bgra[:, :, 0].astype(np.uint16)
    g = bgra[:, :, 1].astype(np.uint16)
    r = bgra[:, :, 2].astype(np.uint16)
    luma = (54 * r + 183 * g + 19 * b + 128) >> 8
    dark = luma <= under
    bright = (r >= over) | (g >= over) | (b >= over)
    # In the unusual case that both rules match, clipping takes precedence.
    dark &= ~bright

    y, x = np.ogrid[: bgra.shape[0], : bgra.shape[1]]
    over_stripe = ((x + y + phase) % 12) < 5
    under_stripe = ((x - y + phase) % 12) < 5
    result = np.zeros_like(bgra)
    result[:, :, 2] = np.where(bright & over_stripe, 205, 0)  # red, premultiplied
    result[:, :, 0] = np.where(dark & under_stripe, 205, 0)  # blue, premultiplied
    result[:, :, 3] = np.where((bright & over_stripe) | (dark & under_stripe), 205, 0)
    count = bgra.shape[0] * bgra.shape[1]
    return (
        result,
        100.0 * np.count_nonzero(dark) / count,
        100.0 * np.count_nonzero(bright) / count,
    )


def image_to_bgra(image: Quartz.CGImageRef) -> np.ndarray:
    width = Quartz.CGImageGetWidth(image)
    height = Quartz.CGImageGetHeight(image)
    row_bytes = Quartz.CGImageGetBytesPerRow(image)
    if (
        Quartz.CGImageGetBitsPerPixel(image) != 32
        or Quartz.CGImageGetBitsPerComponent(image) != 8
    ):
        raise RuntimeError("ScreenCaptureKit returned an unsupported pixel format")
    info = Quartz.CGImageGetBitmapInfo(image)
    byte_order = info & Quartz.kCGBitmapByteOrderMask
    if byte_order != Quartz.kCGBitmapByteOrder32Little:
        raise RuntimeError(
            f"Expected little-endian BGRA pixels; bitmap info was {info:#x}"
        )
    data = Quartz.CGDataProviderCopyData(Quartz.CGImageGetDataProvider(image))
    return (
        np.frombuffer(data, dtype=np.uint8, count=height * row_bytes)
        .reshape(height, row_bytes)[:, : width * 4]
        .reshape(height, width, 4)
    )


def image_from_bgra(pixels: np.ndarray) -> Quartz.CGImageRef:
    height, width, _ = pixels.shape
    # CGImage retains the provider; bytes owns its buffer after this call.
    provider = Quartz.CGDataProviderCreateWithCFData(pixels.tobytes())
    color_space = Quartz.CGColorSpaceCreateDeviceRGB()
    return Quartz.CGImageCreate(
        width,
        height,
        8,
        32,
        width * 4,
        color_space,
        Quartz.kCGImageAlphaPremultipliedFirst | Quartz.kCGBitmapByteOrder32Little,
        provider,
        None,
        False,
        Quartz.kCGRenderingIntentDefault,
    )


class ZebraView(AppKit.NSView):
    def initWithFrame_(self, frame):
        self = objc.super(ZebraView, self).initWithFrame_(frame)
        if self is not None:
            self.image = None
        return self

    def isOpaque(self):
        return False

    def drawRect_(self, rect):
        if self.image is not None:
            context = AppKit.NSGraphicsContext.currentContext().CGContext()
            Quartz.CGContextDrawImage(context, self.bounds(), self.image)


def label(text: str, frame: tuple[int, int, int, int]) -> AppKit.NSTextField:
    field = AppKit.NSTextField.labelWithString_(text)
    field.setFrame_(((frame[0], frame[1]), (frame[2], frame[3])))
    return field


class ZebraController(Foundation.NSObject):
    def initWithOptions_(self, options):
        self = objc.super(ZebraController, self).init()
        if self is None:
            return None
        self.under = options.under
        self.over = options.over
        self.interval = 1.0 / options.fps
        self.in_flight = False
        self.filter = None
        self.config = None
        self.timer = None
        self.phase = 0
        self.frame_count = 0

        display_id = Quartz.CGMainDisplayID()
        screen = next(
            (
                item
                for item in AppKit.NSScreen.screens()
                if int(item.deviceDescription()["NSScreenNumber"]) == display_id
            ),
            None,
        )
        if screen is None:
            raise RuntimeError("Could not find the primary display in AppKit")
        frame = screen.frame()
        self.overlay = (
            AppKit.NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
                frame,
                AppKit.NSWindowStyleMaskBorderless,
                AppKit.NSBackingStoreBuffered,
                False,
            )
        )
        self.overlay.setOpaque_(False)
        self.overlay.setBackgroundColor_(AppKit.NSColor.clearColor())
        self.overlay.setHasShadow_(False)
        self.overlay.setIgnoresMouseEvents_(True)
        self.overlay.setLevel_(AppKit.NSFloatingWindowLevel + 1)
        self.overlay.setCollectionBehavior_(
            AppKit.NSWindowCollectionBehaviorCanJoinAllSpaces
            | AppKit.NSWindowCollectionBehaviorFullScreenAuxiliary
            | AppKit.NSWindowCollectionBehaviorStationary
        )
        self.overlay_view = ZebraView.alloc().initWithFrame_(
            self.overlay.contentView().bounds()
        )
        self.overlay.setContentView_(self.overlay_view)
        self.overlay.orderFrontRegardless()

        panel_frame = (
            (frame.origin.x + 24, frame.origin.y + frame.size.height - 172),
            (344, 148),
        )
        self.panel = (
            AppKit.NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
                panel_frame,
                AppKit.NSWindowStyleMaskTitled | AppKit.NSWindowStyleMaskClosable,
                AppKit.NSBackingStoreBuffered,
                False,
            )
        )
        self.panel.setTitle_("Screen zebras")
        self.panel.setLevel_(AppKit.NSFloatingWindowLevel + 2)
        self.panel.setHidesOnDeactivate_(False)
        self.panel.setCollectionBehavior_(
            AppKit.NSWindowCollectionBehaviorCanJoinAllSpaces
            | AppKit.NSWindowCollectionBehaviorFullScreenAuxiliary
        )
        self.panel.setDelegate_(self)
        content = self.panel.contentView()
        content.addSubview_(label("Over (any RGB channel)", (15, 105, 205, 20)))
        content.addSubview_(label("Under (luma)", (15, 56, 205, 20)))
        self.over_value = label("", (288, 105, 48, 20))
        self.under_value = label("", (288, 56, 48, 20))
        content.addSubview_(self.over_value)
        content.addSubview_(self.under_value)
        self.over_slider = (
            AppKit.NSSlider.sliderWithValue_minValue_maxValue_target_action_(
                self.over, min(180, self.over), 255, self, "overChanged:"
            )
        )
        self.under_slider = (
            AppKit.NSSlider.sliderWithValue_minValue_maxValue_target_action_(
                self.under, 0, max(100, self.under), self, "underChanged:"
            )
        )
        for slider, y in ((self.over_slider, 83), (self.under_slider, 34)):
            slider.setFrame_(((15, y), (316, 22)))
            slider.setContinuous_(True)
            content.addSubview_(slider)
        self.status = label("Waiting for screen capture…", (15, 7, 315, 18))
        content.addSubview_(self.status)
        self.updateLabels()
        self.panel.orderFrontRegardless()
        self.panel.makeKeyAndOrderFront_(None)
        return self

    def updateLabels(self):
        self.over_value.setStringValue_(f"{self.over}/255")
        self.under_value.setStringValue_(f"{self.under}/255")

    def overChanged_(self, sender):
        self.over = int(round(sender.doubleValue()))
        self.updateLabels()

    def underChanged_(self, sender):
        self.under = int(round(sender.doubleValue()))
        self.updateLabels()

    def windowShouldClose_(self, sender):
        AppKit.NSApp.terminate_(None)
        return True

    def start(self):
        SCK.SCShareableContent.getShareableContentWithCompletionHandler_(
            self.contentReady_error_
        )

    def contentReady_error_(self, content, error):
        if error is not None or content is None:
            self.showCaptureError_(f"Could not enumerate screens: {error}")
            return
        Foundation.NSOperationQueue.mainQueue().addOperationWithBlock_(
            lambda: self.configureCaptureWithContent_(content)
        )

    def configureCaptureWithContent_(self, content):
        display_id = Quartz.CGMainDisplayID()
        display = next(
            (item for item in content.displays() if item.displayID() == display_id),
            None,
        )
        if display is None:
            self.showCaptureError_(
                "Primary display was not available to ScreenCaptureKit"
            )
            return
        own_app = [
            app for app in content.applications() if app.processID() == os.getpid()
        ]
        self.filter = SCK.SCContentFilter.alloc().initWithDisplay_excludingApplications_exceptingWindows_(
            display, own_app, []
        )
        self.config = SCK.SCStreamConfiguration.alloc().init()
        self.config.setWidth_(display.width())
        self.config.setHeight_(display.height())
        self.config.setShowsCursor_(False)
        self.capture()
        self.timer = Foundation.NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
            self.interval, self, "tick:", None, True
        )

    def tick_(self, timer):
        self.capture()

    def capture(self):
        if self.in_flight or self.filter is None:
            return
        self.in_flight = True
        SCK.SCScreenshotManager.captureImageWithFilter_configuration_completionHandler_(
            self.filter, self.config, self.imageReady_error_
        )

    def imageReady_error_(self, image, error):
        self.in_flight = False
        if error is not None or image is None:
            self.showCaptureError_(f"Screen capture failed: {error}")
            return
        try:
            pixels = image_to_bgra(image)
            stripes, dark_pct, bright_pct = zebra_pixels(
                pixels, self.under, self.over, self.phase
            )
            self.phase = (self.phase + 1) % 12
            overlay_image = image_from_bgra(stripes)
            Foundation.NSOperationQueue.mainQueue().addOperationWithBlock_(
                lambda: self.presentFrameWithImage_dark_bright_(
                    overlay_image, dark_pct, bright_pct
                )
            )
        except Exception as exc:
            self.showCaptureError_(str(exc))

    def presentFrameWithImage_dark_bright_(self, image, dark_pct, bright_pct):
        self.frame_count += 1
        self.overlay_view.image = image
        self.overlay_view.setNeedsDisplay_(True)
        self.status.setStringValue_(
            f"Blue {dark_pct:.1f}%   Red {bright_pct:.1f}%   · frame {self.frame_count}"
        )

    def showCaptureError_(self, message):
        print(message, file=sys.stderr, flush=True)
        Foundation.NSOperationQueue.mainQueue().addOperationWithBlock_(
            lambda: self.stopWithError_(message)
        )

    def stopWithError_(self, message):
        self.status.setStringValue_(message)
        if self.timer is not None:
            self.timer.invalidate()
            self.timer = None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--under",
        type=int,
        default=16,
        help="luma at or below this is blue (0–255; default 16)",
    )
    parser.add_argument(
        "--over",
        type=int,
        default=250,
        help="any RGB channel at or above this is red (0–255; default 250)",
    )
    parser.add_argument("--fps", type=float, default=3, help="capture rate (default 3)")
    options = parser.parse_args()
    if not (
        0 <= options.under <= 255 and 0 <= options.over <= 255 and 0 < options.fps <= 30
    ):
        parser.error("thresholds must be 0–255 and fps must be above 0 and at most 30")
    if not Quartz.CGPreflightScreenCaptureAccess():
        Quartz.CGRequestScreenCaptureAccess()
        raise SystemExit(
            "Allow screen recording for the terminal/Python process in System Settings, then run again."
        )
    app = AppKit.NSApplication.sharedApplication()
    app.setActivationPolicy_(AppKit.NSApplicationActivationPolicyRegular)
    app.finishLaunching()
    # Python does not service SIGINT while Cocoa owns the native event loop.
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    controller = ZebraController.alloc().initWithOptions_(options)
    controller.start()
    app.activateIgnoringOtherApps_(True)
    AppKit.NSApp.run()


if __name__ == "__main__":
    main()
