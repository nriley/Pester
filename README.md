Pester
======

Simple, disposable alarms and timers for macOS.

Building Pester
---------------

1. Clone this repository.
2. ```cd /path/to/Pester```
3. ```git submodule update --init --force```
4. Open Pester’s project file (in the `Source` folder) in Xcode and build. 

The Xcode and macOS versions I use to build Pester are mentioned at the bottom of the version history in the Read Me — or Xcode builds them into Pester’s `Info.plist` — though there should be a reasonable amount of slop.  The most common thing to break is Perl dependencies, as macOS tends to include at most 2 versions of Perl.  This is one reason why recent versions of Pester no longer support as many macOS versions as they once did (Apple’s free yearly updates, more aggressive deprecation policy, and my vanishing free time don’t help).

Running tests
-------------

Pester’s tests cover some trickier bits such as the exception-y deserialization process and interaction of `Date::Manip` with macOS date formats.

1. Select Product → Test in Xcode.

Note that `testDateCompletionSupportedLocales` is expected to fail for some Spanish and Italian relative dates — these appear to be `Date::Manip` issues (patches welcome!)

Need ideas?
-----------

Open `Pester to do.ooutline` in OmniOutliner — it contains many ideas I haven’t had time to implement.  If you don't have OmniOutliner, use [this HTML version](https://rawgit.com/nriley/Pester/master/Pester%20to%20do.html/index.html) instead.