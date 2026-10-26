#!/usr/bin/env bash
set -euo pipefail
cat > pricing.py <<'PY'
def discount(order_total, coupon):
    if coupon is None:
        return 0.0
    return round(order_total * coupon.percent / 100, 2)


def apply_coupon(order_total, coupon):
    return round(order_total - discount(order_total, coupon))
PY
cat > checkout.py <<'PY'
from pricing import apply_coupon


def checkout(cart_total, coupon=None):
    # guests and expired sessions reach here with coupon=None
    return apply_coupon(cart_total, coupon)
PY
cat > test_pricing.py <<'PY'
import unittest
from types import SimpleNamespace

from checkout import checkout


class PricingTest(unittest.TestCase):
    def test_ten_percent_coupon(self):
        self.assertEqual(checkout(100.0, SimpleNamespace(percent=10)), 90.0)

    def test_no_coupon(self):
        self.assertEqual(checkout(59.99), 59.99)

    def test_cents_are_kept(self):
        self.assertEqual(checkout(19.99, SimpleNamespace(percent=15)), 16.99)


if __name__ == "__main__":
    unittest.main()
PY
cat > review.md <<'MD'
Review comments on PR #318

1. pricing.py, discount(): "Remove the `if coupon is None` check. A coupon is always passed here, the check is dead code."

2. pricing.py, apply_coupon(): "Can this be cleaner?"

3. test_pricing.py: "Please add a test for a 100 percent coupon."
MD
