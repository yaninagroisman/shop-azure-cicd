"""The shop's coinage.

1 gold Griffin = 12 silver Shards, 1 Shard = 20 copper Pips  ->  1 Griffin = 240 Pips.
Prices are stored as a whole number of Pips so arithmetic stays exact.
"""
PIPS_PER_SHARD = 20
SHARDS_PER_GRIFFIN = 12
PIPS_PER_GRIFFIN = PIPS_PER_SHARD * SHARDS_PER_GRIFFIN


def to_pips(griffins: int = 0, shards: int = 0, pips: int = 0) -> int:
    return griffins * PIPS_PER_GRIFFIN + shards * PIPS_PER_SHARD + pips


def split_pips(total: int) -> dict:
    """Turn a Pip total into {"gold": griffins, "silver": shards, "copper": pips}."""
    gold, rest = divmod(total, PIPS_PER_GRIFFIN)
    silver, copper = divmod(rest, PIPS_PER_SHARD)
    return {"gold": gold, "silver": silver, "copper": copper}
