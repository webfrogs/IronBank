# IronBank [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/Carthage/Carthage/master/LICENSE.md)

IronBank is designed to be a dependence manager  tool for Cocoa project.

## Why should I use IronBank?

There are several similar tools exists now, and they are good. Why should I use IronBank?

For example, in your iOS project, you should add some static resources such as javascript or html files. They are large and will change sometimes in the future, you don't want to add them to the current git repository used by now, because it will cause the unnecessary size increasement of git repository. How can you handle this? 

Using git submodule? Oh, it will be a nightmare when you have to remove it or change its address. [CocoaPods](http://cocoapods.org/) may be a good choice. But you still need to write a podspec file by your own and put it carefully in your detached resource git repository. Cocoapods is a centralized tool, it wastes me more and more time waiting for pulling its specs. That's why I prefer [Carthage](https://github.com/Carthage/Carthage) in my swift project. But Carthage can not do it, neither [Swift Package Manager](https://github.com/apple/swift-package-manager) can. For now, SPM can not be used for iOS project.

The main purpose of IronBank is fetch the resources listed in the configuration file located in the root path of project, and put them in the fixed path relative to the project. Just like a reference in memory.

Since IronBank is in early development, some important features have not been implemented.

- build framework and cache the build result.
- create swift modulefile for Objective-C static library to use it as custom module in Swift project.


# Install

IronBank is written in Swift 4, so you should install Xcode 9 first. Latest release version of Xcode is recommended.

Clone this repository using Git:

```
git clone https://github.com/webfrogs/IronBank.git
```

Change path to this repo and run command:

```
make install
```

# Usage

Create a configuration file named `Bankfile.yml` in your project's root path. Then run the command:

```
ironbank install
```

YES, IronBank uses YAML as the configuration file's format. It may be unfamiliar to iOS developers, but it is easy to learn.

The root data struction of configuration file is an array. For now, it supports two dependent types. One is Git repository and the other is HTTP downloading.

## Git Repository

IronBank will clone the git repository, and checkout the resource from git with the version specified by you. You can find them in the folder `IronBank/Checkouts` from the project's root path.

``` yaml
- git: # Git repository
    # Required. Git remote address.
    remote: "https://github.com/Alamofire/Alamofire.git"
    # Required. Checkout version.
    version: "4.6.0"
    # Optional. Override the checkout folder name.
    name: "Alamofire-repo"
```

## Downloading 

IronBank will download the resource from web to the path `IronBank/Downloads`.

``` yaml
- download: # Downloading from web.
    # Required. Name of the folder in Downloads directory.
    name: "Crashlytics"
    # Required. the http url used to download 
    url: "https://s3.amazonaws.com/kits-crashlytics-com/mac/com.twitter.crashlytics.mac/3.9.3/com.twitter.crashlytics.mac-manual.zip"
    # Optional. Run custom shell in the proper moment.
    hooks:
      # Run shell after downloading. The shell path is the Download directory.
      after:
        - "unzip *.zip"
        - "rm *.zip"
```