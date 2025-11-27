from urtypes import bytewords
import cbor2
from web3 import Web3

def decode_eth_sign_request(ur_string):
    # Strip prefix and decode bytewords → bytes
    payload = ur_string.split("/", 1)[1]
    cbor_bytes = bytewords.decode(payload)

    # Parse CBOR into dict
    data = cbor2.loads(cbor_bytes)

    sign_data = data[2]   # raw tx
    chain_id  = data.get(4)

    return sign_data, chain_id


def decode_tx_with_web3(raw_tx_bytes):
    w3 = Web3()
    tx = w3.eth.account._parse_transaction(raw_tx_bytes)
    return tx


# === Example ===

testqr = "ur:eth-sign-request/oladtpdagdpyjzbsveemamfpfllnsogydrolcssocmaohdjpaoyajllyldaolpbkkneclfaelpbtwngtvyaolfwyjpmwfngansghdwwshyetbyvycfdwvdbtlkrtfshheohklarofyptahnsrkaeaeaeaeaeaeaeaeaeaeaeaehehgwemthgaewmlnmusewpwtqdisclbzmundpazeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaebsfwfzrtaxaaaacsldahtaaddyoeadlecsdwykcsfnykaeykaewkaewkaocybnmdbbsnamghhehgwemthgaewmlnmusewpwtqdisclbzmundpazebkhytyjs"

raw_tx, chain_id = decode_eth_sign_request(testqr)
decoded = decode_tx_with_web3(raw_tx)

print("chainId:", chain_id)
print(decoded)

