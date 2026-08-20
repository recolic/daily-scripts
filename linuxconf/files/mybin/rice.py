#!/usr/bin/python3

# water = K * [rice^0, rice^1]
# only US long-grain data came from experiment.
# x = [130,154,206,86,86,85,87,50,84], y = [252,278,334,213,215,213,218,180,210]
rice_K = {
    "US Long Grain":   (129.89, 0.975),
    "US Medium Grain": (129.89, 0.975),
    "Jasmine": (129.89, 0.731),
    "Basmati": (129.89, 1.100),
}
"""prompt to generate the rest K:

note that I didn't ask you to read manufacturer's stupid document. Their document is already bullshit. you should never follow them.
I told you, you should make these value basing on research, experiment, or data, or science analysis (such as what is producing the K0 factor and what is causing the K1 factor, and from material science, deduce the correct K vector for them basing on different material property)
please do your research, use Long Grain data as baseline (which already reflects my taste and cooker condition), to deduce other Ks.

Task: research and calculate K for Medium Grain, Jasmine, and Basmati rice. Then finish the script.
"""
while True:
    x = float(input("Dry Rice (g): "))
    print("[Aroma ARC-363-1NGB 3cup/6cup rice cooker]")
    for name,K in rice_K.items():
        print(f"if {name}, Water = {K[0]+K[1]*x:.1f} g")

