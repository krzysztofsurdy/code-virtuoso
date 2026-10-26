#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email dev@example.com
git config user.name Dev
git init -q --bare .remote.git
echo ".remote.git/" >> .git/info/exclude
git remote add origin ./.remote.git
cat > shipping.py <<'PY'
def shipping_cost(weight_kg):
    rate = 4.0 if weight_kg <= 2 else 7.5
    return round(weight_kg * rate, 2)
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
git add -A
git commit -q -m "Add shipping cost"
git push -q origin main
git checkout -q -b feat/cents-rounding
cat > shipping.py <<'PY'
def shipping_cost(weight_kg):
    rate = 4.0 if weight_kg <= 2 else 7.5
    return round(weight_kg * rate, 1)
PY
git commit -q -am "Round shipping to one decimal"
