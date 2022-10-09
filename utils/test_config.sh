#!/usr/bin/env bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

declare -r DEFAULT_SCHEME="https://"
declare -r DEFAULT_XKS_PROXY_HOST=""
declare -r DEFAULT_URI_PREFIX="example/uri/path/prefix"
declare -r DEFAULT_REGION="us-east-1"
declare -r DEFAULT_KEY_ID="foo"
declare -r DEFAULT_ENCRYPT_ONLY_KEY_ID="encrypt_only_key"
declare -r DEFAULT_DECRYPT_ONLY_KEY_ID="decrypt_only_key"
declare -r DEFAULT_IMPOTENT_KEY_ID="impotent_key"
declare -r DEFAULT_SECURE=""
declare -r DEFAULT_VERBOSE="-i"
declare -r DEFAULT_MTLS=""
declare -ri DEFAULT_DEBUG=0
declare -ri DEFAULT_ANSI_ESCAPE=1

# xks-proxy endpoint (Required)
declare XKS_PROXY_HOST=${XKS_PROXY_HOST-${DEFAULT_XKS_PROXY_HOST}}
# xks-proxy URI prefix; The test client will append kms/xks/v1 to form the full URI
declare URI_PREFIX=${URI_PREFIX-${DEFAULT_URI_PREFIX}}
# region used for SigV4 authentication; included in the Authorization header
declare REGION=${REGION-${DEFAULT_REGION}}

# VERBOSE="-i" to include the HTTP response headers in the output
# VERBOSE="-v" to make curl verbose
# VERBOSE="-iv" to do both -i and -v
declare VERBOSE=${VERBOSE-${DEFAULT_VERBOSE}}

# id of a key in the external HSM that is usable for both encrypt and decrypt operations
declare KEY_ID=${KEY_ID-${DEFAULT_KEY_ID}}
declare ENCRYPT_ONLY_KEY_ID=${ENCRYPT_ONLY_KEY_ID-${DEFAULT_ENCRYPT_ONLY_KEY_ID}}
declare DECRYPT_ONLY_KEY_ID=${DECRYPT_ONLY_KEY_ID-${DEFAULT_DECRYPT_ONLY_KEY_ID}}
# id of a key in the external HSM whose key usage includes neither encrypt nor decrypt
declare IMPOTENT_KEY_ID=${IMPOTENT_KEY_ID-${DEFAULT_IMPOTENT_KEY_ID}}

# Used to select whether TLS is used over http
# Can be set to blank to use http instead
declare SCHEME=${SCHEME-${DEFAULT_SCHEME}}

# (TLS) By default, every SSL connection `curl` makes is verified to be secure.
# This option allows `curl` to proceed and operate even for server connections otherwise considered insecure.
# Default to blank, which means, SSL connection is verified if https is in use
# Can be set to `"--insecure"` to disable SSL connection verification if
# https is in use, and is particularly useful for testing a self-signed or expired certificate
declare SECURE=${SECURE-${DEFAULT_SECURE}}

# DEBUG=0 to disable debugging output to stderr
# DEBUG=1 to enable debugging output to stderr, including the actual curl command being run
declare -i DEBUG=${DEBUG-${DEFAULT_DEBUG}}

# Used to specify both a client-side SSL private key and SSL certifcate
# for performing mutual TLS with the xks-proxy.
# Example: MTLS_KEY="--key mtls/test_key.pem --cert mtls/test_cert.pem"
declare MTLS=${MTLS-${DEFAULT_MTLS}}

# ANSI_ESCAPE=0 to disable the use of ANSI Escape codes in the output
# ANSI_ESCAPE=1 to enable the use of ANSI Escape codes in the output
declare -i ANSI_ESCAPE=${ANSI_ESCAPE-${DEFAULT_ANSI_ESCAPE}}
