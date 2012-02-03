**xcodebuild.sh**

A build script based upon this:

https://gist.github.com/949831
http://blog.carbonfive.com/2011/05/04/automated-ad-hoc-builds-using-xcode-4/

Usage:

* Put xcodebuild.sh somewhere in your PATH
* Copy the top part of the file (the configuration) to a new file in your XCode project folder
* Edit the file and change the settings to match your configuration


**xcoderun.sh**

A script to build and run from command line.

Requirements:

  ios-sim, install from brew with: 
  brew install ios-sim

Usage:

* Put xcoderun.sh somewhere in your PATH

From the root folder of your XCode project type xcoderun.sh

The script will try to lookup the project file and your first available
scheme (make sure it's "shared" in XCode) automatically.

When the project is successfully built, the product is looked up and 


xbuild.sh is a script that simply builds the current project with the
first available scheme.
