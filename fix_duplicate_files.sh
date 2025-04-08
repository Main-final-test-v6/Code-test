#!/bin/bash

# Script to fix duplicate file references in Xcode project causing build errors
# This script:
# 1. Removes symbolic links
# 2. Removes duplicate file references from project.pbxproj
# 3. Adds direct file references pointing to the correct locations
# 4. Updates groups and build phases

echo "Starting project file fix process..."

# Step 1: Remove symbolic links
echo "Removing symbolic links..."
rm -f iOS/Views/Settings/AILearningSettingsViewController.swift
rm -f iOS/Views/Settings/ImprovedLearningSettingsCell.swift
rm -f iOS/Views/Settings/ImprovedLearningViewController.swift
rm -f iOS/Views/Settings/ModelServerIntegrationViewController.swift
rm -f iOS/Views/Settings/ModelServerIntegrationViewController+SafeAsync.swift
rm -f iOS/Views/Settings/SettingsHeaderTableViewCell.swift

# Step 2: Backup and clean up project.pbxproj
PROJ_FILE="backdoor.xcodeproj/project.pbxproj"
FINAL_BACKUP="backdoor.xcodeproj/project.pbxproj.before_fixes"

# Make a final backup of the original file
cp "$PROJ_FILE" "$FINAL_BACKUP"

echo "Cleaning project.pbxproj file..."

# Step 3: Remove PBXFileSystemSynchronizedBuildFileExceptionSet sections
awk '
BEGIN { 
    in_exception_set = 0;
    skip_line = 0;
}

/\/\* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section \*\// { 
    in_exception_set = 1;
    skip_line = 1;
}

/\/\* End PBXFileSystemSynchronizedBuildFileExceptionSet section \*\// { 
    in_exception_set = 0;
    skip_line = 1;
}

!skip_line && !in_exception_set { 
    print;
}

{
    skip_line = 0;
}
' "$FINAL_BACKUP" > "$PROJ_FILE"

echo "Adding direct file references..."

# Step 4: Create a temporary file for our manipulations
TEMP_FILE="backdoor.xcodeproj/project.pbxproj.temp"
cp "$PROJ_FILE" "$TEMP_FILE"

# Step 5: Add file references to the PBXFileReference section
awk '
BEGIN {
    inserted = 0;
}

/\/\* Begin PBXFileReference section \*\// {
    print;
    if (!inserted) {
        print "\t\t33FD1001 /* AILearningSettingsViewController.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \"AI Learning/AILearningSettingsViewController.swift\"; sourceTree = \"<group>\"; };";
        print "\t\t33FD1002 /* ImprovedLearningSettingsCell.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \"AI Learning/ImprovedLearningSettingsCell.swift\"; sourceTree = \"<group>\"; };";
        print "\t\t33FD1003 /* ImprovedLearningViewController.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \"AI Learning/ImprovedLearningViewController.swift\"; sourceTree = \"<group>\"; };";
        print "\t\t33FD1004 /* ModelServerIntegrationViewController.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \"AI Learning/ModelServerIntegrationViewController.swift\"; sourceTree = \"<group>\"; };";
        print "\t\t33FD1005 /* ModelServerIntegrationViewController+SafeAsync.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \"AI Learning/ModelServerIntegrationViewController+SafeAsync.swift\"; sourceTree = \"<group>\"; };";
        print "\t\t33FD1006 /* SettingsHeaderTableViewCell.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \"About/SettingsHeaderTableViewCell.swift\"; sourceTree = \"<group>\"; };";
        inserted = 1;
    }
    next;
}

{ print; }
' "$TEMP_FILE" > "$PROJ_FILE"
cp "$PROJ_FILE" "$TEMP_FILE"

echo "Adding files to groups..."

# Step 6: Add file references to appropriate groups
awk '
BEGIN {
    updated_settings_group = 0;
}

# Find the Settings group and add the files
/isa = PBXGroup;/ && !updated_settings_group && $0 ~ /children =/ {
    updated_settings_group = 1;
    print $0;
    print "\t\t\t\t33FD1001 /* AILearningSettingsViewController.swift */,";
    print "\t\t\t\t33FD1002 /* ImprovedLearningSettingsCell.swift */,";
    print "\t\t\t\t33FD1003 /* ImprovedLearningViewController.swift */,";
    print "\t\t\t\t33FD1004 /* ModelServerIntegrationViewController.swift */,";
    print "\t\t\t\t33FD1005 /* ModelServerIntegrationViewController+SafeAsync.swift */,";
    print "\t\t\t\t33FD1006 /* SettingsHeaderTableViewCell.swift */,";
    next;
}

{ print; }
' "$TEMP_FILE" > "$PROJ_FILE"
cp "$PROJ_FILE" "$TEMP_FILE"

echo "Adding files to build phases..."

# Step 7: Add file references to compile sources build phase
awk '
BEGIN {
    updated_sources = 0;
}

# Find the Sources build phase and add the files
/isa = PBXSourcesBuildPhase;/ && !updated_sources {
    in_sources = 1;
    print;
    next;
}

in_sources && $0 ~ /files = \(/ {
    updated_sources = 1;
    print $0;
    print "\t\t\t\t33FD1001 /* AILearningSettingsViewController.swift in Sources */,";
    print "\t\t\t\t33FD1002 /* ImprovedLearningSettingsCell.swift in Sources */,";
    print "\t\t\t\t33FD1003 /* ImprovedLearningViewController.swift in Sources */,";
    print "\t\t\t\t33FD1004 /* ModelServerIntegrationViewController.swift in Sources */,";
    print "\t\t\t\t33FD1005 /* ModelServerIntegrationViewController+SafeAsync.swift in Sources */,";
    print "\t\t\t\t33FD1006 /* SettingsHeaderTableViewCell.swift in Sources */,";
    next;
}

/\);/ && in_sources {
    in_sources = 0;
    print;
    next;
}

{ print; }
' "$TEMP_FILE" > "$PROJ_FILE"

# Clean up temporary files
rm -f "$TEMP_FILE"

echo "Project file fix complete!"
echo "Make sure to clean your build folder and derived data before rebuilding."
