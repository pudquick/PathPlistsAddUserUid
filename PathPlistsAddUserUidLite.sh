#!/bin/bash

GetCaseState() {
    if [[ $(shopt -p nocasematch) == 'shopt -u nocasematch' ]]; then
        return 1
    fi
    return 0
}

SetCaseState() {
    if [[ $1 == 0 ]]; then
        shopt -s nocasematch
    else
        shopt -u nocasematch
    fi
}

PlistArrayContains() {
    # Args: 'plist path' 'key name in plist' 'value to search for'
    if [[ (! -a "$1") || (! -r "$1") || (! -w "$1") ]]; then
        echo "PlistArrayContains: Plist not present/readable/writable ($1)"
        return 2
    fi
    local _ArrayContents=$(/usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>&1)
    local _NoSuchKey='^Print: Entry, ".+", Does Not Exist$'
    if [[ ${_ArrayContents} =~ ${_NoSuchKey} ]]; then
        echo "PlistArrayContains: Plist present but key is missing ($2)"
        return 3
    fi
    GetCaseState
    local _OriginalCapsState=$?
    local _MatchState=1
    local _RegExMatch="^$3$"
    for _ArrayItem in ${_ArrayContents}; do
        if [[ ${_ArrayItem} =~ ${_RegExMatch} ]]; then
            _MatchState=0
        fi
    done
    SetCaseState ${_OriginalCapsState}
    return ${_MatchState}
}

PlistArrayAdd() {
    # Args: 'plist path' 'key name in plist' 'value to add'
    PlistArrayContains "$1" "$2" "$3"
    local _ContainsResult=$?
    if [[ $_ContainsResult > 1 ]]; then
        # Error other than 'not present' - pass it up
        return 1
    elif [[ $_ContainsResult = 0 ]]; then
        return 0
    fi
    /usr/libexec/PlistBuddy -c "Add :$2:0 string \"$3\"" "$1"
}

PlistAddShortnameUuid() {
    # Args: 'plist path' 'shortname' 'uuid'
    PlistArrayAdd "$1" 'users' "$2"
    local _AddResult=$?
    if [[ $_AddResult != 0 ]]; then
        return $_AddResult
    fi
    PlistArrayAdd "$1" 'groupmembers' "$3"
}
