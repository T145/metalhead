#!/usr/bin/env bash

main() {
    git config --global --add safe.directory /__w/metalhead/metalhead

    if ./scripts/v1/build_lists.bash; then
        echo "status=success" >>"$GITHUB_OUTPUT"
    else
        cat <&2
		exit 1
    fi
}

main
