# IronBank [![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/Carthage/Carthage/master/LICENSE.md)

IronBank is designed to be a dependence manager  tool for Cocoa project.

## Why should I use IronBank?

There are several similar tools exists now, and they are good. Why should I use IronBank?

For example, in your iOS project, you should add some static resources such as javascript or html files. They are large and will change sometimes in the future, you don't want to add them to the current git repository used by now, because it will cause the unnecessary size increasement of git repository. How can you handle this? 

Using git submodule? Oh, it will be a nightmare when you have to remove it or change its address. [CocoaPods](http://cocoapods.org/) may be a good choice. But you still need to write a podspec file by your own and put it carefully in your detached resource git repository. Cocoapods is a centralized tool, it wastes me more and more time waiting for pulling its specs. That's why I prefer [Carthage](https://github.com/Carthage/Carthage) in my swift project. But Carthage can not do that, neither [Swift Package Manager](https://github.com/apple/swift-package-manager) can. For now, SPM can not be used for iOS project.

The main purpose of IronBank is fetch the resources listed in the configuration file located in the root path of project, and put them in a fixed path relative to your project. Just like a reference, configuation file points to some resources on the Internet, which used by IronBank to download it for you.

Since IronBank is in early development, some important features have not been implemented.

- build framework and cache the build result.
- create swift modulefile for Objective-C static library to use it as custom module in Swift project.


> Adding IronBank support to your project has no side effects even if you have used other tools. 


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
    # Optional, default is master. Checkout version.
    version: "4.6.0"
    # Optional. Override the checkout folder name.
    name: "Alamofire-repo"
```

Version can be git hash, git branch, git tag, or string with version syntax listed above:

```
'~> 0.1.2' Version 0.1.2 and the versions up to 0.2, not including 0.2 and higher
'~> 0.1' Version 0.1 and the versions up to 1.0, not including 1.0 and higher
'~> 0' Version 0 and higher, this is basically the same as not having it.
```


## Downloading 

IronBank will download the resource from web to the path `IronBank/Downloads`.

``` yaml
- download: # Download resources from web.
    # Required. Name of the folder in Downloads directory.
    name: "Crashlytics"
    # Required. the http url used to download 
    url: "https://s3.amazonaws.com/kits-crashlytics-com/ios/com.twitter.crashlytics.ios/3.9.3/com.crashlytics.ios-manual.zip"
    # Optional. Run custom shell in the proper moment.
    hooks:
      # Run shell after the http is downloaded successfully. Current shell path is the Download directory in the project.
      after:
        - "unzip *.zip"
        - "rm *.zip"
```
