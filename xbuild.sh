#!/bin/bash

# This script is based on the blog post and sources below.
# Credits go to: 
#  
# https://gist.github.com/949831
# http://blog.carbonfive.com/2011/05/04/automated-ad-hoc-builds-using-xcode-4/




###############################
## Don't edit below
###############################



function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}
function find_workspace_in()
{
  folder=$1
  echo "Looking in $folder"
    project_workspace=$(find $folder -maxdepth 2 -name "project.xcworkspace")
    if [[ $project_workspace == "" ]]; then
      find_workspace_in $(dirname "$folder") #recursively go up until we find the project folder
    else
        workspace_name=$(echo $project_workspace|sed "s/^.*\///")
        workspace=$(echo $workspace_dir|sed "s/.xcworkspace//")
        project_dir=$folder
        workspace=$(ls $project_dir |grep xcworkspace)
        projectfile_dir=$(echo $project_workspace|sed "s/project.xcworkspace//")
        project_name=$(echo $project_dir |sed "s/.*\///") # Assume scheme name is same as project dir name (!)
        scheme=$(ls $projectfile_dir/xcshareddata/xcschemes/$project_name.xcscheme |sed "s/.*xcschemes\///" |sed "s/\.xcscheme//")
        testscheme=$(ls $projectfile_dir/xcshareddata/xcschemes/ |grep Test |sed "s/.*xcschemes\///" |sed "s/\.xcscheme//")

        echo "Project dir: '$project_dir'"
        echo "Project name: '$project_name'"
        echo "Project root: '$folder'"
        echo "Project file dir: $projectfile_dir"
        echo "Project scheme: $scheme"
        echo "Workspace: $workspace"
        echo ""
    fi

}

function build_app()
{

    #get the name of the workspace to be build, used as the prefix of the DerivedData directory for this build
    local workspace_name=$(echo "$workspace" | awk -F. '{print $1}')
    #build the app

    #  disabled overriding PRODUCT_NAME, setting applies to all built targets in Xcode 4 which renames static library target dependencies and breaks linking
    cd $project_dir
    if [[ $should_test ]]; then
      run_unit_tests.rb  $workspace $testscheme
    else
      xcodebuild  -arch i386 -parallelizeTargets -jobs 4 -verbose -workspace "$workspace" -scheme "$scheme" -sdk iphonesimulator -configuration Debug build
      if [ $? -ne 0 ]
      then
        failed xcodebuild
      fi
    fi
}

function run_app() {

    local derived_data_path="$HOME/Library/Developer/Xcode/DerivedData"
    #locate this project's DerivedData directory
    #local project_derived_data_directory=$(grep -oE "$workspace_name-([a-zA-Z0-9]+)[/]" /tmp/xcodebuild_output | sed -n "s/\($workspace_name-[a-z]\{1,\}\)\//\1/p" | head -n1)

    # Assume that the first instance of $workspace_name in the derived data dir is the output dir
    project_derived_data_directory=$(ls "$derived_data_path" |grep "$scheme")
    project_derived_data_path="$derived_data_path/$project_derived_data_directory"

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
    #echo "Built $full_path_to_app"
    echo "*** Running **"
    echo "****************"
#rm -f /tmp/iossim-output
ios-sim launch "$full_path_to_app" --family "$device_name"
#ios-sim launch "$full_path_to_app" --stdout /tmp/iossim-output --stderr /tmp/iossim-output --exit --family "$device_name"
#open -a /Applications/Utilities/Console.app /tmp/iossim-output
}



if [[ $1 == "test" ]]; then
  should_test=1
fi
if [[ $1 == "run" ]]; then
  should_run=1
fi

echo "*** Preparing **"
echo "****************"

folder=$(pwd)

find_workspace_in $folder

echo "*** Building **"
echo ****************""
echo ""
echo ""
build_app
if [[ $should_run ]]; then
  run_app
fi
