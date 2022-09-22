#!/usr/bin/env bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# shellcheck disable=SC1091
source ./utils/test_config.sh

# https://en.wikipedia.org/wiki/Box-drawing_character#Box_Drawing
declare -r top_left="\u250f" horizontal="\u2501" top_right="\u2513" vertical="\u2503"
declare -r bottom_left="\u2517" bottom_right="\u251b"
declare red="\e[1;31m" green="\e[1;32m" yellow="\e[1;33m" reset="\e[0m"

# shellcheck disable=SC2034
declare -r aws_principal_arn="arn:aws:iam::123456789012:user/Alice"
# shellcheck disable=SC2034
declare -r aws_key_arn="arn:aws:kms:us-east-2:123456789012:/key/1234abcd-12ab-34cd-56ef-1234567890ab"
# shellcheck disable=SC2034
declare -r kms_via_service="ebs"

read -r -d '' json_body_with_empty_request_metadata <<EOM
{
    "requestMetadata": {
    }
}
EOM
# shellcheck disable=SC2034
declare -r json_body_with_empty_request_metadata

# Not thread safe
declare last_json_body

print_test_pass() {
    echo -e "${green}PASSED${reset} with expected response"
}

print_test_fail() {
    local -r reason="$1"
    echo -e "${red}FAILED${reset} $reason"
}

run_test() {
    local command

    print_header() {
        local -r message="$1"
        local -ir len=$(( ${#message} + 2 ))
        cat > /dev/stderr <<EOM

$(echo -e $top_left)$(eval "printf '$horizontal%.0s' {1..$len}")$(echo -e $top_right)
$(echo -e $vertical) $message $(echo -e $vertical)
$(echo -e $bottom_left)$(eval "printf '$horizontal%.0s' {1..$len}")$(echo -e $bottom_right)
EOM
    }

    # without the "--silent" parameter curl could fail on AL2 with large AAD and plaintext
    build_command() {
        local -r uri_target="$1" json_body="$2"
        local command
        cat <<-EOM
curl $SCHEME$XKS_PROXY_HOST/$URI_PREFIX/kms/xks/v1/$uri_target \\
    --silent $VERBOSE $SECURE $MTLS \\
    -H "Content-Type:application/json" \\
    --aws-sigv4 "aws:amz:$REGION:kms-xks-proxy" \\
    --user "$SIGV4_ACCESS_KEY_ID:$SIGV4_SECRET_ACCESS_KEY" \\
    --data-binary "\$(cat <<EOF
$json_body
EOF
)"
EOM
    }

    post() {
        local -r uri_target="$1" json_body="$2"
        command="$(build_command "$@")"

        if ((DEBUG)); then
            # shellcheck disable=SC2086
            cat > /dev/stderr <<EOM

$(echo -e $yellow)** Debugging - command to be run:

$command
$(echo -e $reset)
EOM
        fi

        eval "$command"
    }

    local -r uri_target=$1 json_body=$2 label=$3 expected=$4 delay_judgement=$5
    print_header "Testing $label ..."

    echo "Request body ..."
    jq <<< "$json_body"
    echo -e "${reset}"

    # shellcheck disable=SC2207
    local -r response="$(post "$uri_target" "$json_body" 2>&1)"
    local -a arr
    readarray -t arr <<<"$response"
    local -ir n=${#arr[@]}
    for ((i=0; i<n-1; i++)); do
        echo "${arr[i]}"
    done

    echo -e "${reset}\nResponse body ..."
    last_json_body="${arr[n-1]}"
    if [[ "$last_json_body" =~ ^\{.*\}$ ]]; then
        jq <<< "$last_json_body"
    else
        echo "$last_json_body"
    fi
    echo -en "${reset}\n=> Test $label "

    # shellcheck disable=SC2128
    if [[ "$response" =~ .*${expected}.* ]]; then
        ((delay_judgement)) || print_test_pass
        return 0
    else
        print_test_fail "with unexpected response"
        return 1
    fi
}

summarize() {
    local -ir success=$1 failure=$2
    if ((failure)); then
        if ((success)); then
            echo -e "\nA total of $green$success tests PASSED$reset and $red$failure tests FAILED$reset."
        else
            echo -e "\n${red}All ${failure} tests FAILED.${reset}"
        fi
    else
        echo -e "\n${green}All ${success} tests PASSED.${reset}"
    fi
}

abort() {
    echo "$*" > /dev/stderr
    exit 1
}

check_environment() {
    check_min_version() {
        local -r cmd="$1"

        local min_version_arr
        IFS='.' read -ra min_version_arr <<< "$2"
        local -ir min_major=${min_version_arr[0]} min_minor=${min_version_arr[1]}

        local -r extract_version_cmd="$3"

        if ! which "$cmd" > /dev/null; then
            abort "Please install $cmd $min_major.$min_minor or later for use with this test client."
        fi

        local version_arr
        IFS='.' read -ra version_arr <<< "$(eval "$extract_version_cmd")"
        local -ir major=${version_arr[0]} minor=${version_arr[1]}

        ((DEBUG)) && echo "$cmd $major.$minor is available ..." > /dev/stderr
        if (( major < min_major || major == min_major && minor < min_minor )); then
            abort "Please install $cmd $min_major.$min_minor or later for use with this test client."
        fi
    }

    local cmd
    for cmd in awk base64 head mktemp printf read sed sha256sum tr xxd; do
        if which $cmd > /dev/null; then
            ((DEBUG)) && echo "$cmd is available ..." > /dev/stderr
        else
            abort "Please install $cmd for use with this test client."
        fi
    done

    check_min_version "bash" "4.2" \
        "bash --version | head -1 | sed -e 's/.*version \([0-9]*.[0-9]*\).*/\1/'"
    check_min_version "curl" "7.75" \
        "curl --version | head -1 | sed -e 's/^curl \([0-9]*.[0-9]*\).*/\1/'"
    check_min_version "jq"   "1.5" \
        "jq --version | head -1 | sed -e 's/^jq-\([0-9]*.[0-9]*\).*/\1/'"
}
