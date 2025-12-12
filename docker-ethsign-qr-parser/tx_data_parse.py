# Parse the magical tx data string and tell if it's safe.

KNOWN_INNER_DEST = {
    "66a9893cc07d91d95644aedd05d03f95e1dba8af": "Uniswap Router V2 on ETH",
    "3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad": "Uniswap Router V1.2 on ETH",
    "ef1c6e67703c7bd7107eed8303fbe6ec2554bf6b": "Uniswap Router V1 on ETH",
    "e592427a0aece92de3edee1f18e0157c05861564": "Uniswap Router V3",
    "1095692a6237d83c6a72f3f5efedb9a670c49223": "Uniswap Router V2 on Polygon",
    "ec7be89e9d109e7e3fec59c222cf297125fefda2": "Uniswap Router V1.2 on Polygon",
    "643770e279d5d0733f21d6dc03a8efbabf3255b4": "Uniswap Router V1.2_nov2 on Polygon",
    "4c60051384bd2d3c01bfc845cf5f4b44bcbe9de5": "Uniswap Router V1 on Polygon",
    "ba12222222228d8ba445958a75a0704d566bf2c8": "Balancer Vault",
    "000000000022d473030f116ddee9f6b43ac78ba3": "Uniswap Permit2",
}
KNOWN_FUNCS = { 
    "a9059cbb": "TRANSFER",
    "095ea7b3": "APPROVE"
}
KNOWN_ETH_DEST = {
    "a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48": ["USDC", 6],
    "dac17f958d2ee523a2206206994597c13d831ec7": ["USDT", 6],
    "c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2": ["WETH", 18],
    "ae78736cd615f374d3085123a210448e74fc6393": ["rETH", 18],
}

def pprint_op(op_hex):
    return KNOWN_FUNCS.get(op_hex, op_hex)
def pprint_dest(dest_hex):
    return KNOWN_ETH_DEST.get(dest_hex, [dest_hex, 18])
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

    return f" Op: {op}\n Dest: {addr}\n Amount: {amt} * {token}"

if __name__ == "__main__":
    import sys
    print("Paste your EVM transaction data:")
    # Example: 0xa9059cbb0000000000000000000000005f57ed965700eb8693c1ecf0b3682115939bb1fe00000000000000000000000000000000000000000000000000000000000f4240
    res = parse(sys.stdin.readline().strip())
    print(res)

