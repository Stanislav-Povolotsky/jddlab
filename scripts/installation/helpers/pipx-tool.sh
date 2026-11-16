#!/bin/bash
# Shared installer for Python CLI tools that get their own isolated pipx venv
# (instead of the shared /usr/local/python-venv), so that their pinned
# dependencies can't break other tools (e.g. quark-engine pins androguard).
#
# Sourced by install scripts. Usage:
#   pipx_tool <pkg> <pip_pkg> <home_page> <cmd> [<cmd>...]
# The first <cmd> is used for the "--help" sanity check during the build.
# Version comes from PyPI in both build modes, so the version-collection build
# reports exactly what the full build installs.

pipx_tool() {
    local pkg=$1 pip_pkg=$2 home_page=$3
    shift 3
    local cmds="$*"
    local first_cmd=$1
    local pkg_path=$target_install_path/usr/local/$pkg
    local bin_path=$target_install_path/usr/local/bin
    local pkg_info=$pkg_path/$pkg.software_version.txt
    mkdir -p $pkg_path $bin_path

    local version
    version=$(curl -sfL "https://pypi.org/pypi/$pip_pkg/json" | jq -r .info.version)
    if [ -z "$version" ] || [ "$version" == "null" ]; then
        echo "ERROR: couldn't determine the latest PyPI version of $pip_pkg"
        return 1
    fi

    echo "$version"           >$pkg_info
    echo "$home_page"         >>$pkg_info
    echo "$pip_pkg==$version" >>$pkg_info
    echo "https://pypi.org/project/$pip_pkg/$version" >>$pkg_info

    if [[ "$versions_collect_mode" == "0" ]]; then
        # Installation mode
        pipx install "$pip_pkg==$version"
        for cmd in $cmds; do
            # PIPX_BIN_DIR is moved to the same absolute path in the final image (99.venv-move.sh)
            ln -s $PIPX_BIN_DIR/$cmd $bin_path/$cmd
        done

        # Checking it can be runned
        $PIPX_BIN_DIR/$first_cmd --help 2>&1 | tee -a $pkg_path/$first_cmd.command_help.txt
        local rc=${PIPESTATUS[0]}
        if [[ $rc -ne 0 && $rc -ne 1 ]]; then
            echo "ERROR: $first_cmd --help failed with code $rc"
            cat $pkg_path/$first_cmd.command_help.txt
            return $rc
        fi
    fi
}
