#!/usr/bin/env bash

# shellcheck disable=SC2154
request_metadata() {
    local -r kms_operation=$1
    local -r uuid="$(uuidgen)"
    cat <<-EOM
    "requestMetadata": {
        "awsPrincipalArn": "$aws_principal_arn",
        "kmsKeyArn": "$aws_key_arn",
        "kmsOperation": "$kms_operation",
        "kmsRequestId": "${uuid,,}",
        "kmsViaService": "$kms_via_service"
    }
EOM
}

aad_json_entry() {
    local -r aad="$1"
    cat <<EOM
"additionalAuthenticatedData": "$aad",
EOM
}

plaintext_json_entry() {
    local -r plaintext="$1"
    cat <<EOM
"plaintext": "$plaintext",
EOM
}

cdiv_algo_json_entry() {
    local -r cdiv_algo="$1"
    cat <<EOM
"ciphertextDataIntegrityValueAlgorithm": "$cdiv_algo",
EOM
}

json_body_encrypt() {
    local -r request_metadata="$1"

    local plaintext_entry=""
    (($# > 1)) && plaintext_entry="$(plaintext_json_entry "$2")"

    local aad_entry=""
    (($# > 2 && ${#3} > 0)) && aad_entry="$(aad_json_entry "$3")"

    local cdiv_algo_entry=""
    (($# > 3)) && cdiv_algo_entry="$(cdiv_algo_json_entry "$4")"

    cat <<-EOM
{
$request_metadata,
    $aad_entry
    $plaintext_entry
    $cdiv_algo_entry
    "encryptionAlgorithm": "AES_GCM"
}
EOM
}

declare ciphertext iv tag ciphertext_metadata

json_body_decrypt() {
    local -r request_metadata="$1" ciphertext="$2" iv="$3" tag="$4"

    local aad_entry=""
    (($# > 4)) && aad_entry="$(aad_json_entry "$5")"
    if [[ "$ciphertext_metadata" == "null" ]]; then
        cat <<-EOM
{
$request_metadata,
    $aad_entry
    "ciphertext": $ciphertext,
    "initializationVector": $iv,
    "authenticationTag": $tag,
    "encryptionAlgorithm": "AES_GCM"
}
EOM
    else
        cat <<-EOM
{
$request_metadata,
    $aad_entry
    "ciphertext": $ciphertext,
    "initializationVector": $iv,
    "authenticationTag": $tag,
    "ciphertextMetadata": $ciphertext_metadata,
    "encryptionAlgorithm": "AES_GCM"
}
EOM
    fi
}

prepare_decrypt() {
    # shellcheck disable=SC2154
    ciphertext=$(jq ".ciphertext"<<<"$last_json_body")
    iv=$(jq ".initializationVector"<<<"$last_json_body")
    tag=$(jq ".authenticationTag"<<<"$last_json_body")
    ciphertext_metadata=$(jq ".ciphertextMetadata"<<<"$last_json_body")
}

remove_quotes() {
    local temp="${1%\"}"
    temp="${temp#\"}"
    echo "$temp"
}

# Extract a binary field value from $last_json_body into a temporary file.
# We use file to get around the limitation that bash variable cannot handle null values.
extract_binary_field_to_file() {
    local -r field_name=$1
    local -r field_value=$(jq ".$field_name"<<<"$last_json_body")
    if [[ "$field_value" == "null" ]]; then
        # no such field
        echo -n "" > "$tmpdir/$field_name"
    else
        local -r b64=$(remove_quotes "$field_value")
        base64 -d <<<"$b64" > "$tmpdir/$field_name"
    fi
}

size_of_binary() {
    local -r field_name=$1
    wc -c "$tmpdir/$field_name" | awk '{print $1}'
}

# [<AAD> ||] [<Ciphertext Metadata> ||] <IV> || <Ciphertext> || <Authentication Tag>
build_cdiv_input_binary() {
    cat "$tmpdir/additionalAuthenticatedData" > "$tmpdir/cdiv_input"
    {
        cat "$tmpdir/ciphertextMetadata";
        cat "$tmpdir/initializationVector";
        cat "$tmpdir/ciphertext";
        cat "$tmpdir/authenticationTag"
    } >> "$tmpdir/cdiv_input"
}

verify_cdiv() {
    local -r debug_cdiv=0
    local -r aad_b64="$1"
    if ((${#aad_b64} == 0)); then
        echo -n "" > "$tmpdir/additionalAuthenticatedData"
    else
        base64 -d <<<"$aad_b64" > "$tmpdir/additionalAuthenticatedData"
    fi
    ((debug_cdiv)) && echo "binary additionalAuthenticatedData len: $(size_of_binary additionalAuthenticatedData)"
    extract_binary_field_to_file "ciphertext"
    ((debug_cdiv)) && echo "binary ciphertext len: $(size_of_binary ciphertext)"
    extract_binary_field_to_file "ciphertextMetadata"
    ((debug_cdiv)) && echo "binary ciphertextMetadata len: $(size_of_binary ciphertextMetadata)"
    extract_binary_field_to_file "initializationVector"
    ((debug_cdiv)) && echo "binary initializationVector len: $(size_of_binary initializationVector)"
    extract_binary_field_to_file "authenticationTag"
    ((debug_cdiv)) && echo "binary authenticationTag len: $(size_of_binary authenticationTag)"
    build_cdiv_input_binary
    ((debug_cdiv)) && echo "binary cdiv_input len: $(size_of_binary cdiv_input)"
    local -r cdiv_computed_hex=$(sha256sum "$tmpdir/cdiv_input" | awk '{print $1}')
    ((debug_cdiv)) && echo "cdiv_computed_hex: $cdiv_computed_hex"
    local -r cdiv_response=$(remove_quotes "$(jq ".ciphertextDataIntegrityValue"<<<"$last_json_body")")
    local -r cdiv_response_hex=$(base64 -d <<<"$cdiv_response" | xxd -p | tr -d '\n')
    ((debug_cdiv)) && echo "cdiv_response_hex: $cdiv_response_hex"
    if [[ "$cdiv_computed_hex" == "$cdiv_response_hex" ]]; then
        return 0
    else
        return 1
    fi
}
