"""Economy pacing simulator for Brainrot Factory Tycoon.

Mirrors the formulas in src/shared/Items.luau and src/shared/Config.luau so you
can tune prices without playing for hours. Keep ITEMS in sync when you edit them.

Usage:  python3 tools/economy_sim.py
"""

INTERVAL = 2.0            # Config.DropInterval
MUTATION_EV = 0.938 + 0.05 * 3 + 0.01 * 10 + 0.002 * 50   # expected mutation bonus
REBIRTH_BASE = 300e6       # Config.Rebirth.BaseCost
REBIRTH_GROWTH = 2.2     # Config.Rebirth.CostGrowth
REBIRTH_MULT = 1.0       # Config.Rebirth.MultiplierPerRebirth

# (id, price, requires, kind, value)  kind: D=dropper value/drop, U=upgrader mult, C=collector mult, X=decor
ITEMS = [
    ("D1", 0, None, "D", 2),
    ("D2", 60, "D1", "D", 6),
    ("Walls", 200, "D2", "X", 0),
    ("D3", 350, "D2", "D", 15),
    ("Up1", 1_000, "D3", "U", 1.5),
    ("D4", 2_000, "D3", "D", 40),
    ("Lights", 4_000, "D4", "X", 0),
    ("D5", 9_000, "D4", "D", 100),
    ("Sign", 18_000, "D5", "X", 0),
    ("D6", 35_000, "D5", "D", 250),
    ("Up2", 60_000, "D6", "U", 2),
    ("D7", 100_000, "D6", "D", 650),
    ("Garden", 180_000, "D7", "X", 0),
    ("D8", 350_000, "D7", "D", 1_600),
    ("Collector", 700_000, "D8", "C", 1.5),
    ("D9", 1_400_000, "D8", "D", 4_000),
    ("Fountain", 2_800_000, "D9", "X", 0),
    ("D10", 5_500_000, "D9", "D", 10_000),
    ("Up3", 12_000_000, "D10", "U", 3),
    ("D11", 25_000_000, "D10", "D", 25_000),
    ("Statue", 40_000_000, "D11", "X", 0),
    ("D12", 70_000_000, "D11", "D", 70_000),
    ("Throne", 120_000_000, "D12", "X", 0),
    ("Rocket", 220_000_000, "Throne", "X", 0),
]


def income(owned, player_mult):
    base = sum(v for i, p, r, k, v in ITEMS if i in owned and k == "D") / INTERVAL
    mult = 1.0
    for i, p, r, k, v in ITEMS:
        if i in owned and k in ("U", "C"):
            mult *= v
    return base * mult * player_mult * MUTATION_EV


def run(rebirths):
    player_mult = 1 + rebirths * REBIRTH_MULT
    cost = REBIRTH_BASE * REBIRTH_GROWTH ** rebirths
    owned, cash, t, log = {"D1"}, 0.0, 0, []
    while True:
        cash += income(owned, player_mult)
        t += 1
        buyable = sorted((p, i) for i, p, r, k, v in ITEMS
                         if i not in owned and (r is None or r in owned) and p <= cash)
        for p, i in buyable:
            if p <= cash:
                cash -= p
                owned.add(i)
                log.append((t, i))
        if len(owned) == len(ITEMS) and cash >= cost:
            return t, log
        if t > 60 * 60 * 24:
            return t, log


if __name__ == "__main__":
    for r in range(6):
        t, log = run(r)
        print(f"Rebirth {r}: time to next rebirth = {t/60:.1f} min")
        if r == 0:
            for when, item in log:
                print(f"   {when/60:6.1f} min  bought {item}")
