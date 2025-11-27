from ur.ur_decoder import URDecoder
from ur.ur import UR
import cbor2
from web3 import Web3

def decode_ur(ur_string):
    dec = URDecoder()
    dec.receive_part(ur_string)
    if not dec.is_complete() or not dec.is_success():
        raise ValueError("UR not decoded")
    return dec.result.cbor


def decode_eth_sign_request(ur_string):
    cbor_bytes = decode_ur(ur_string)

    data = cbor2.loads(cbor_bytes)

    # EthSignRequest structure:
    # {
    #   1: requestId (optional)
    #   2: signData
    #   3: dataType
    #   4: chainId (optional)
    #   5: derivationPath (complex object)
    #   6: address (optional)
    #   7: origin (optional)
    # }

    sign_data = data[2]
    chain_id = data.get(4)
    return sign_data, chain_id


#def decode_tx(raw_tx_bytes):
#    w3 = Web3()
#    return w3.eth.account._parse_transaction(raw_tx_bytes)
from eth_account.typed_transactions import TypedTransaction
from eth_account._utils.legacy_transactions import Transaction, vrs_from
from eth_account._utils.signing import hash_of_signed_transaction
from eth_account import Account
from hexbytes import HexBytes

def decode_tx(txn_bytes2):
    txn_bytes = HexBytes(txn_bytes2)
    if len(txn_bytes) > 0 and txn_bytes[0] <= 0x7F:
        # We are dealing with a typed transaction.
        tx_type = 2
        tx = TypedTransaction.from_bytes(txn_bytes)
        msg_hash = tx.hash()
        vrs = tx.vrs()
    else:
        # We are dealing with a legacy transaction.
        tx_type = 0
        tx = Transaction.from_bytes(txn_bytes)
        msg_hash = hash_of_signed_transaction(tx)
        vrs = vrs_from(tx)

    # extracting sender address
    sender = Account._recover_hash(msg_hash, vrs=vrs)

    # adding sender to result and cleaning
    res = tx.as_dict()
    res["from"] = sender
    res["to"] = res["to"].hex()
    res["data"] = res["data"].hex()
    res["type"] = res.get("type", tx_type)

    return res


# ------------ FULL PIPELINE ------------

def parse_eth_sign_request(ur_string):
    sign_data, chain_id = decode_eth_sign_request(ur_string)
    tx = decode_tx(sign_data)
    return {
        "chain_id": chain_id,
        "tx": tx,
    }


# ------------ RUN ON YOUR SAMPLE ------------

qr = "ur:eth-sign-request/oladtpdagdpyjzbsveemamfpfllnsogydrolcssocmaohdjpaoyajllyldaolpbkkneclfaelpbtwngtvyaolfwyjpmwfngansghdwwshyetbyvycfdwvdbtlkrtfshheohklarofyptahnsrkaeaeaeaeaeaeaeaeaeaeaeaehehgwemthgaewmlnmusewpwtqdisclbzmundpazeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaebsfwfzrtaxaaaacsldahtaaddyoeadlecsdwykcsfnykaeykaewkaewkaocybnmdbbsnamghhehgwemthgaewmlnmusewpwtqdisclbzmundpazebkhytyjs"
qr = "ur:eth-sign-request/oladtpdagdpyjzbsveemamfpfllnsogydrolcssocmaohdjpaoyajllyldaolpbkkneclfaelpbtwngtvyaolfwyjpmwfngansghdwwshyetbyvycfdwvdbtlkrtfshheohklarofyptahnsrkaeaeaeaeaeaeaeaeaeaeaeaehehgwemthgaewmlnmusewpwtqdisclbzmundpazeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaebsfwfzrtaxaaaacsldahtaaddyoeadlecsdwykcsfnykaeykaewkaewkaocybnmdbbsnamghhehgwemthgaewmlnmusewpwtqdisclbzmundpazebkhytyjs"

result = parse_eth_sign_request(qr)
print(result)

