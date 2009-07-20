.. Pester documentation master file, created by
   sphinx-quickstart on Mon Jun  1 22:57:22 2009.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Pester's documentation!
==================================

=============
Pester  1.1b8
=============
UNRELEASED—do not distribute

A simple alarm clock and timer for Mac OS X.

Written by Nicholas Riley <pester@sabi.net>.
Obtain updates from <http://web.sabi.net/nriley/software/>.

Note: This documentation is not yet updated for version 1.1, though most of it
should still apply; please read the release notes at the end for a listing of
what has changed in this version. This beta version of Pester 1.1 is not yet
feature-complete; some user interface elements from earlier betas are missing
because they don’t work yet.

-----------
What is it?
-----------

Don’t want to miss the bus or train? Have a meeting coming up soon and want to
be reminded of it? Too much trouble to create an appointment in Palm Desktop,
iCal or Entourage? Pester can help.



------------
Installation
------------

Pester should work on Mac OS X 10.4 or later; it has been tested on Mac OS X
10.4.11 and 10.5.1.

To install Pester, simply drag the Pester icon to your Applications folder or
another convenient location. If you use Pester often, drag it to the Dock or
add it to your Login Items.

If for some reason you find Pester not to your liking, remove it by dragging
its icon to the Trash. Pester’s preferences file is named
“net.sabi.Pester.plist” and is located in the Library/Preferences subfolder of
your Home folder.

------------
Usage
------------

Use Pester to set alarms for times in the future. Alarms that are scheduled to
expire after you quit Pester are saved automatically. Pester must be running
in order to notify you that an alarm has expired. If an alarm expires while
Pester isn’t running, you will not be notified, but the alarm’s time will be
“«expired»” in Pester’s alarm list.

To set an alarm, click the Pester icon, choose “Set Alarm…” from the Alarm
menu, or press ⌘N, and the Set Alarm window (shown above) will appear.

First type a message if you wish, otherwise the rather unimaginative “Alarm!”
will be used. Recent messages you’ve used appear in the menu; if you mistype
or want to remove a message, click the “–” button. To remove the all recent
messages from the menu, click “– All”.

To specify the alarm time in seconds, minutes or hours from now, click the
“in” radio button, then type a number and pick a unit from the popup menu. To
quickly pick one of the units from the keyboard, type S, M or H after typing a
number.

To specify an absolute time, click the “at” radio button, type a time and
date. If you’re outside the US, the time format may not be what you expect;
I’m sorry, but a multitude of date-related Cocoa bugs make supporting
localization very difficult. In addition to typing numbers, you can select a
relative date from the menu to the right of the date field, or type words such
as:

Time: “morning”, “noon”, “afternoon”, “dinner”, “midnight”
Date: “today”, “tomorrow”, “next Thursday”, “November”

The text at the bottom left corner of the window changes as you type to
indicate whether the date and time you’re typing is valid.

When an alarm expires, Pester’s Dock icon bounces once, your Mac beeps, and
Pester displays a dialog box:


To view or remove alarms, choose “All Alarms…” from the Alarm menu or press
⌘L.

Alarms shown as “«expired»” expired while Pester was not running. As alarms
are set, they appear in the list; alarms which expire while Pester is running
are removed from the list. To remove one or more alarms, select them and click
Remove.

-------------
More features
-------------

Pester includes a Dock menu, which you can access by Control (⌃)-clicking
Pester’s icon.

From this menu, you can view information about the next alarm, open the Set Alarm window, or open the Alarms window.  The number of alarms is shown in parentheses.

Pester’s Dock icon displays the time until the next alarm expires.

Pester is also fully Y3K-compliant. It can be comforting to know that even if you won’t be around then, if your Mac still works, so will Pester.

--------------------------
Frequently asked questions
--------------------------

Q: Why isn’t Pester a full-featured calendar/scheduling program? What use is it otherwise?

A: I wrote and use Pester on my Mac for the same reason I use programs such as BigClock and TikTok on my Palm, the built-in clock on my Newton and the alarm on my cellular phone. Sometimes all you want is an alarm to go off in 5 minutes, not an “appointment” or “meeting” entry that survives in perpetuity and is synchronized with your phone, PDA and iPod. On the other hand, if you’re happy with what you’re using, stick with it.

Q: OK, but why doesn’t Pester have feature X?

A: I didn’t need it. I have looked at (and even registered) some similar programs such as Alarm Clock Pro, Alarm Clock S.E., CountDown, Tea Timer and the like. None of them did what I wanted. Please check out those other programs first; if Pester comes closest to your ideal but is missing a key feature, let me know and I’ll consider adding it.

Q: Under what conditions is the source code licensed?

A: Please see my Web page for details. Essentially: don’t pass it off as your own, and give me credit if you use all or part of it in your own software.

--------------------------
Version history
--------------------------

1.1 / forthcoming
-----------------
•	Requires Mac OS X 10.4 or later (Universal Binary).
•	Fixed small memory leaks on alarm creation and with the “Remove” button in the alarm list window.
•	Fixed vertical resizing of the alarm list window.
•	Fixed ‘s’, ‘m’, ‘h’, ‘d’ and ‘w’ shortcuts for selecting alarm interval so they work regardless of the insertion point position.
•	Fixed time remaining in the Dock being wrong by one second, or showing «expired».
•	Fixed empty messages appearing in the alarm message combo box.
•	Fixed display of time intervals between 1 and 59 minutes: now “#m” instead of “0h #m”.
•	Fixed display of time intervals between 24 and 48 hours: now “One day” instead of “1 days”.
•	Fixed alarms not expiring after you put your Mac to sleep and wake it up again.
•	Better indicate when a duration is out of range (okay, Nat?)
•	Added more keyboard navigation, type-selection, sorting and iTunes-like row coloring to the alarm list window.
• Added daily and weekly
•	View alerts for scheduled alarms as help tags in the alarm list window.
•	Customizable alerts: the previously-mandatory notification dialog box, alert sound and Dock bouncing are now all optional, and speech is new.
•	Ellipsize long alarm messages in the alarm list window.
•	Added Delete keyboard shortcut for removing alarms to the alarm list window.
•	Alarm removal in the alarm list window is now undoable.
•	Added in-application read me viewer with section navigation, instead of opening TextEdit.
•	Retain highlighted alarms in the alarm list window when alarms are added, removed or resorted.
•	Removed horizontal scroll bar from the alarm list window because it wasn’t ever available.
•	Replaced buggy and deprecated Cocoa natural language date parser with the Perl Date::Manip module.
•	Updated to new Cocoa date formatters, better supporting international date and time formats.
•	Fixed text display with non-Roman languages.
•	Added Preferences, with optional systemwide keyboard shortcut for set alarm window.
•	Only show set alarm window when Pester comes to the front if an alarm isn’t in the process of expiring.
•	Only bring Pester to the front if needed for the type of alert selected; if Pester was hidden or not in front before an alarm expired, it switches back and hides if necessary after the alarm is dismissed. (This means you can dismiss an alarm by clicking or pressing the return key and go right back to work.)
•	Added simple repeating alarms. When the “Display message and time” alert is selected, each time an alarm expires you have an opportunity to stop it repeating; otherwise, remove alarms from the alarm list between expirations to stop them from repeating. This works well for things like “remind me every 15 minutes to take a break”. An alarm won’t start to repeat until the alerts have finished going off and you dismiss it, so you won’t come back to several thousand alerts!
•	Added a “snooze” feature; works similarly to editing an alarm interval, with an additional “until…” option (‘u’ shortcut).
•	Added a popup calendar to the Set Alarm window and the “snooze until” sheet.
•	Added ⇧⌘T shortcut to switch between “in” and “at”.
•	Default to today’s date in the “at” section.
•	Reduced Pester’s processor usage while alarms are pending, and while the “Set Alarm” window is open but hidden.
•	Changed alarm storage to be more reliable, expandable and human-readable, if a bit slower. Conversion occurs at startup and is one-way (if you really need it to be two-way, the feature would not be hard to add).  The alarm list should no longer become lost with a message such as “2002-11-18 00:31:24.461 Pester[8545] An error occurred while attempting to restore the alarm list: \*\*\* Incorrect archive: unexpected byte”.
•	Switched to apple-generic versioning (agvtool, etc.).  Xcode 2.4 or later is required to build Pester 1.1.
•	Incorporated Sparkle for automatic updates.
•	Creator code is now Pest instead of Pstr (the latter was already registered).

--------------------------
Still to be fixed for 1.1:
--------------------------

•	Dock bouncing doesn’t work when Pester is frontmost.
•	Customizable alerts: AppleScript, playback of sounds, images and movies (anything QuickTime can handle).
•	Sometimes Pester will not open the Set Alarm window when you bring it to the front and no other window is open.
•	Sometimes, alarms stay as expired, end up in the 'expired' section of the alarm list, and never get removed.
•	Handle alarm—mostly alert—restoration failure (finish implementing PSError, test cases).
•	The Dock icon still sometimes displays «expired» briefly; this is an artifact of the new timer implementation.
•	Write documentation.
•	Alarm times can be off by up to one second in certain cases.
•	Extremely delayed alarm times can be huge (4....... years)

----------------------------------------------------
Known bugs in this version (not to be fixed by 1.1):
----------------------------------------------------
•	Type-selection of alarms by their dates and times in the alarm list only works well when the items in the list are in approximate alphabetical order; this breaks with certain date and time formats.

-----------------------------------------------
Additional features planned for later versions:
-----------------------------------------------
•	Better repeating alarms, such as a “real time” option so you can schedule an alarm to go off every hour, on the hour, for example.
•	Better handling of non-repeating expired alarms—offer the option to have the alarms go off when Pester is restarted?
•	Alarms (unscheduled ones, at least) as documents.
•	Notifications before an alarm goes off, as in xalarm.
•	Full localization of all text in the application, not just date and time formats.
•	User interface overhaul (Philippe, I am not forgetting :-)

[Two rereleases of 1.0 had no changes in the Pester application itself; they fixed problems with double-clicking the Read Me, so the version number was not changed.]

1.0 / 14 October 2002
---------------------
Added alarm list, saved alarms, Dock icon/menu, live alarm time, other features.

1.0d1 / 9 October 2002
----------------------
First public release.

---------------------
Acknowledgments
---------------------

Pester uses Andy Matuschak’s Sparkle, for which the following conditions apply:

Copyright (c) 2006 Andy Matuschak

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Pester uses Sullivan Beck’s Date::Manip module.

Pester uses code from Dan Wood’s TableTester examples.

Pester uses BDAlias, for which the following conditions apply:

Copyright © 2001, bDistributed.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

•	Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
•	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
•	Neither the name of bDistributed.com, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Pester includes software developed by The Omni Group. Unmodified versions of this software are available at http://www.omnigroup.com/developer/.


Contents:

.. toctree::
   :maxdepth: 2

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

