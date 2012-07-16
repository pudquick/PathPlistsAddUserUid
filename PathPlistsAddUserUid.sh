#!/bin/bash

# Executables required: /bin/bash, /usr/libexec/PlistBuddy, /usr/bin/sed, /usr/bin/grep
# /usr/bin/logger is also used for debugging, but those lines can be removed / are not required
#
# Example usage:
# PathPlistsAddUserUid '/private/var/db/dslocal/nodes/Default/groups' 'admin,wheel' 'bob' 'ABCDEFAB-CDEF-0000-0000-000000000000'

PlistArrayContains() {
    # 1.) Location of plist file
    # 2.) Array name to search
    # 3.) String to search for (treated case insensitive)
    if [[ $# != 3 ]]; then
        /usr/bin/logger "CreateUserPkg: PlistArrayContains: Incorrect number of arguments passed (#: $#)"
        /usr/bin/logger "CreateUserPkg: PlistArrayContains: Passed: $@"
        exit 1
    fi
    local _PlistPath="$1"
    local _KeyName="$2"
    local _SearchString="$3"
    if [[ ! -r "${_PlistPath}" ]]; then
        /usr/bin/logger "CreateUserPkg: PlistArrayContains: Plist not readable (${_PlistPath})"
        exit 1
    fi
    /usr/libexec/PlistBuddy -c "Print :${_KeyName}" "${_PlistPath}" | /usr/bin/sed -e '1d' -e '$d' | /usr/bin/grep -qi "^    ${_SearchString}$"
}

PlistArrayAdd() {
    # 1.) Location of plist file
    # 2.) Array name to modify
    # 3.) String to add
    if [[ $# != 3 ]]; then
        /usr/bin/logger "CreateUserPkg: PlistArrayAdd: Incorrect number of arguments passed (#: $#)"
        /usr/bin/logger "CreateUserPkg: PlistArrayAdd: Passed: $@"
        exit 1
    fi
    PlistArrayContains "$1" "$2" "$3"
    if [[ $? == 0 ]]; then
        # echo "Already present"
        return 0
    fi
    local _PlistPath="$1"
    local _KeyName="$2"
    local _AddString="$3"
    if [[ ! -w "${_PlistPath}" ]]; then
        /usr/bin/logger "CreateUserPkg: PlistArrayAdd: Plist not writable (${_PlistPath})"
        exit 1
    fi
    /usr/libexec/PlistBuddy -c "Add :${_KeyName}:0 string \"${_AddString}\"" "${_PlistPath}"
}

PlistAddUserUid() {
    # 1.) Location of plist file
    # 2.) Username to add to 'users' array
    # 3.) Uid to add to 'groupmembers' array
    if [[ $# != 3 ]]; then
        /usr/bin/logger "CreateUserPkg: PlistAddUserUid: Incorrect number of arguments passed (#: $#)"
        /usr/bin/logger "CreateUserPkg: PlistAddUserUid: Passed: $@"
        exit 1
    fi
    local _PlistPath="$1"
    local _User="$2"
    local _Uid="$3"
    PlistArrayAdd "${_PlistPath}" 'users' "${_User}"
    if [[ $? == 0 ]]; then
        PlistArrayAdd "${_PlistPath}" 'groupmembers' "${_Uid}"
        if [[ $? == 0 ]]; then
            return 0
        else
            /usr/bin/logger "CreateUserPkg: PlistAddUserUid: Unknown error modifying groupmembers"
            /usr/bin/logger "CreateUserPkg: PlistAddUserUid: Passed: $@"
            exit 1
        fi
    fi
    /usr/bin/logger "CreateUserPkg: PlistAddUserUid: Unknown error modifying users"
    /usr/bin/logger "CreateUserPkg: PlistAddUserUid: Passed: $@"
    exit 1
}

PathPlistsAddUserUid() {
    # 1.) Path to plist files (/private/var/db/dslocal/nodes/Default/groups)
    # 2.) Comma (no spaces) delimited list of plist file names (without .plist suffix)
    # 3.) Username to add to 'users' array in each plist file
    # 4.) Uid to add to 'groupmembers' array in each plist file
    if [[ $# != 4 ]]; then
        /usr/bin/logger "CreateUserPkg: PathPlistsAddUserUid: Incorrect number of arguments passed (#: $#)"
        /usr/bin/logger "CreateUserPkg: PathPlistsAddUserUid: Passed: $@"
        exit 1
    fi
    local _BasePath="$1"
    local _Plists="$2"
    local _User="$3"
    local _Uid="$4"
    if [[ ! -d "${_BasePath}" ]]; then
        /usr/bin/logger "CreateUserPkg: PathPlistsAddUserUid: Base plist path not found (${_BasePath})"
        exit 1
    fi
    for _Pfile in $(echo "${_Plists}.plist" | /usr/bin/sed 's/,/.plist /g'); do
        PlistAddUserUid "${_BasePath}/${_Pfile}" "${_User}" "${_Uid}"
    done
}
