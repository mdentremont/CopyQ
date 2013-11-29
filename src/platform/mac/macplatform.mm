/*
    Copyright (c) 2013, Lukas Holecek <hluk@email.cz>

    This file is part of CopyQ.

    CopyQ is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    CopyQ is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with CopyQ.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "macplatform.h"

#include <Cocoa/Cocoa.h>

#include <QApplication>
#include <QDebug>
#include <QWidget>

void * MacPlatform::m_currentPasteWindow = 0;

namespace {
    void raisePasteWindow(WId wid)
    {
        qWarning() << "!! RAISE PASTE WINDOW:" << wid;
        if (wid == 0L)
            return;

        [NSApp activateIgnoringOtherApps:YES];

        NSRunningApplication *runningApplication = reinterpret_cast<NSRunningApplication *>(wid);
        [runningApplication unhide];
        [runningApplication activateWithOptions:NSApplicationActivateAllWindows];
    }
} // namespace

PlatformPtr createPlatformNativeInterface()
{
    return PlatformPtr(new MacPlatform);
}

MacPlatform::MacPlatform()
{
    qWarning() << "!!!! NEW MacPlatform";
}

WId MacPlatform::getCurrentWindow()
{
//    NSApplication *application = [NSApplication sharedApplication];
//    if (application == NULL)
//        qWarning() << "ASJDIAJDLSAJDALDJLJL:KJS";

    qWarning() << "!! GET CURRENT WINDOW";

    NSRunningApplication *runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (runningApp == NULL)
        qWarning() << "!!@^@^@^^@^@^@^^@^@^ASJDIAJDLSAJDALDJLJL:KJS";

    WId wid = reinterpret_cast<WId>(runningApp);

    qWarning() << "!! CURRENT WINDOW:" << wid;

    return wid;

//    NSView *view = [window contentView];
//    if (view == NULL)
//        qWarning() << "(((((((((((((((((((((SAJDALDJLJL:KJS";
    //NSWindow *keyWindow = [application keyWindow];

//    QWidget *widget = QApplication::activeWindow();
//    if (widget == NULL)
//        return 0L;

//    //WId wid = reinterpret_cast<WId>(view);
//    qWarning() << "!!!!! WINDOW ID:" << widget->winId();

//    return widget->winId();
}

QString MacPlatform::getWindowTitle(WId wid)
{
    qWarning() << "!! GET WINDOW TITLE:" << wid;
    if (wid == 0L)
        return QString();

//    QWidget *widget = QWidget::find(wid);
//    if (widget == NULL)
//        return QString();

//    qWarning() << "!! WINDOW TITLE:" << widget->windowTitle();

//    return widget->windowTitle();

    NSRunningApplication *runningApplication = reinterpret_cast<NSRunningApplication *>(wid);

    QString result = QString::fromUtf8([[runningApplication localizedName] UTF8String]);

    qWarning() << "!! WINDOW TITLE:" << result;
    return result;
}

void MacPlatform::raiseWindow(WId wid)
{
    qWarning() << "!! RAISE WINDOW:" << wid;
    if (wid == 0L)
        return;

    if (((WId) m_currentPasteWindow) == wid) {
//        NSRunningApplication *runningApplication = reinterpret_cast<NSRunningApplication *>(wid);
//        [runningApplication unhide];
//        [runningApplication activateWithOptions:NSApplicationActivateAllWindows];
        raisePasteWindow((WId) wid);
    } else {
        [NSApp activateIgnoringOtherApps:YES];

        NSWindow *window = [reinterpret_cast<NSView *>(wid) window];
        [window makeKeyAndOrderFront:nil];
    }
}

void MacPlatform::pasteToWindow(WId wid)
{
    // TODO
    //Q_UNUSED(wid);

    qWarning() << "!!!! PASTE TO WINDOW:" << wid;
    if (wid == 0L)
        return;

//    NSWindow *window = [reinterpret_cast<NSView *>(QApplication::activeWindow()->winId()) window];
//    [window orderOut:nil];
//    [NSApp hide:nil];
//    usleep(150000);

    raisePasteWindow(wid);
    usleep(150000);

    CGEventSourceRef sourceRef = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    if (!sourceRef)
    {
        NSLog(@"No event source");
        return;
    }
    //9 = "v"
    CGEventRef eventDown = CGEventCreateKeyboardEvent(sourceRef, (CGKeyCode)9, true);
    CGEventSetFlags(eventDown, kCGEventFlagMaskCommand|0x000008); // some apps want bit set for one of the command keys
    CGEventRef eventUp = CGEventCreateKeyboardEvent(sourceRef, (CGKeyCode)9, false);
    CGEventPost(kCGHIDEventTap, eventDown);
    CGEventPost(kCGHIDEventTap, eventUp);
    CFRelease(eventDown);
    CFRelease(eventUp);
    CFRelease(sourceRef);

    usleep(150000);

}

WId MacPlatform::getPasteWindow()
{
    m_currentPasteWindow = (void *) getCurrentWindow();
    qWarning() << "!! GET PASTE WINDOW:" << (WId) m_currentPasteWindow;
    return (WId) m_currentPasteWindow;
}

long int MacPlatform::getChangeCount() {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSInteger changeCount = [pasteboard changeCount];
    return changeCount;
}
