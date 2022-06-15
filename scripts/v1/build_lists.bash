#!/usr/bin/env bash

main() {
    curl --proto '=https' --tlsv1.3 -H 'Accept: application/vnd.github.v3+json' -sSf https://api.github.com/repos/T145/black-mirror/releases/latest |
        jq -r '.assets[] | select(.name | endswith("txt")).browser_download_url' |
        aria2c -i- -d ./assets --conf-path='./configs/aria2.conf'

    # Max thread count is 204822, as given by `cat /proc/sys/kernel/threads-max`
    # https://askubuntu.com/questions/1006377/check-the-max-allowed-threads-count-for-sure#1006384
    # TODO: Perform these steps for each list!
    if test -f './dist/black_nxdomain.txt'; then
        dnsx -r ./configs/resolvers.txt -hf ./dist/black_nxdomain.txt -l ./assets/black_domain*.txt -o ./assets/black_nxdomain.txt -c 200000 -silent -rcode nxdomain 1>/dev/null
        mawk '{print $1}' ./assets/black_nxdomain.txt | comm ./dist/black_nxdomain.txt - -13 >>./dist/black_nxdomain.txt
    else
        dnsx -r ./configs/resolvers.txt -l ./assets/black_domain*.txt -o ./assets/black_nxdomain.txt -c 200000 -silent -rcode nxdomain 1>/dev/null
    fi

    rm -rf ./assets/*.txt
}

main
