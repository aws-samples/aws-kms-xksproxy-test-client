![](https://github.com/aws-samples/aws-kms-xksproxy-test-client/actions/workflows/ci.yml/badge.svg)

# aws-kms-xksproxy-test-client

This package provides a sample `curl` based utility for reference by external customers to test against
implemenations of the AWS KMS External Keystore (XKS) Proxy API over HTTP or HTTPS.

# Version

`1.1.0`

## Dependencies

* `awk`
* `base64`
* `bash 4.2+`
* `curl 7.75+` (i.e. with `sigv4` support)
* `echo`
* `head`
* `jq 1.5+`
* `mktemp`
* `printf`
* `read`
* `sed`
* `sha256sum`
* `tr`
* `xxd`

## Examples

```bash
# Change this to your XKS Proxy endpoint to test.
export XKS_PROXY_HOST="myxksproxy.domain.com"
# Change this to the URI_PREFIX of a logical keystore supported by your XKS Proxy.
export URI_PREFIX="example/uri/path/prefix"
# Change this to the Access key ID for request authentication to your logical keystore.
# Valid characters are a-z, A-Z, 0-9, /, - (hyphen), and _ (underscore)
export SIGV4_ACCESS_KEY_ID="aaaaaaaaaaaaaaaaaaaa"
# Change this to the Secret access key for request authentication to your logical keystore.
# Secret access key must have between 43 and 64 characters. Valid characters are a-z, A-Z, 0-9, /, +, and =
export SIGV4_SECRET_ACCESS_KEY="==========================================="
# Change this to a test key id supported by your logical keystore.
export KEY_ID="foo"

# Run the tests
./test-xks-proxy

# Run all the tests including the use of encrypt-only key, decrypt-only key and
# key that can neither encrypt nor decrypt. You can specify the respective key id's with
# the environment variables ENCRYPT_ONLY_KEY_ID, DECRYPT_ONLY_KEY_ID and IMPOTENT_KEY_ID.
./test-xks-proxy -a
```

### Examples of running in other modes

```bash
# Do not include the curl HTTP response headers in the output
VERBOSE= ./test-xks-proxy

# To make curl verbose
VERBOSE=-v ./test-xks-proxy

# To make curl verbose and include the HTTP response headers in the output
VERBOSE=-iv ./test-xks-proxy

# To enable debugging output to stderr, including the actual curl command being run
DEBUG=1 ./test-xks-proxy

# To enable all of the above
VERBOSE=-iv DEBUG=1 ./test-xks-proxy

# To test against the endpoint http:://xks-proxy.mydomain.com
# XKS_PROXY_HOST=xks-proxy.mydomain.com \
#     SCHEME= \
#     ./test-xks-proxy

# To enable mTLS, a client side SSL key and certificate would need to be specified.
# The command to run the tests would be something like:
# XKS_PROXY_HOST=xks-proxy_with_mtls_enabled.mydomain.com \
#    MTLS="--key client_key.pem --cert client_cert.pem" \
#    ./test-xks-proxy
```

## Environment variables

The following environment variables can be used to override the default settings.

* `XKS_PROXY_HOST` - the xks-proxy endpoint (Required)
* `URI_PREFIX` - the xks-proxy URI prefix
    * Default to `"example/uri/path/prefix"`
* `REGION` - the region used for SigV4 authentication
    * Default to `"us-east-1"`
* `VERBOSE` - verbosity
    * Default to `"-i"`
    * Can be set to `"-i"` to include the curl HTTP response headers in the output
    * Can be set to `"-v"` to make curl verbose
    * Can be set to `"-iv"` to do both

* `KEY_ID` - the HSM key id
    * Default to `"foo"`
* `ENCRYPT_ONLY_KEY_ID` - the HSM key id for an encrypt-only key
    * Default to `"encrypt_only_key"`
* `DECRYPT_ONLY_KEY_ID` - the HSM key id for an decrypt-only key
    * Default to `"decrypt_only_key"`
* `IMPOTENT_KEY_ID` - the HSM key id for a key that can neither encrypt nor decrypt
    * Default to `"impotent_key"`

* `SCHEME` - used to select whether TLS is used over http
    * Default to `"https://"`
    * Can be set to blank to use http instead
* `SECURE` - (TLS) By default, every SSL connection `curl` makes is verified to be secure. This option allows `curl` to proceed and operate even for server connections otherwise considered insecure.
    * Default to blank, which means, SSL connection is verified if https is in use
    * Can be set to `"--insecure"` to disable SSL connection verification if https is in use
* `MTLS` - used to specify both a client-side SSL private key and SSL certifcate for performing mutual TLS with the xks-proxy.
    * Default to not using mTLS.

* `DEBUG` - used to toggle debugging output to stderr
    * Default to `0` to disable debugging output
    * Can be set to `1` to enable debugging output, printing the actual `curl` command being run

* `ANSI_ESCAPE` - used to toggle the use of ANSI Escape codes in the output
    * Default to `1` to enable the use of ANSI Escape codes in the output
    * Can be set to `0` to disable the use of ANSI Escape codes in the output

## Notes

The `sha256sum` command can be installed on `OSX` via

```bash
brew install coreutils
```
and is typically pre-installed in a Linux distribution.

## Change log

* Wed Oct 5 2022 Hanson Char <hchar@amazon.com> - 1.1.0
    - Fix typo, changing "ASCII_ESCAPE" to "ANSI_ESCAPE"
* Wed Sep 28 2022 Hanson Char <hchar@amazon.com> - 1.0.6
    - Fix "Segmentation fault: 11" when run on OSX
* Mon Sep 26 2022 Hanson Char <hchar@amazon.com> - 1.0.5
    - Supports ANSI_ESCAPE to toggle the use of ANSI Escape codes in the output
* Mon Sep 26 2022 Hanson Char <hchar@amazon.com> - 1.0.4
    - Make scripts work when run in AWS Lambda
* Mon Sep 5 2022 Hanson Char <hchar@amazon.com> - 1.0.3
    - Initial release

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.
