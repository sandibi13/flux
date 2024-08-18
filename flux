#!/bin/bash

tabs -4

export TEXTDOMAIN=flux
if [[ -n $FLUX_DEBUG ]]; then
    export TEXTDOMAINDIR="${PWD}/locale"
else
    export TEXTDOMAINDIR=/usr/share/locale
fi

# Colors
if [[ -z $NO_COLOR ]]; then
    export NC=$'\033[0m'
    export BGreen=$'\033[1;32m'
    export BCyan=$'\033[1;36m'
    export BYellow=$'\033[1;33m'
    export BPurple=$'\033[1;35m'
    export BRed=$'\033[1;31m'
    export BWhite=$'\033[1;37m'
fi

help_flag="USAGE: $(basename $0) [function] {flag} <input>

functions:
    install: Install package(s) - Prompts user to respond with
             the number(s) associated with the desired package(s).

    remove:  Uninstall package(s) - Prompts user to respond with
             the number(s) associated with the desired package(s).

    search:  Search for package(s) - Does not have a second prompt.

    update:  Updates all packages accessible to the wrapper - does
             not accept <input>, instead use install to update
             individual packages. Has a confirmation prompt.

    cleanup: Attempts to repair broken dependencies and remove any
             unused packages. Does not accept <input>, but has
             a confirmation prompt.

flags:
    --help/-h: Display this page

    --description/-d: By default, $(basename $0) will only display packages
    that contain <input> within their name. Use this flag to increase
    range and display packages with <input> in their description.

    -y: Makes functions with confirmation prompts run promptless.

input:
    Provide a package name or description.

Example execution:
    \$ $(basename $0) install foobar
    Found packages matching '${BPurple}foobar${NC}':

    [${BGreen}0${NC}]: pyfoobar (${BGreen}dnf${NC})
    [${BGreen}1${NC}]: foobarshell (${BGreen}dnf${NC})
    [${BCyan}2${NC}]: foobar (${BCyan}flatpak${NC})

    Select which package to install [0-2]: 0 1 2
    Selecting '${BGreen}pyfoobar${NC}' from package manager '${BGreen}dnf${NC}'
    Selecting '${BGreen}foobarshell${NC}' from package manager '${BGreen}dnf${NC}'
    Selecting '${BCyan}foobar${NC}' from package manager '${BCyan}flatpak${NC}'
    Are you sure? (${BGreen}y${NC}/${BRed}N${NC})
    [...]

    _____.__
  _/ ____\  |  __ _____  ___
  \   __\|  | |  |  \  \/  /
   |  |  |  |_|  |  />    <
   |__|  |____/____//__/\_ \
                          \/

$(basename "$0") 0.1.0
A package manager wrapper for DNF and Flatpak
Developed by sandibi13 <sandipanb223@gmail.com> for
Fedora Linux and Fedora Linux based distributions."

function msg() {
    local input="$*"
    echo -e "$input"
}

function prompt() {
    local input="$1"
    local index="$2"
    echo -ne "$input [0-$index]: ${BWhite}"
}

function clearscr() {
    tput cuu 1 && tput el
}

function search_dnf() {
    if [[ -z $DESCRIPTION ]]; then
        local contents=("$(dnf search --names-only "$*" | awk '{print $1}')")
    else
        local contents=("$(dnf search "$*" | awk '{print $1}')")
    fi
    if [[ -n $contents ]]; then
        echo "${contents[@]}"
    else
        return 1
    fi
}

function search_flatpak() {
    if [[ -z $DESCRIPTION ]]; then
        local contents=("$(LC_ALL=C sudo flatpak search --columns="application" "$*" | grep -i --color=never "$*")")
    else
        local contents=("$(LC_ALL=C sudo flatpak search --columns="application" "$*")")
    fi
    if [[ ${contents[*]} == "No matches found" ]]; then
        return 1
    else
        echo "${contents[@]}"
    fi
}

case "${1}" in
    search)
        SEARCH=true
        shift
        ;;
    install)
        INSTALL=true
        shift
        ;;
    remove)
        REMOVE=true
        shift
        ;;
    cleanup)
        CLEANUP=true
        shift
        if [[ $1 == "-y" ]]; then
            PROMPTLESS=true
            shift
        fi
        ;;
    update)
        UPDATE=true
        shift
        if [[ $1 == "-y" ]]; then
            PROMPTLESS=true
            shift
        fi
        ;;
    -h | --help)
        echo "$help_flag"
        exit 0
        ;;
    *)
        echo "$help_flag"
        exit 1
        ;;
esac

if [[ $1 == "-d" || $1 == "--description" ]]; then
    DESCRIPTION=true
    shift
fi

if [[ -n $UPDATE ]]; then
    if [[ -n $* ]]; then
        exit 1
    fi
    if [[ -z $PROMPTLESS ]]; then
        echo -n $"Are you sure you want to update all packages? (${BGreen}y${NC}/${BRed}N${NC}) "
        read -ra read_update
        echo -ne "${NC}"
    else
        read_update=("Y")
    fi
    case "${read_update[0]}" in
        Y* | y*) ;;
        *) exit 1 ;;
    esac
    if command -v dnf &> /dev/null; then
        if [[ -n $PROMPTLESS ]]; then
            sudo dnf check-update && sudo dnf upgrade -y
        else
            sudo apt check-update && sudo dnf upgrade
        fi
    fi
    if command -v flatpak &> /dev/null; then
        if [[ -n $PROMPTLESS ]]; then
            sudo flatpak update -y
        else
            sudo flatpak update
        fi
    fi
    exit 0
fi

if [[ -n $CLEANUP ]]; then
    if [[ -n $* ]]; then
        exit 1
    fi
    if [[ -z $PROMPTLESS ]]; then
        echo -n $"Attempting to repair dependencies and remove unused packages. Continue? (${BGreen}y${NC}/${BRed}N${NC}) "
        read -ra read_update
        echo -ne "${NC}"
    else
        read_update=("Y")
    fi
    case "${read_update[0]}" in
        Y* | y*) ;;
        *) exit 1 ;;
    esac
    if command -v dnf &> /dev/null; then
        if [[ -n $PROMPTLESS ]]; then
            sudo dnf check && sudo dnf autoremove -y
        else
            sudo dnf check && sudo dnf autoremove
        fi
    fi
    if command -v flatpak &> /dev/null; then
        if [[ -n $PROMPTLESS ]]; then
            sudo flatpak repair && sudo flatpak uninstall --unused -y
        else
            sudo flatpak repair && sudo flatpak uninstall --unused
        fi
    fi
    exit 0
fi

# Lowercase the rest of input
set -- "${*,,}"

if command -v dnf &> /dev/null; then
    msg $"Searching dnf…"
    dnf_search_list=($(search_dnf $*))
    clearscr
fi
if command -v flatpak &> /dev/null; then
    msg $"Searching flatpak…"
    flatpak_search_list=($(search_flatpak $*))
    clearscr
fi

if [[ ${#dnf_search_list} -eq 0 && ${#flatpak_search_list} -eq 0 ]]; then
    msg $"No packages found matching '$*'!"
    exit 1
fi

msg $"Found packages matching '${BPurple}$*${NC}':"
echo

count=0
pkgs=()
pkgrepo=()

for i in "${flatpak_search_list[@]}"; do
    echo -e "[${BCyan}$count${NC}]: $i (${BCyan}flatpak${NC})"
    pkgs+=("$i")
    pkgrepo+=("flatpak")
    ((count++))
done
for i in "${dnf_search_list[@]}"; do
    echo -e "[${BGreen}$count${NC}]: $i (${BGreen}apt${NC})"
    pkgs+=("$i")
    pkgrepo+=("dnf")
    ((count++))
done

((count--))

if [[ -n $SEARCH ]]; then
    exit 0
fi

echo

if [[ -n $INSTALL ]]; then
    flatpak_cmd="install"
    dnf_cmd="install"
    prompt $"Select which package to install" "$count"
elif [[ -n $REMOVE ]]; then
    flatpak_cmd="remove"
    dnf_cmd="remove"
    prompt $"Select which package to remove" "$count"
fi

read -ra entered_input
echo -ne "${NC}"
if ((count == 0)) && [[ -z ${entered_input[*]} ]]; then
    entered_input="0"
elif [[ ! ${entered_input[*]} =~ ^(([0-9])\s?)+ ]]; then
    msg $"'${entered_input[*]}' is not a valid number"
    exit 1
fi

for i in "${entered_input[@]}"; do
    msg $"Selecting '${BPurple}${pkgs[i]}${NC}' from package manager '${BPurple}${pkgrepo[i]}${NC}'"
done

echo -n $"Are you sure? (${BGreen}y${NC}/${BRed}N${NC}) "
read -r sure
case "${sure}" in
    Y* | y*)
        true
        ;;
    *)
        exit 1
        ;;
esac

for i in "${entered_input[@]}"; do
    case "${pkgrepo[i]}" in
        flatpak)
            sudo flatpak "${flatpak_cmd}" "${pkgs[i]}" -y
            ret=$?
            ;;
        apt)
            if command -v dnf &> /dev/null; then
                sudo dnf "${dnf_cmd}" "${pkgs[i]}" -y
                ret=$?
            fi
            ;;
        *)
            msg $"Invalid repository name!"
            exit 1
            ;;
    esac
done

exit "$ret"
