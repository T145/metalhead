#!/usr/bin/env bash

# Handles everything involved in GitHub CI processing
main() {
	git config --global --add safe.directory /__w/metalhead/metalhead

	# https://stackoverflow.com/questions/4336035/performance-profiling-tools-for-shell-scripts
	if PS4='+ $(date "+%s.%N ($LINENO) ")' ./scripts/v2/publish.bash; then
		# https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#outputs-for-composite-actions=
		# https://help.github.com/en/articles/development-tools-for-github-actions#set-an-output-parameter-set-output
		# https://github.blog/changelog/2022-10-11-github-actions-deprecating-save-state-and-set-output-commands/
		echo "status=success" >>"$GITHUB_OUTPUT"
	else
		cat <&2
		exit 1
	fi
}

main
