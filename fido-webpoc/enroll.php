<?php
session_start();

function b64u_encode($value) { return rtrim(strtr(base64_encode($value), '+/', '-_'), '='); }
function b64u_decode($value) { $result = base64_decode(strtr($value, '-_', '+/'), true); if ($result === false) fail('bad base64'); return $result; }
function fail($message) { http_response_code(400); die($message); }
function request_origin() { return $_SERVER['HTTP_ORIGIN'] ?? ((!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST']); }
function rp_id() { $host = parse_url(request_origin(), PHP_URL_HOST); if (!$host) fail('bad host'); return $host; }
function der_to_pem($der) { return "-----BEGIN PUBLIC KEY-----\n" . chunk_split(base64_encode($der), 64, "\n") . "-----END PUBLIC KEY-----\n"; }
function json_input() { $data = json_decode(file_get_contents('php://input'), true); if (!is_array($data)) fail('bad json'); return $data; }

if (($_GET['action'] ?? '') === 'options') {
  $challenge = random_bytes(32);
  $_SESSION['webauthn_enroll_challenge'] = $challenge;
  header('Content-Type: application/json');
  echo json_encode(['challenge' => b64u_encode($challenge), 'rpId' => rp_id(), 'origin' => request_origin(), 'userId' => b64u_encode(random_bytes(32))]);
  exit;
}

if (($_GET['action'] ?? '') === 'finish') {
  $data = json_input();
  $challenge = $_SESSION['webauthn_enroll_challenge'] ?? null;
  unset($_SESSION['webauthn_enroll_challenge']);
  if (!is_string($challenge)) fail('missing challenge');
  $client_json = b64u_decode($data['clientDataJSON'] ?? '');
  $client = json_decode($client_json, true);
  if (!is_array($client) || ($client['type'] ?? '') !== 'webauthn.create') fail('bad ceremony');
  if (!hash_equals(b64u_encode($challenge), $client['challenge'] ?? '')) fail('bad challenge');
  if (!hash_equals(request_origin(), $client['origin'] ?? '')) fail('bad origin');
  $auth_data = b64u_decode($data['authenticatorData'] ?? '');
  if (strlen($auth_data) < 37 || !hash_equals(hash('sha256', rp_id(), true), substr($auth_data, 0, 32))) fail('bad rp id');
  $flags = ord($auth_data[32]);
  if (($flags & 0x01) === 0 || ($flags & 0x04) === 0) fail('user verification required');
  $public_key_der = b64u_decode($data['publicKey'] ?? '');
  $public_key = der_to_pem($public_key_der);
  $key = openssl_pkey_get_public($public_key);
  if ($key === false) fail('bad public key');
  $details = openssl_pkey_get_details($key);
  $alg = (int)($data['publicKeyAlgorithm'] ?? 0);
  if (($alg !== -7 || ($details['type'] ?? -1) !== OPENSSL_KEYTYPE_EC) && ($alg !== -257 || ($details['type'] ?? -1) !== OPENSSL_KEYTYPE_RSA)) fail('unsupported public key');
  $record = ['v' => 1, 'id' => $data['credentialId'] ?? '', 'key' => b64u_encode($public_key_der), 'alg' => $alg, 'rp' => rp_id()];
  if ($record['id'] === '') fail('missing credential id');
  header('Content-Type: text/plain; charset=utf-8');
  echo b64u_encode(json_encode($record, JSON_UNESCAPED_SLASHES));
  exit;
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Enroll passkey</title>
  <style>body { max-width: 42rem; margin: 3rem auto; padding: 0 1rem; font: 16px/1.5 system-ui, sans-serif; } button { padding: .6rem .9rem; } pre { padding: 1rem; border: 1px solid #aaa; white-space: pre-wrap; overflow-wrap: anywhere; }</style>
</head>
<body>
  <h1>Enroll passkey</h1>
  <button id="enroll">Enroll</button>
  <p>Store the resulting WebAuthn credential record as <code>FIDO_CRED_REC_&lt;k&gt;</code>.</p>
  <pre id="output"></pre>
  <script>
    const output = document.querySelector('#output');
    const fromB64u = value => Uint8Array.from(atob(value.replaceAll('-', '+').replaceAll('_', '/').padEnd(Math.ceil(value.length / 4) * 4, '=')), c => c.charCodeAt(0));
    const toB64u = value => btoa(String.fromCharCode(...new Uint8Array(value))).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
    document.querySelector('#enroll').onclick = async () => {
      try {
        const options = await fetch('?action=options').then(response => response.json());
        const credential = await navigator.credentials.create({ publicKey: { challenge: fromB64u(options.challenge), rp: { id: options.rpId, name: 'Passkey PHP POC' }, user: { id: fromB64u(options.userId), name: 'user', displayName: 'User' }, pubKeyCredParams: [{ type: 'public-key', alg: -7 }, { type: 'public-key', alg: -257 }], authenticatorSelection: { residentKey: 'preferred', userVerification: 'required' }, attestation: 'none', timeout: 120000 } });
        const publicKey = credential.response.getPublicKey();
        if (!publicKey) throw new Error('This browser cannot export the passkey public key.');
        const body = { credentialId: toB64u(credential.rawId), clientDataJSON: toB64u(credential.response.clientDataJSON), authenticatorData: toB64u(credential.response.getAuthenticatorData()), publicKey: toB64u(publicKey), publicKeyAlgorithm: credential.response.getPublicKeyAlgorithm() };
        const response = await fetch('?action=finish', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
        const text = await response.text();
        if (!response.ok) throw new Error(text);
        output.textContent = text;
      } catch (error) { output.textContent = `${error.name}: ${error.message}`; }
    };
  </script>
</body>
</html>