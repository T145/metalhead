#!/usr/bin/env bash

#shopt -s extdebug     # or --debugging
set +H +o history     # disable history features (helps avoid errors from "!" in strings)
shopt -u cmdhist      # would be enabled and have no effect otherwise
shopt -s execfail     # ensure interactive and non-interactive runtime are similar
shopt -s extglob      # enable extended pattern matching (https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html)
set -euET -o pipefail # put bash into "strict mode" & have it give descriptive errors
umask 055             # change all generated file permissions from 755 to 700

OUTDIR='assets'
DOWNLOADS=$(mktemp -d)
TMP=$(mktemp)
ERROR_LOG='logs/error.log'
JOB_LOG='logs/jobs.log'
NXLIST='./dist/BLOCK_NXDOMAIN.txt'
TARGET='./assets/BLOCK_DOMAIN.txt'
readonly OUTDIR DOWNLOADS TMP ERROR_LOG JOB_LOG

# https://github.com/ildar-shaimordanov/perl-utils#sponge
sponge() {
	perl5.41.1 -ne '
	push @lines, $_;
	END {
		open(OUT, ">$file")
		or die "sponge: cannot open $file: $!\n";
		print OUT @lines;
		close(OUT);
	}
	' -s -- -file="$1"
}

# params: file to sort,
sorted() {
	parsort -bfiu -S 100% -T "$DOWNLOADS" "$1" | sponge "$1"
	echo "[INFO] Organized: ${1}"
}

# merge list 2 into list 1
# params: list 1, list 2
# merge_lists() {
# 	cat "$1" "$2" >"$1"
# 	sorted "$1"
# }

main() {
	trap 'rm -rf "$TMP"' EXIT || exit 1
	mkdir -p "$OUTDIR"
	# clear all logs
	#find -P -O3 ./logs -depth -type f -print0 | xargs -0 truncate -s 0
	chmod -t /tmp

	curl --proto '=https' --tlsv1.3 -H 'Accept: application/vnd.github.v3+json' -sSf https://api.github.com/repos/T145/black-mirror/releases/latest |
		jaq -r '.assets[] | select(.name | startswith("BLOCK_DOMAIN")) | select(.name | endswith(".txt")).browser_download_url' |
		aria2c -i- -d "$OUTDIR"

	split -d -l 500000 --additional-suffix .txt "$TARGET" "${OUTDIR}/BLOCK_DOMAIN_"
	rm "$TARGET"
	find -P -O3 "$OUTDIR" -type f -name *.txt -exec sem dnsx -l {} -o "{}2" -silent -rcode nxdomain 1>/dev/null \;
	sem --wait

	# Max thread count is 204822, as given by `cat /proc/sys/kernel/threads-max`
	# https://askubuntu.com/questions/1006377/check-the-max-allowed-threads-count-for-sure#1006384
	# TODO: Perform these steps for each list!
	# if [ -f "$NXLIST" ]; then
	# 	# TODO: Export JSON from dnsX and use jq to pull out domains & ips
	# 	dnsx -r ./configs/resolvers.txt -l "$NXLIST" -o "$TMP" -c 20000 -silent -rcode noerror,servfail,refused 1>/dev/null
	# 	merge_lists "$TARGET" "$TMP"
	# 	# nxlist should be small enough that parallel isn't needed
	# 	grep -Fxvf "$TMP" "$NXLIST" | sponge "$NXLIST"
	# 	dnsx -r ./configs/resolvers.txt -hf "$NXLIST" -l "$TARGET" -o "$NXLIST" -c 20000 -silent -rcode nxdomain 1>/dev/null
	# 	: >"$TMP"
	# else
	# 	dnsx -r ./configs/resolvers.txt -l "$TARGET" -o "$NXLIST" -c 20000 -silent -rcode nxdomain 1>/dev/null
	# fi

	mawk '{print $1}' "${OUTDIR}/BLOCK_DOMAIN_*.txt2" | sponge "$NXLIST"
	sorted "$NXLIST"
	rm -rf "$OUTDIR"

	chmod +t /tmp
}

# https://github.com/koalaman/shellcheck/wiki/SC2218
main
