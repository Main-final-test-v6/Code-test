#!/bin/bash

# Script to clean derived data before building
# Run this before building to avoid "multiple commands produce" errors

echo "Cleaning build cache and derived data..."

# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/backdoor-*

# Clean build directory
xcodebuild clean -project backdoor.xcodeproj -scheme "backdoor (Debug)" -configuration Debug
xcodebuild clean -project backdoor.xcodeproj -scheme "backdoor (Release)" -configuration Release

echo "Clean complete. Now you can build the project."
