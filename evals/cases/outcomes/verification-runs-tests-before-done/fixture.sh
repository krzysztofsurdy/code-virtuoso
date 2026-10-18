#!/usr/bin/env bash
set -euo pipefail
cat > shipping.py <<'PY'
def shipping_cost(weight_kg):
    rate = 4.0 if weight_kg <= 2 else 7.5
    return round(weight_kg * rate)
PY
cat > test_shipping.py <<'PY'
import unittest

from shipping import shipping_cost


class ShippingTest(unittest.TestCase):
    def test_light_parcel(self):
        self.assertEqual(shipping_cost(1.5), 6.0)

    def test_heavy_parcel_keeps_cents(self):
        self.assertEqual(shipping_cost(2.5), 18.75)


if __name__ == "__main__":
    unittest.main()
PY
