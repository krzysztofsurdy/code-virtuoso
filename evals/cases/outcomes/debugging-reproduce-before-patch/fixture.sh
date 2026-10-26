#!/usr/bin/env bash
set -euo pipefail
cat > orders.py <<'PY'
import re


def parse_price(text):
    cleaned = text.replace("$", "").strip()
    return float(re.match(r"\d+(\.\d+)?", cleaned).group())


def order_total(lines):
    return sum(parse_price(price) * qty for price, qty in lines)


def discount(total):
    """Orders of 100 or more get 10% off."""
    return round(total * 0.9, 2) if total > 100 else total


def checkout(lines):
    return discount(order_total(lines))
PY
cat > test_orders.py <<'PY'
import unittest

from orders import checkout


class OrdersTest(unittest.TestCase):
    def test_small_order_has_no_discount(self):
        self.assertEqual(checkout([("$40.00", 1)]), 40.0)

    def test_order_over_100_gets_discount(self):
        self.assertEqual(checkout([("$60.00", 2)]), 108.0)


if __name__ == "__main__":
    unittest.main()
PY
