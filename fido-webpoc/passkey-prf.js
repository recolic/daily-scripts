"use strict";

const encoder = new TextEncoder();

function randomBytes(length) {
  return crypto.getRandomValues(new Uint8Array(length));
}

function toBase64Url(bytes) {
  return btoa(String.fromCharCode(...new Uint8Array(bytes)))
    .replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

function fromBase64Url(value) {
  const base64 = value.replaceAll("-", "+").replaceAll("_", "/").padEnd(Math.ceil(value.length / 4) * 4, "=");
  return Uint8Array.from(atob(base64), character => character.charCodeAt(0));
}

function asBytes(value) {
  return typeof value === "string" ? encoder.encode(value) : value;
}

/**
 * Minimal browser-only WebAuthn PRF helper.
 *
 * Enrollment challenges are generated in the browser because this helper is for
 * local key derivation, not login. Authentication challenges must come from and
 * be verified by a server when WebAuthn is used for website login.
 */
export class YubiKeyPrf {
  constructor({
    storageKey = "yubikey-prf-credential-id",
    rpName = "YubiKey PRF",
    rpId,
    authenticatorAttachment,
    residentKey = "preferred",
    prfInput = "yubikey-prf/cipher-key/v1",
    hkdfInfo = "yubikey-prf/aes-gcm/v1"
  } = {}) {
    this.storageKey = storageKey;
    this.rpName = rpName;
    this.rpId = rpId;
    this.authenticatorAttachment = authenticatorAttachment;
    this.residentKey = residentKey;
    this.prfInput = asBytes(prfInput);
    this.hkdfInfo = asBytes(hkdfInfo);
  }

  get credentialId() {
    return localStorage.getItem(this.storageKey);
  }

  get enrolled() {
    return this.credentialId !== null;
  }

  async enroll({ userName = `poc-${Date.now()}`, displayName = userName, userId = randomBytes(32) } = {}) {
    this.#requireWebAuthn();

    const publicKey = {
      challenge: randomBytes(32),
      rp: { name: this.rpName },
      user: { id: asBytes(userId), name: userName, displayName },
      pubKeyCredParams: [
        { type: "public-key", alg: -7 },
        { type: "public-key", alg: -257 }
      ],
      authenticatorSelection: {
        residentKey: this.residentKey,
        userVerification: "required"
      },
      timeout: 120000,
      attestation: "none",
      extensions: { prf: {} }
    };
    if (this.rpId) publicKey.rp.id = this.rpId;
    if (this.authenticatorAttachment) publicKey.authenticatorSelection.authenticatorAttachment = this.authenticatorAttachment;

    const credential = await navigator.credentials.create({ publicKey });
    if (!credential) throw new Error("Credential creation was cancelled.");
    if (!credential.getClientExtensionResults().prf?.enabled) {
      throw new Error("This browser/authenticator path did not enable WebAuthn PRF.");
    }

    const credentialId = toBase64Url(credential.rawId);
    localStorage.setItem(this.storageKey, credentialId);
    return { credentialId, prfEnabled: true };
  }

  /** Clears this origin's local credential reference; WebAuthn cannot delete credentials from a YubiKey. */
  clearCredential() {
    localStorage.removeItem(this.storageKey);
  }

  /** Returns an AES-256-GCM CryptoKey derived from the enrolled credential. Keep extractable false outside demonstrations. */
  async deriveAesKey({ prfInput = this.prfInput, hkdfInfo = this.hkdfInfo, extractable = false } = {}) {
    this.#requireWebAuthn();
    if (!this.credentialId) throw new Error("Enroll a credential first.");

    const publicKey = {
      challenge: randomBytes(32),
      allowCredentials: [{ type: "public-key", id: fromBase64Url(this.credentialId) }],
      userVerification: "required",
      timeout: 120000,
      extensions: { prf: { eval: { first: asBytes(prfInput) } } }
    };
    if (this.rpId) publicKey.rpId = this.rpId;

    const assertion = await navigator.credentials.get({ publicKey });
    if (!assertion) throw new Error("Authentication was cancelled.");
    const prfValue = assertion.getClientExtensionResults().prf?.results?.first;
    if (!prfValue) throw new Error("No PRF result was returned by the browser/authenticator.");

    const masterKey = await crypto.subtle.importKey("raw", prfValue, "HKDF", false, ["deriveKey"]);
    return crypto.subtle.deriveKey(
      { name: "HKDF", hash: "SHA-256", salt: new Uint8Array(), info: asBytes(hkdfInfo) },
      masterKey,
      { name: "AES-GCM", length: 256 },
      extractable,
      ["encrypt", "decrypt"]
    );
  }

  #requireWebAuthn() {
    if (!window.isSecureContext || !window.PublicKeyCredential) {
      throw new Error("WebAuthn requires HTTPS or localhost in a supported browser.");
    }
  }
}
