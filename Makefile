sensei:
	tuist fetch
	TUIST_BUNDLE_ID_PREFIX=$(bundle-id-prefix) TUIST_VERSION=$(version) TUIST_BUILD=$(build) tuist generate
