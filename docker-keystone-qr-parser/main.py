# doc: https://developer.onekey.so/connect-to-hardware/air-gap-qr-code/reference/ethereum-and-evm/ethsignrequest

from ur.ur_decoder import URDecoder
from ur.ur import UR
import cbor2
import tx_data_parse

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
    # dataType:
    #    transaction = 1, // For the legacy transaction, the rlp encoding of the unsigned data.
    #    typedData = 2, // For the EIP-712 typed data. Bytes of the json string.
    #    personalMessage = 3, // For the personal message signing.
    #    typedTransaction = 4 // For the typed transaction, like the EIP-1559 transaction.
    sign_data, data_type = data[2], data[3]
    chain_id = data.get(4)
    return sign_data, data_type, chain_id

#from web3 import Web3
#def decode_tx(raw_tx_bytes):
#    w3 = Web3()
#    return w3.eth.account._parse_transaction(raw_tx_bytes)
from eth_account.typed_transactions import TypedTransaction
from eth_account._utils.legacy_transactions import Transaction, vrs_from
from eth_account._utils.signing import hash_of_signed_transaction
from eth_account import Account
import eth_account
from hexbytes import HexBytes
import rlp

def decode_alt(txn_bytes):
    ## weird workaround. why this extra byte in RLP???
    if txn_bytes[0] == 0x02: txn_bytes = txn_bytes[1:]
    # recolic: manually implement ETH sign request parsing
    # [HexBytes('0x89'), HexBytes('0x02'), HexBytes('0x0a7a358200'), HexBytes('0x0df14de102'), HexBytes('0xee72'), HexBytes('0xvery_long_addr'), HexBytes('0x'), HexBytes('<very long data>'), []]
    chain_id, tx_type, max_priority_fee_pg, max_fee_pg, gas_limit, tx_to, tx_amount, tx_data, access_list = rlp.decode(txn_bytes)
    def chain_name(cid):
        m = {1:"ETH",137:"Polygon",56:"BNB",10:"Optimism",42161:"Arbitrum"}
        return m.get(int.from_bytes(cid,'big'),"Unknown")
    def tx_type_name(t):
        return "EIP-1559" if int.from_bytes(t,'big') == 2 else "Unknown"
    def hx(x):
        return x.hex() if x else "0x"
    cid = int.from_bytes(chain_id,'big')
    tf = int.from_bytes(max_fee_pg,'big')
    gl = int.from_bytes(gas_limit,'big')
    amt = int.from_bytes(tx_amount,'big') if tx_amount else 0
    
    info = f"""
Chain: {cid} {chain_name(chain_id)}
Type: {tx_type_name(tx_type)}
Max total fee: {format((tf * gl) / 1e18, '.8f')} ETH
To: {hx(tx_to)}
Amount: {amt}
Data (Raw): {hx(tx_data)}
Data (Parsed): {tx_data_parse.parse(hx(tx_data))}
"""
    return info

def decode_tx(raw_bytes, data_type):
    # Ref: https://ethereum.stackexchange.com/questions/83802/how-to-decode-a-raw-transaction-in-python
    txn_bytes = HexBytes(raw_bytes)
    print("tx bytes:", txn_bytes.hex())
    if data_type == 4:
        # We are dealing with a typed transaction.
        tx_type = 2
        return decode_alt(txn_bytes) # for unknown reason, next line will crash
        tx = TypedTransaction.from_bytes(txn_bytes)
        #tx=eth_account._utils.signing.UnsignedTransaction.from_bytes(txn_bytes)
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


def parse_eth_sign_request(ur_string):
    sign_data, t, chain_id = decode_eth_sign_request(ur_string)
    return decode_tx(sign_data, t)

## test and print
qr = "ur:eth-sign-request/oladtpdagdpyjzbsveemamfpfllnsogydrolcssocmaohdjpaoyajllyldaolpbkkneclfaelpbtwngtvyaolfwyjpmwfngansghdwwshyetbyvycfdwvdbtlkrtfshheohklarofyptahnsrkaeaeaeaeaeaeaeaeaeaeaeaehehgwemthgaewmlnmusewpwtqdisclbzmundpazeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaebsfwfzrtaxaaaacsldahtaaddyoeadlecsdwykcsfnykaeykaewkaewkaocybnmdbbsnamghhehgwemthgaewmlnmusewpwtqdisclbzmundpazebkhytyjs"
print("Test functionality:", parse_eth_sign_request(qr))

from http.server import BaseHTTPRequestHandler, HTTPServer
import os
class SimpleServer(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/api":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length).decode("utf-8")
            res = parse_eth_sign_request(body)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(res.encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()
    def do_GET(self):
        fn = self.path.lstrip("/") or "index.html"
        if os.path.isfile(fn):
            with open(fn, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"not found")

if __name__ == "__main__":
    print("listen 0.0.0.0:8080")
    HTTPServer(("0.0.0.0", 8080), SimpleServer).serve_forever()


