Pester
======

Simple, disposable alarms and timers for macOS.

Building Pester
---------------

1. Clone this repository.
2. ```cd /path/to/Pester```
3. ```git submodule update --init --force```
4. Copy the Growl 1.2.3 SDK framework to `/Library/Frameworks` (included in the [Growl 2.0.1 SDK](http://growl.info/downloads#devdownloads) in `Framework/Legacy`)
5. Open the project file (in the `Source` folder) in Xcode and build. 

The corresponding Xcode version is mentioned in the version history, though there should be a reasonable amount of slop.  The main thing to break is Perl dependencies, as macOS tends to include at most 2 versions.  This is one reason why recent versions of Pester no longer support as many macOS versions as they once did (Apple’s free yearly updates, more aggressive deprecation policy, and my vanishing free time don’t help).

Running tests
-------------

Pester’s test coverage is dismal, but some tests do exist for trickier bits such as the exception-y deserialization process and interaction of `Date::Manip` with macOS date formats.

1. Select Product → Test in Xcode.

Need ideas?
-----------

Open `Pester to do.oo3` in OmniOutliner — it contains many ideas I haven’t had time to implement.  If you don't have OmniOutliner, use [this HTML version](https://rawgit.com/nriley/Pester/master/Pester%20to%20do.html/index.html) instead.
