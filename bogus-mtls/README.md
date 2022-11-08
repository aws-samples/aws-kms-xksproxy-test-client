## Notes

All keys and certificates placed in this folder with the respective file names of "`*_key.pem`" and "`*_cert.pem`"
1. are expected to cause `mTLS` connectivity failure for one reason or another when used against an XKS Proxy that enforces the use of `mTLS`; and
1. are automatically picked up by [test_negative_mtls](../test_negative_mtls) for testing `mTLS` failure.
