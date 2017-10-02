Pester
======

Simple, disposable alarms and timers for macOS.

Building Pester
---------------

1. Clone this repository.
2. ```cd /path/to/Pester```
3. ```git submodule update --init --force```
4. Copy the Growl 1.2.3 SDK framework to `/Library/Frameworks` (included in the [Growl 2.0.1 SDK](http://growl.info/downloads#devdownloads) in `Framework/Legacy`)
5. Open Pester’s project file (in the `Source` folder) in Xcode and build. 

The Xcode and macOS versions I use to build Pester are mentioned at the bottom of the version history in the Read Me — or Xcode builds them into Pester’s `Info.plist` — though there should be a reasonable amount of slop.  The most common thing to break is Perl dependencies, as macOS tends to include at most 2 versions of Perl.  This is one reason why recent versions of Pester no longer support as many macOS versions as they once did (Apple’s free yearly updates, more aggressive deprecation policy, and my vanishing free time don’t help).

If you just want to build Pester for yourself and don’t care about preserving backwards compatibility, it is easiest to delete whichever ParseDate-10.*x* target doesn’t build cleanly.  For example, Pester 1.1b23 was built for distribution with Xcode 9.0 on macOS 10.12.6, but will not build on macOS 10.13 until you remove the ParseDate-10.9 target.

Running tests
-------------

Pester’s tests cover some trickier bits such as the exception-y deserialization process and interaction of `Date::Manip` with macOS date formats.

1. Select Product → Test in Xcode.

Note that `testDateCompletionSupportedLocales` is expected to fail for some Spanish and Italian relative dates — these appear to be `Date::Manip` issues (patches welcome!)

Need ideas?
-----------

Open `Pester to do.ooutline` in OmniOutliner — it contains many ideas I haven’t had time to implement.  If you don't have OmniOutliner, use [this HTML version](https://rawgit.com/nriley/Pester/master/Pester%20to%20do.html/index.html) instead.