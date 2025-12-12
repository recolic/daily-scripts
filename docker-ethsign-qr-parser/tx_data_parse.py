# Parse the magical tx data string and tell if it's safe.

KNOWN_INNER_DEST = {
    "e592427a0aece92de3edee1f18e0157c05861564": "Uniswap V3 Router",
    "7a250d5630b4cf539739df2c5dacb4c659f2488d": "Uniswap V2 Router",
    "d9e1ce17f2641f24ae83637ab66a2cca9c378b9f": "Uniswap V3 Quoter",
    "3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad": "Balancer Vault",
}
KNOWN_FUNCS = { 
    "a9059cbb": "TRANSFER",
    "095ea7b3": "APPROVE"
}
KNOWN_ETH_DEST = {
    "a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48": ["USDC", 6],
    "dac17f958d2ee523a2206206994597c13d831ec7": ["USDT", 6],
    "c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2": ["WETH", 18],
}

def pprint_op(op_hex):
    return KNOWN_FUNCS.get(op_hex, op_hex)
def pprint_dest(dest_hex):
    return KNOWN_ETH_DEST.get(dest_hex, [dest_hex, None])
def pprint_dest2(dest_hex):
    return KNOWN_INNER_DEST.get(dest_hex, dest_hex)

def parse(data, dest="a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"):
    data = data.lower().removeprefix("0x")
    dest = dest.lower().removeprefix("0x")

    token, dec = pprint_dest(dest)

    op = pprint_op(data[:8])
    if op not in KNOWN_FUNCS.values():
        return f"Op: UNKNOWN {op}"

    addr = pprint_dest2(data[32:72])
    raw_amt = int(data[72:136], 16) 

    amt = "Infinite" if op == "APPROVE" and raw_amt > 2**255 else f"{raw_amt/(10**dec):,.{dec}f} {token}"

    return f"Op: {op}\nDest: {addr}\nAmount: {amt}"

if __name__ == "__main__":
    import sys
    print("Paste your EVM transaction data:")
    # Example: 0xa9059cbb0000000000000000000000005f57ed965700eb8693c1ecf0b3682115939bb1fe00000000000000000000000000000000000000000000000000000000000f4240
    res = parse(sys.stdin.readline().strip())
    print(res)

