#!/usr/bin/env bash

main() {
    local result

    git config --global --add safe.directory /__w/black-mirror/black-mirror
    ./scripts/v1/build_lists.bash

    [[ "$?" = 0 ]] && result='success' || result='failure'

    # https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#outputs-for-composite-actions=
    # https://help.github.com/en/articles/development-tools-for-github-actions#set-an-output-parameter-set-output
    echo "::set-output name=status::${result}"
}

main
