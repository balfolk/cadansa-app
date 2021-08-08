# CaDansa app

[![Dart](https://github.com/balfolk/cadansa-app/actions/workflows/dart.yml/badge.svg)](https://github.com/balfolk/cadansa-app/actions/workflows/dart.yml)

This is the [Flutter](https://flutter.dev/)-based mobile app for the [CaDansa festival](https://cadansa.nl). This app is designed to run on Android and iOS.

## Installation

### Part 0: Requirements

Any system will require about 10 GB of free disk space, and an installation of any Linux distribution, macOS, or Windows 10.

#### Linux

Most Linux distributions should not need any additional dependencies. The full list of required tools can be found near the top of the Flutter installation page.

#### macOS

Make sure you're on the latest version of macOS. Install XCode through the Mac App Store, open it, and press "Install" when the popup for additional components appears.
Then install the XCode command line tools by running `xcode-select --install` on the command line, followed by `sudo xcodebuild -license`. 

#### Windows

Windows requires the most configuration to set up. Make sure to carefully follow the setup instructions in the Flutter documentation and you should be good to go.
Before starting, please ensure your Windows 10 system has all the latest updates and patches installed.


### Part 1: Installation and running tests

*  First, install Flutter and associated programs (such as Android Studio) according to the instructions here: https://flutter.dev/docs/get-started/install.
    *  If you install Git on Windows, make sure to select the option to commit using Unix-style line endings.
    *  Flutter automatically enables analytics reporting to Google. If you want to disable this, run `flutter config --no-analytics` on the command line.
    *  Make sure to follow the steps that help you set up Android Studio as an editor.
    *  The unofficial [Flutter Enhancement Suite](https://plugins.jetbrains.com/plugin/12693-flutter-enhancement-suite/) plugin for Android Studio is highly recommended, and .env and Markdown plugins can also come in handy.
*  Currently, this app builds against the `stable` channel of Flutter. Make sure that's your current channel by executing `flutter channel stable`.
*  Run `flutter upgrade` followed by `flutter update-packages` to update Flutter and its internal packages.
*  Accept the Android licenses using `flutter doctor --android-licenses`.
*  Open Android Studio and create a new project from this repository.
    * On an Apple Silicon (ARM) machine, _do not_ attempt to set Android Studio to full screen - use Windows -> Zoom instead. For an unknown reason full screen breaks the application.
    * You need to have an SSH key set up in order to do so.
    * Make sure to add it as a Flutter project. If you can't do that, first ensure you have gone through the entire set-up process of Flutter.
*  Head to Android Studio Settings -> Languages & Frameworks -> Dart and enable Dart support for this project. Set the Dart SDK location to `bin/cache/dart-sdk` relative your Flutter installation directory.
    * Android Studio Settings are located under Android Studio -> Preferences (or  ⌘,) on macOS and under File -> Settings on Linux and Windows.
*  The banner in Android Studio should change to give you the option to get packages; do so now. Wait for the downloads to complete.
    * If there's no banner, manually execute `flutter pub get`.
*  Set up a `.env` file in the top-level repository directory containing `CONFIG_URI=https://...`, where the URI points to a local or remote resource containing the configuration.
    * If you use a local file, add it to the `assets` section of the `pubspec.yaml`, and use the same (relative) path in the `.env` file. Make sure to not commit these changes!
*  Obtain the app & map fonts (or use your favourite fonts), and put them into `assets/fonts/app-font.otf` and `assets/fonts/map-{regular,bold,light}.otf`, respectively.

### Part 2a: Running the app on an Android Emulator

* Make sure that you have an Android Emulator of a recent Android SDK version (eg. API 30) set up and ready to go.
    * Starting with Ubuntu 19.10, 32-bit apps are no longer supported. Make sure you download and use a 64-bit Android image.
* Now you can start the application and debug it. Enjoy!

### Part 2b: Running the app on an iOS emulator (macOS only)

* First make sure to follow all the steps of part 2a.
* Install command-line support for Cocoapods using `sudo gem install cocoapods`.
* Update all pods using `cd ios; pod update`.
* If you're on an Apple Silicon chip, configure XCode to run using Rosetta 2 by navigating to the application, right-clicking it, selecting "Get Info", and ticking "Open using Rosetta".
* Open the project in XCode by starting XCode, selecting "Open a project or file", and opening the `ios` folder of this project.
* If you're on an Apple Silicon chip, start the iOS emulator using Rosetta 2. The easiest way to find it is to start it from XCode using XCode -> Open Developer Tool -> Simulator, then right-clicking it in the dock and selecting Options -> Show in Finder. From this executable the setting can be modified similar to how you just did it for XCode.
    * Make sure your iOS device has iOS 12.0 or greater installed, as that's the minimum supported version for this app.
* Once a simulated iOS device is running, it should show up in the list of target devices in Android Studio. At this point XCode can safely be closed.

In case of errors on iOS, it is advised to first try cleaning everything before attempting a fresh build:
```flutter clean; flutter upgrade; flutter build ios```

## Updating dependencies

* Open the `pubspec.yaml` file in Android Studio.
* If you have the Flutter Enhancement Suite installed, outdated dependencies will be automatically highlighted.
* Update all the version numbers to the latest versions and run `pub upgrade`.
* Make any required changes to the code.
* Test the new dependencies.
* Commit the changes to `pubspec.yaml`, to the code, and the file `pubspec.lock` all at once.
  Don't forget the `pubspec.lock` file, as that contains the actual version number with which you tested!

Note: sometimes it's necessary to run `flutter update-packages --force-upgrade` to force an update of the built-in Flutter dependencies.
