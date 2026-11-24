// ==UserScript==
// @name        apple-webauthn-capabilities
// @namespace   nixos-config
// @description Hide PublicKeyCredential.getClientCapabilities on Apple sign-in
// @match       https://appleid.apple.com/*
// @match       https://idmsa.apple.com/*
// @run-at      document-start
// ==/UserScript==

// Apple's sign-in script awaits PublicKeyCredential.getClientCapabilities()
// before it finishes setting up the sign-in form. In QtWebEngine that call
// never settles, so the form is left half set up and Continue fails with
// "Cannot read properties of undefined (reading 'trigger')". Apple's script
// treats a missing getClientCapabilities as "no information" and carries on.
if (window.PublicKeyCredential && PublicKeyCredential.getClientCapabilities) {
  delete PublicKeyCredential.getClientCapabilities;
}
