#!/bin/bash

# This script is based on the blog post and sources below.
# Credits go to: 
#  
# https://gist.github.com/949831
# http://blog.carbonfive.com/2011/05/04/automated-ad-hoc-builds-using-xcode-4/
 



###############################
## Don't edit below
###############################

# Tries to figure out project and scheme names
project_dir=`pwd`
workspace=$(find . -maxdepth 2 -name "project.xcworkspace" |sed "s/^.\///")
xcodeproj=$(echo $workspace| sed "s/\/.*$//")
scheme=$(find $xcodeproj -regex ".*xcshareddata/xcschemes/.*\.xcscheme" |head -1 |sed "s/^.*xcschemes\///" |sed "s/\.xcscheme//")

device_name="$1"
[ $# -eq 0 ] && { device_name="iphone";}



function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}
 
function build_app()
{
  local derived_data_path="$HOME/Library/Developer/Xcode/DerivedData"
 
  #get the name of the workspace to be build, used as the prefix of the DerivedData directory for this build
  local workspace_name=$(echo "$workspace" | awk -F. '{print $1}')
  #build the app
 
#  disabled overriding PRODUCT_NAME, setting applies to all built targets in Xcode 4 which renames static library target dependencies and breaks linking
xcodebuild  -arch i386 -parallelizeTargets -jobs 4 -verbose -workspace "$workspace" -scheme "$scheme" -sdk iphonesimulator -configuration Debug build
  if [ $? -ne 0 ]
  then
    failed xcodebuild
  fi
 
}


build_app
