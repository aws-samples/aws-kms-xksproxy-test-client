#!/usr/bin/env bash

declare -i success=0 failure=0

main() {
    local -r key_id="$1"
    local -r plaintext="cGxhaW50ZXh0Cg=="
    local -r aad="cHJvamVjdD1uaWxlLGRlcGFydG1lbnQ9bWFya2V0aW5n"

    if run_test "keys/$key_id/encrypt" \
        "$(json_body_encrypt "$(request_metadata "Encrypt")" "$plaintext" $aad)" \
        "Encrypt with AAD using \"$key_id\"" \
        "InvalidKeyUsageException"; then
        ((++success))
    else
        ((++failure))
    fi

    if run_test "keys/$key_id/encrypt" \
        "$(json_body_encrypt "$(request_metadata "Encrypt")" "$plaintext")" \
        "Encrypt without AAD using \"$key_id\"" \
        "InvalidKeyUsageException"; then
        ((++success))
    else
        ((++failure))
    fi

    if run_test "keys/$key_id/encrypt" \
        "$(json_body_encrypt "$(request_metadata "Encrypt")" "$plaintext" $aad "SHA_256")" \
        "Encrypt with AAD and CDIV using \"$key_id\"" \
        "InvalidKeyUsageException"; then
        ((++success))
    else
        ((++failure))
    fi

    if run_test "keys/$key_id/encrypt" \
        "$(json_body_encrypt "$(request_metadata "Encrypt")" "$plaintext" "" "SHA_256")" \
        "Encrypt with CDIV but without AAD using \"$key_id\"" \
        "InvalidKeyUsageException"; then
        ((++success))
    else
        ((++failure))
    fi
}
