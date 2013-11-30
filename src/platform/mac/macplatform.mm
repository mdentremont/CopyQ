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

#include <common/common.h>

#include <Cocoa/Cocoa.h>

#include <QApplication>
#include <QDebug>
#include <QWidget>

void * MacPlatform::m_currentPasteWindow = 0;

namespace {
    template<typename T> inline T* objc_cast(id from) {
        if ([from isKindOfClass:[T class]]) {
            return static_cast<T*>(from);
        }
        return nil;
    }

    void raisePasteWindow(WId wid)
    {
        ::log(QString("!! RAISE PASTE WINDOW: %1").arg(wid), LogNote);

        if (wid == 0L)
            return;

        NSRunningApplication *runningApplication = objc_cast<NSRunningApplication>((id) wid);
        NSView *view = objc_cast<NSView>((id) wid);
        //[NSApp activateIgnoringOtherApps:YES];
        if (runningApplication) {
            [runningApplication unhide];
            [runningApplication activateWithOptions:NSApplicationActivateAllWindows];
        } else if (view) {
            ::log("got a view...", LogNote);
        } else if (wid) {
            ::log("wid is non-null...", LogNote);
        } else {
            ::log("wid is null...", LogNote);
        }
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

    NSView *view = objc_cast<NSView>((id)wid);
    if (((WId) m_currentPasteWindow) == wid) {
        ::log(QString("wid is paste window: %1").arg(wid), LogNote);
        raisePasteWindow((WId) wid);
    } else if (view) {
        ::log(QString("wid is CopyQ: %1").arg(wid), LogNote);
        [NSApp activateIgnoringOtherApps:YES];

        NSWindow *window = [view window];
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
    WId current = getCurrentWindow();
    if (((WId) m_currentPasteWindow) != current) {
        if (m_currentPasteWindow) {
            NSObject *obj = objc_cast<NSObject>((id)m_currentPasteWindow);
            if (obj) {
                [obj release];
            } else {
                ::log("Unable to release paste window for some reason!", LogWarning);
            }
        }

        if (current) {
            NSObject *newObj = objc_cast<NSObject>((id)current);
            if (newObj) {
                [newObj retain];
            } else {
                ::log("Unable to retain paste window for some reason!", LogWarning);
            }
        }
    }

    m_currentPasteWindow = (void *) current;

    qWarning() << "!! GET PASTE WINDOW:" << (WId) m_currentPasteWindow;

    return (WId) m_currentPasteWindow;
}

long int MacPlatform::getChangeCount() {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSInteger changeCount = [pasteboard changeCount];
    return changeCount;
}
