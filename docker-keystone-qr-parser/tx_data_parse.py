# Parse the magical tx data string and tell if it's safe.

def parse(data, token="USDC"):
    KNOWN_FUNCS = { 
        "a9059cbb": "TRANSFER",
        "095ea7b3": "APPROVE"
    }
    DECIMALS = {"USDC": 6, "USDT": 6}

    data = data.lower().removeprefix("0x")
    sel = data[:8]
    op = KNOWN_FUNCS.get(sel)
    if not op: 
        return f"Op: UNKNOWN {sel}"

    addr = "0x" + data[32:72]
    raw_amt = int(data[72:136], 16) 
    dec = DECIMALS.get(token, 18) 

    amt = "Infinite" if op == "APPROVE" and raw_amt > 2**255 else f"{raw_amt/(10**dec):,.{dec}f} {token}"

    return f"Op: {op}\nDest: {addr}\nAmount: {amt}"

if __name__ == "__main__":
    import sys
    print("Paste your EVM transaction data:")
    # Example: 0xa9059cbb0000000000000000000000005f57ed965700eb8693c1ecf0b3682115939bb1fe00000000000000000000000000000000000000000000000000000000000f4240
    res = parse(sys.stdin.readline().strip())
    print(res)

