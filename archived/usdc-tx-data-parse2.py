#!/usr/bin/env python3
# GPT-5

KNOWN_FUNCS = {
    "a9059cbb": "TRANSFER",
    "095ea7b3": "APPROVE"
}
DECIMALS = {"USDC": 6, "USDT": 6}

def parse_tx(data, token="USDC"):
    data = data.lower().removeprefix("0x")
    sel = data[:8]
    op = KNOWN_FUNCS.get(sel)

    if not op:
        print(f"Op: UNKNOWN {sel}")
        return

    addr = "0x" + data[32:72]
    raw_amt = int(data[72:136], 16)
    dec = DECIMALS.get(token, 18)

    amt = "Infinite" if op == "APPROVE" and raw_amt > 2**255 else f"{raw_amt/(10**dec):,.{dec}f} {token}"

    print(f"Op: {op}")
    print(f"Dest: {addr}")
    print(f"Amount: {amt}")

#def decode_ur_eth_sign_request(ur_string):
#    from ur_registry import URDecoder
#    from ur_registry.ETHSignRequest import ETHSignRequest
#    if ur_string.startswith("ur:eth-sign-request/"):
#        part = ur_string[len("ur:eth-sign-request/"):]
#        dec = URDecoder()
#        dec.receive_part(f"ur:eth-sign-request/{part}")  # full string
#        ur_obj = dec.result_ur()
#        req = ETHSignRequest.from_cbor(ur_obj.cbor)
#        payload = req.get_sign_data()
#        return "0x" + payload.hex()
#    return ur_string


if __name__ == "__main__":
    # parse_tx(input("Hex data: ").strip())
    testqr = "ur:eth-sign-request/oladtpdagdpyjzbsveemamfpfllnsogydrolcssocmaohdjpaoyajllyldaolpbkkneclfaelpbtwngtvyaolfwyjpmwfngansghdwwshyetbyvycfdwvdbtlkrtfshheohklarofyptahnsrkaeaeaeaeaeaeaeaeaeaeaeaehehgwemthgaewmlnmusewpwtqdisclbzmundpazeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaebsfwfzrtaxaaaacsldahtaaddyoeadlecsdwykcsfnykaeykaewkaewkaocybnmdbbsnamghhehgwemthgaewmlnmusewpwtqdisclbzmundpazebkhytyjs"
    decode_ur_eth_sign_request(testqr)

# Example:
#   0xa9059cbb00000000000000000000000032be343b94f860124dc4fee278fdcbd38c102d880000000000000000000000000000000000000000000000000000004a8cf090
#   0x095ea7b3000000000000000000000000dAC17F958D2ee523a2206206994597C13D831ec7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
