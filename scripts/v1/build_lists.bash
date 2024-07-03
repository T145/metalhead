#!/usr/bin/env bash

TMP=$(mktemp)
readonly TMP
trap 'rm -rf "$TMP"' EXIT || exit 1

# https://github.com/ildar-shaimordanov/perl-utils#sponge
sponge() {
	perl -ne '
	push @lines, $_;
	END {
		open(OUT, ">$file")
		or die "sponge: cannot open $file: $!\n";
		print OUT @lines;
		close(OUT);
	}
	' -s -- -file="$1"
}

# params: file path
sorted() {
  parsort -bfiu -S 100% -T "$DOWNLOADS" "$1" | sponge "$1"
}

# merge list 2 into list 1
# params: list 1, list 2
merge_lists() {
  cat "$1" "$2" >"$1"
  sorted "$1"
}

main() {
  curl --proto '=https' --tlsv1.3 -H 'Accept: application/vnd.github.v3+json' -sSf https://api.github.com/repos/T145/black-mirror/releases/latest |
    jaq -r '.assets[] | select(.name | endswith("txt")).browser_download_url' |
    aria2c -i- -d ./assets --conf-path='./configs/aria2.conf'

  local nxlist
  local list

  nxlist='./dist/BLOCK_NXDOMAIN.txt'
  list='./assets/BLOCK_DOMAIN.txt'

  # Max thread count is 204822, as given by `cat /proc/sys/kernel/threads-max`
  # https://askubuntu.com/questions/1006377/check-the-max-allowed-threads-count-for-sure#1006384
  # TODO: Perform these steps for each list!
  if test -f "$nxlist"; then
    # TODO: Export JSON from dnsX and use jq to pull out domains & ips
    dnsx -r ./configs/resolvers.txt -l "$nxlist" -o "$TMP" -c 200000 -silent -rcode noerror,servfail,refused 1>/dev/null
    merge_lists "$list" "$TMP"
    # nxlist should be small enough that parallel isn't needed
    grep -Fxvf "$TMP" "$nxlist" | sponge "$nxlist"
    dnsx -r ./configs/resolvers.txt -hf "$nxlist" -l "$list" -o "$nxlist" -c 200000 -silent -rcode nxdomain 1>/dev/null
    : >"$TMP"
  else
    dnsx -r ./configs/resolvers.txt -l "$list" -o "$nxlist" -c 200000 -silent -rcode nxdomain 1>/dev/null
  fi

  rm -rf ./assets/*.txt
}

main
