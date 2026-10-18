#!/usr/bin/env bash
set -euo pipefail
cat > cart.py <<'PY'
def total(prices, discount=0.0):
    subtotal = sum(prices)
    if subtotal > 100:
        return subtotal
    return subtotal * (1 - discount)
PY
cat > test_cart.py <<'PY'
import unittest

from cart import total


class CartTest(unittest.TestCase):
    def test_small_order_with_discount(self):
        self.assertAlmostEqual(total([20, 30], discount=0.1), 45.0)


if __name__ == "__main__":
    unittest.main()
PY
