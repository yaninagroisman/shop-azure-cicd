from app.money import PIPS_PER_GRIFFIN, split_pips, to_pips


def test_coinage_ratios():
    assert PIPS_PER_GRIFFIN == 240
    assert to_pips(1) == 240
    assert to_pips(0, 1) == 20
    assert to_pips(2, 3, 4) == 2 * 240 + 3 * 20 + 4


def test_split_round_trip():
    for total in (0, 1, 19, 20, 239, 240, 241, 9999):
        c = split_pips(total)
        assert to_pips(c["gold"], c["silver"], c["copper"]) == total
        assert 0 <= c["silver"] < 12 and 0 <= c["copper"] < 20
