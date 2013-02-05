#!/usr/local/bin/ruby
# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

#xcodebuild -sdk iphonesimulator  -workspace TheCellar.xcworkspace -scheme "KiwiUnitTest" build SL_RUN_UNIT_TESTS=YES

# based on https://gist.github.com/3349345
# Thanks, @alloy!
#
# To get your project ready for this, you'll have to create a scheme for your unit test project, make sure run is checked in 
# the build step, and then delete the Test Host setting.
# Also, make sure you have the colored and open4 gems installed.

require 'rubygems'
require 'colored'
require 'pathname'
require 'open4'

# Change these to what is appropriate for your project
source_root = File.expand_path("../", __FILE__)

workspace = ARGV[0]
scheme = ARGV[1]

if !workspace || !scheme
  puts "Usage: run_unit_tests.rb [workspace.xcworkspace] [scheme name]"
  puts ""
  exit(1)
end


verbose = !!ARGV.delete("--verbose")


class TestOutput < Array
  def initialize(io, verbose, source_root)
    @io, @verbose, @source_root = io, verbose, Pathname.new(source_root)
  end

  def <<(line)
    return if !@verbose && line =~ /^Test Case/
      super
    @io << case line
    when /^Run test case/
      line.bold.white

    when /Test Suite '(.*)' started/
      "\n#{$1}:\n".blue
    when /.*\+\s+(.*)(\[PASSED\])/
      "[PASSED]".green+" #{$1.white}\n"
    when /\[PENDING\]/
      line.yellow
      # [DEBUG] /Users/ciryon/Documents/Coding/XCode/TheCellar/KiwiUnitTest/StorageSpec.m:144: error: -[StorageSpec Storage_WhenTheCellarContainsSixStorageNames_StorageLocationsShouldBeSortedAlphabetically] : 'Storage, when the cellar contains six storage names, storage locations should be sorted alphabetically' [FAILED], expected subject to equal "B storage", got "C storage"
    when /^(\[DEBUG\])*\s*\S+\/(\S+\.m)\:(\d+)\:.*\:\s+(.*)\s+(\[FAILED\]),\s+(.*)/
      #line.red
        "[FAILED]".red+" #{$2.white}:#{$3.white}: #{$4}:\n#{$6.capitalize}\n"
    when /^\[DEBUG\]\s+(.+?\.m)(:\d+:\s.+?)(\[FAILED\])(.*)/m
      if $1 == 'Unknown.m'
        line.red
      else
        "[FAILED] ".red+(Pathname.new($1).relative_path_from(@source_root).to_s + "#{$2.white}\n")+"\n#{$3.white}\n"
      end

    when /^=== BUILD/
      line
    when /^\*\*\s+BUILD FAILED/
      line.red
    when /.*Run script/
      "\n\n=== Starting Test Run...\n"

      # Executed 31 tests, with 0 failures (0 unexpected) in 2.698 (2.728) seconds
    when /Executed (\d+) tests, with (\d+) failures \((\d+) unexpected\) in (\S+) .*seconds$/
      if($2.to_i==0 && $3.to_i==0) 
        # Test success
        "Duration: #{$4} s\n\n".white
      else
        # Test failed
        "[Test suite failed]".red+"\nFailures: #{$2}\nUnexpected: #{$3}\nDuration: #{$4} si\n\n".white
      end
    when /\*\* BUILD SUCCEEDED \*\*/
      "\nAll OK!\n".green
    else
      #line
    end
    self
  end
end

puts "\n\n=== Cleaning up iOS Simulator app data...\n"
`rm -rf ~/Library/Application\ Support/iPhone\ Simulator/6.1/Applications/*`
puts "\n\n=== Building...\n"
cmd = "xcodebuild -workspace #{workspace} -scheme #{scheme} -sdk iphonesimulator TEST_AFTER_BUILD=YES ONLY_ACTIVE_ARCH=NO build SL_RUN_UNIT_TESTS=YES"
stdout =TestOutput.new(STDOUT, verbose, source_root)
stderr =TestOutput.new(STDERR, verbose, source_root)
status = Open4.spawn(cmd, :stdout => stdout, :stderr => stderr, :status => true)
exit status.exitstatus
