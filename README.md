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
    * `fvm` can be used to manage Flutter versions. This can be installed e.g. using `sudo port install fvm` on macOS, followed by `fvm use` in the project root.
    *  If you install Git on Windows, make sure to select the option to commit using Unix-style line endings.
    *  Flutter automatically enables analytics reporting to Google. If you want to disable this, run `flutter config --no-analytics` on the command line.
    *  Make sure to follow the steps that help you set up Android Studio as an editor.
    *  The unofficial [Flutter Enhancement Suite](https://plugins.jetbrains.com/plugin/12693-flutter-enhancement-suite/) plugin for Android Studio is highly recommended, and .env and Markdown plugins can also come in handy.
*  Currently, this app builds against the `stable` channel of Flutter. Make sure that's your current channel by executing `flutter channel stable`.
*  Run `flutter upgrade` followed by `flutter update-packages` to update Flutter and its internal packages.
*  Accept the Android licenses using `flutter doctor --android-licenses`.
*  Open Android Studio and create a new project from this repository.
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

* Make sure that you have an Android Emulator of a recent Android SDK version (eg. API 35) set up and ready to go.
    * Starting with Ubuntu 19.10, 32-bit apps are no longer supported. Make sure you download and use a 64-bit Android image.
* Now you can start the application and debug it. Enjoy!

### Part 2b: Running the app on an iOS emulator (macOS only)

* First make sure to follow all the steps of part 1.
* Install a more modern version of Ruby, for instance using `sudo port install ruby34`. Make sure `which gem` points to the version you just installed.
* Install command-line support for Cocoapods using `sudo gem update --system && sudo gem install cocoapods && sudo gem update`.
* Update all pods using `cd ios; pod update`.
* Start an iOS simulator, it should show up in the list of target devices in Android Studio.

### Part 3: Building the app for distribution on Android and iOS

Run `./build_all.sh` to build both the Android and iOS apps. If you want to skip either of those two apps, set the environment variables `BUILD_IOS` or `BUILD_ANDROID` to `false`.
The created app bundle (Android) file can be uploaded to the [Google Play Console](https://play.google.com/console/).
The easiest way to upload the IPA file (iOS) is using the [Transporter app](https://apps.apple.com/nl/app/transporter/id1450874784).

## Updating dependencies

* Open the `pubspec.yaml` file in Android Studio.
* If you have the Flutter Enhancement Suite installed, outdated dependencies will be automatically highlighted.
* Update all the version numbers to the latest versions and run `pub upgrade`.
* Make any required changes to the code.
* Test the new dependencies.
* Commit the changes to `pubspec.yaml`, to the code, and the file `pubspec.lock` all at once.
  Don't forget the `pubspec.lock` file, as that contains the actual version number with which you tested!

Note: sometimes it's necessary to run `flutter update-packages --force-upgrade` to force an update of the built-in Flutter dependencies.

## Taking screenshots

### Apple

To take iOS/iPadOS screenshots, use the following simulated devices:

* 6.7" - iPhone 13 Pro Max (optional)
* 6.5" - iPhone 11 Pro Max
* 5.5" - iPhone 8 Plus
* iPad Pro (12.9-inch) (3rd generation)
* iPad Pro (12.9-inch) (2nd generation)

The simulated devices' language should be set to "English (UK)", and the region to "Netherlands".

Before taking the screenshots, use the following command to make the status bar prettier (noon local time on the first day of CaDansa that year, make sure to update the date):

```shell
xcrun simctl status_bar booted override --time "2024-10-31T12:00:00+02:00" --cellularBars 4 --batteryLevel 100
```

## Troubleshooting

### iOS

If the app doesn't build on iOS, you can try the following steps, in order:

* `flutter clean`
* `flutter upgrade`
* `flutter create --platforms ios --org nl.cadansa.app .` to regenerate the iOS project. Make sure to check the `git diff` for changes!
* Ensure that `which rsync` points to `/usr/bin/rsync`, not a version installed by Homebrew or MacPorts.
