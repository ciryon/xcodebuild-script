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

scheme="$2"
[ $# -lt 2 ] && { 
scheme=$(find $xcodeproj -regex ".*xcshareddata/xcschemes/.*\.xcscheme" |head -1 |sed "s/^.*xcschemes\///" |sed "s/\.xcscheme//")
}

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
  echo "Running xcodebuild for scheme $scheme of $workspace..."
 
#  disabled overriding PRODUCT_NAME, setting applies to all built targets in Xcode 4 which renames static library target dependencies and breaks linking
#  xcodebuild -verbose -workspace "$workspace" -scheme "$scheme" -sdk iphoneos -configuration Release clean build PRODUCT_NAME="$product_name" >| xcodebuild_output
rm -f /tmp/xcodebuild_output
#xcodebuild -verbose -workspace "$workspace" -scheme "$scheme" -sdk iphoneos -configuration Release clean build
xcodebuild  -arch i386 -parallelizeTargets -jobs 4 -verbose -workspace "$workspace" -scheme "$scheme" -sdk iphonesimulator -configuration Debug build > /tmp/xcodebuild_output
  if [ $? -ne 0 ]
  then
    tail -n20 /tmp/xcodebuild_output
    failed xcodebuild
  fi
 

  #locate this project's DerivedData directory
  #local project_derived_data_directory=$(grep -oE "$workspace_name-([a-zA-Z0-9]+)[/]" /tmp/xcodebuild_output | sed -n "s/\($workspace_name-[a-z]\{1,\}\)\//\1/p" | head -n1)
  
  # Assume that the first instance of $workspace_name in the derived data dir is the output dir 
  local project_derived_data_directory=$(ls "$derived_data_path" |grep "$workspace_name")
  local project_derived_data_path="$derived_data_path/$project_derived_data_directory"

  echo "Located $project_derived_data_directory in $project_derived_data_path"
  #locate the .app file
 
#  infer app name since it cannot currently be set using the product name, see comment above
#  project_app="$product_name.app"
  project_app=$(ls -1 "$project_derived_data_path/Build/Products/Debug-iphonesimulator/" | grep "$scheme.*\.app$" | head -n1)
 
  # if [ $(ls -1 "$project_derived_data_path/Build/Products/Release-iphoneos/$project_app" | wc -l) -ne 1 ]
  if [ $(ls -1 "$project_derived_data_path/Build/Products/Debug-iphonesimulator/" | grep ".*\.app$" | wc -l) -lt 1 ]
  then
    echo "Failed to find a single .app build product."
    # echo "Failed to locate $project_derived_data_path/Build/Products/Release-iphoneos/$project_app"
    failed locate_built_product
  fi
  full_path_to_app="$project_derived_data_path/Build/Products/Debug-iphonesimulator/$project_app"
 echo "Built $full_path_to_app"
}

function run_app() {
rm -f /tmp/iossim-output
ios-sim launch "$full_path_to_app" --stdout /tmp/iossim-output --stderr /tmp/iossim-output --exit --family "$device_name"
open -a /Applications/Utilities/Console.app /tmp/iossim-output
}

echo
echo "**** Building"
build_app
echo

echo
echo "**** Running"
run_app
echo
echo "**** Complete!"
