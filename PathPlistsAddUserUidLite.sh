#!/bin/bash

PlistArrayContains() {
    # Args: 'plist path' 'key name in plist' 'value to search for'
    if [[ $# != 3 ]]; then
        echo "PlistArrayContains: Incorrect number of arguments passed (#: $#) - Passed: $@"
        return 2
    fi
    if [[ (! -r "$1") || (! -w "$1") ]]; then
        echo "PlistArrayContains: Plist not readable and/or writable ($1)"
        return 3
    fi
    /usr/libexec/PlistBuddy -c "Print :$2" "$1" | /usr/bin/grep -qi "^    $3$"
}

PlistArrayAdd() {
    # Args: 'plist path' 'key name in plist' 'value to add'
    if [[ $# != 3 ]]; then
        echo "PlistArrayAdd: Incorrect number of arguments passed (#: $#) - Passed: $@"
        return 1
    fi
    PlistArrayContains "$1" "$2" "$3"
    if [[ $? > 1 ]]; then
        # Error other than 'not present' - pass it up
        return 1
    elif [[ $? == 0 ]]; then
        # Already present, no need to do the work
        return 0
    fi
    /usr/libexec/PlistBuddy -c "Add :$2:0 string \"$3\"" "$1"
}

PlistAddUserUid() {
    # Args: 'plist path' 'shortname' 'uid'
    if [[ $# != 3 ]]; then
        echo "PlistAddUserUid: Incorrect number of arguments passed (#: $#) - Passed: $@"
        return 1
    fi
    PlistArrayAdd "$1" 'users' "$2"
    if [[ $? != 0 ]]; then
        return $?
    fi
    PlistArrayAdd "$1" 'groupmembers' "$3"    
}
