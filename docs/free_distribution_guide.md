# Free Distribution Guide

Pocket Leak can be used and shared without paying for the Apple Developer Program, but the distribution model is still limited by Apple platform rules.

## A. What You Can Do For Free

- clone the repository from GitHub
- open the project in Xcode
- build and run the app in the iOS simulator
- install the app on your own iPhone from Xcode while using a free Apple ID or Personal Team
- share the source code, screenshots, and documentation as a portfolio project

## B. What You Cannot Do For Free

- publish Pocket Leak on the App Store
- use TestFlight to share the app with friends
- give people a GitHub link that installs the iPhone app directly
- install it like an APK or any Android-style package

## C. Options For Friends Or Reviewers

- let them clone the repo and build it themselves if they also have a Mac and Xcode
- use your own Mac and signed Xcode session to install it on your own iPhone for a demo
- pay for the Apple Developer Program later if you want TestFlight
- pay for the Apple Developer Program later if you want public App Store distribution

## D. Real Limitations

- device installs require signing from Xcode
- free installs are for personal use and local testing, not public distribution
- some capabilities such as App Groups, widgets, and share extensions may need signing and capability setup to work correctly on a device
- installed builds are not a public distribution channel
- signing and provisioning can expire or need to be refreshed when using free or personal-team style installs

## Practical Recommendation

If your goal is portfolio review, the best free workflow is:

1. clone the repo
2. run `xcodegen generate`
3. open `JTap.xcodeproj`
4. run the app in Simulator for quick checks
5. install on your own iPhone from Xcode if you want to verify device behavior
6. use the demo data mode for screenshots and screen recordings

