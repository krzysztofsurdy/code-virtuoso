# Example PR Messages

Real-world examples demonstrating the PR template applied to different change types.

---

## Example 1: Feature -- Add Product Review System

### Title
```
SHOP-1042 Add product review system with ratings and moderation
```

### What have I changed

#### Database and Entity/Model Changes

**New `ProductReview` model:** `id` (UUID), `product_id` (FK), `user_id` (FK), `rating` (int 1-5), `comment` (text, nullable), `status` (enum: pending/approved/rejected), timestamps.

**Migration `20260215120000_create_product_reviews`** creates `product_review` table with unique constraint on `(product_id, user_id)` and index on `(product_id, status)`.

#### API Changes (REST/GraphQL)

**New `submitReview` mutation** -- authenticated users submit a review for a purchased product. Validates purchase history, duplicate prevention, and rating range.

**New `productReviews` query** -- paginated approved reviews with `averageRating` computed field. Updated `product` query includes `averageRating` and `reviewCount`.

#### Caching and Performance

Cache key `product_avg_rating:{productId}` with 1-hour TTL, invalidated on admin approve/reject. Cursor-based pagination on reviews query.

#### Admin Interface Changes

New "Product Reviews" admin page: list with filters (status, rating range), bulk approve/reject, detail view with moderation buttons.

### Testing instructions

**Prerequisites:**
- A customer account that has purchased at least one product (e.g., product "Wireless Headphones")
- An admin account with access to the admin panel

### Test scenarios

- [ ] **Scenario 1: Customer submits a review**
  1. Log in as the customer
  2. Open GraphQL Playground at `https://your-staging.example.com/graphql`
  3. Paste and execute:
     ```graphql
     mutation {
       submitReview(input: { productId: "prod-001", rating: 5, comment: "Excellent quality." }) {
         review { id, status, rating }
         errors { field, message }
       }
     }
     ```

  **Expected results:**
  - The response contains `status: "pending"` and `rating: 5`
  - The `errors` field is empty/null
  - Note down the returned `id` for later scenarios

- [ ] **Scenario 2: Pending review is NOT visible to the public**
  1. Open GraphQL Playground (no login required, or log in as a different user)
  2. Paste and execute:
     ```graphql
     query {
       productReviews(productId: "prod-001", first: 10) {
         edges { node { id, rating, comment, createdAt } }
         averageRating
         totalCount
       }
     }
     ```

  **Expected results:**
  - The review submitted in Scenario 1 does NOT appear in the list
  - The `averageRating` and `totalCount` do not include the pending review

- [ ] **Scenario 3: Admin approves the review**
  1. Log in as admin
  2. Go to `https://your-staging.example.com/admin/product-reviews`
  3. In the status filter dropdown, select "Pending"
  4. Find the review you submitted in Scenario 1
  5. Click the "Approve" button next to it

  **Expected results:**
  - A green success message appears
  - The review status changes to "Approved"
  - The review disappears from the "Pending" filtered list

- [ ] **Scenario 4: Approved review is now visible to the public**
  1. Repeat Scenario 2 (run the same query in GraphQL Playground)

  **Expected results:**
  - The approved review now appears in the list
  - The `averageRating` reflects the new rating (should be 5.0 if this is the only review)
  - The `totalCount` has increased by 1

- [ ] **Scenario 5: Customer cannot submit a duplicate review**
  1. Log in as the same customer from Scenario 1
  2. Run the same mutation from Scenario 1 again (same product)

  **Expected results:**
  - The response contains a validation error saying the user already reviewed this product
  - No new review is created in the database

### Database verification

```sql
-- Check the most recent reviews
SELECT pr.id, pr.rating, pr.status, p.name, u.email
FROM product_review pr
JOIN product p ON pr.product_id = p.id
JOIN "user" u ON pr.user_id = u.id
ORDER BY pr.created_at DESC LIMIT 5;

-- Verify average ratings are correct
SELECT p.id, ROUND(AVG(pr.rating), 2) AS avg_rating, COUNT(pr.id) AS cnt
FROM product p
LEFT JOIN product_review pr ON pr.product_id = p.id AND pr.status = 'approved'
GROUP BY p.id HAVING COUNT(pr.id) > 0 LIMIT 10;
```

### Product changes
- Users can leave 1-5 star reviews on purchased products
- Reviews require admin approval before becoming visible
- Product pages show average rating and review count

---

## Example 2: Bug Fix -- Cart Quantity Not Preserved on Validation Error

### Title
```
SHOP-987 Fix cart quantity reset when validation fails on checkout
```

### What have I changed

#### Root Cause

The cart update logic cleared cart items *before* validation. If validation failed, original quantities were lost.

#### Fix

Reordered to validate first, persist second:

**Before:** Clear items -> Insert updated -> Validate -> Rollback (quantities lost)
**After:** Validate -> If error, return (cart untouched) -> Clear items -> Insert updated

**Files changed:**
- Cart service -- reordered validation and deletion
- Stock availability validator -- extracted standalone validation
- Unit tests -- quantity preservation test
- Integration tests -- full checkout flow test

### Testing instructions

**Prerequisites:**
- A customer account
- At least one product in the shop with limited stock (e.g., only 5 items available)

### Test scenarios

- [ ] **Scenario 1: Cart quantity is preserved when entering an invalid amount**
  1. Log in as a customer
  2. Go to the shop and add any product to your cart
  3. Go to your cart page at `https://your-staging.example.com/cart`
  4. Change the quantity to 2 and click "Update"
  5. Now change the quantity to 9999 (far more than available stock) and click "Update"

  **Expected results:**
  - A validation error message about insufficient stock is displayed
  - The quantity field still shows 2 (not reset to 1, 0, or empty)
  - The product remains in the cart

- [ ] **Scenario 2: Setting quantity to zero removes the item**
  1. With a product in your cart, change the quantity to 0
  2. Click "Update"

  **Expected results:**
  - The item is removed from the cart
  - The cart total is recalculated without that item

- [ ] **Scenario 3: Negative quantity is rejected**
  1. With a product in your cart, change the quantity to -1
  2. Click "Update"

  **Expected results:**
  - A validation error is displayed
  - The original quantity remains unchanged
  - The product stays in the cart

- [ ] **Scenario 4: Exact stock limit succeeds**
  1. Check the available stock for a product (run: `SELECT stock FROM product WHERE id = '<product-id>';`)
  2. Set the cart quantity to exactly that stock number
  3. Click "Update"

  **Expected results:**
  - The quantity is accepted without errors
  - The cart updates to show the new quantity and recalculated total

- [ ] **Scenario 5: Multiple items -- one invalid does not affect others**
  1. Add two different products to your cart (e.g., quantity 2 each)
  2. Change one product's quantity to 9999 (invalid) and leave the other at 2
  3. Click "Update"

  **Expected results:**
  - A validation error is displayed for the invalid item
  - Both items retain their previous quantities (2 each)
  - No quantities were changed for any item in the cart

**API alternative (if UI is not available):** Open GraphQL Playground at `https://your-staging.example.com/graphql` and run:
```graphql
mutation {
  updateCartItem(input: { cartItemId: "item-001", quantity: 9999 }) {
    cart { items { id, quantity } }
    errors { field, message }
  }
}
```
Expected: `errors` contains a stock validation message, and `cart.items` shows the original quantity (not 9999).

### Product changes
- Cart quantities no longer reset on validation errors during checkout

---

## Example 3: Feature -- Add Quiz Question Pool with Admin Management

### Title
```
EDU-2103 Add quiz question pool system with admin CRUD and ordering
```

### What have I changed

#### Database and Entity/Model Changes

**New `QuizPool` model:** `id`, `name` (unique), `description`, `is_active`, timestamps.

**New `QuizQuestion` model:** `id`, `question_text`, `question_type` (multiple_choice/true_false/free_text), `difficulty` (easy/medium/hard), `options` (JSON), `correct_answer`, timestamps.

**New `QuizQuestionPool` join model:** `quiz_pool_id` (FK), `quiz_question_id` (FK), `position` (int for ordering). Unique constraint on `(quiz_pool_id, quiz_question_id)`.

**Migration `20260220090000_create_quiz_tables`** creates all three tables.

#### Admin Interface Changes

**Quiz Pools list:** name, question count, active status, date. Filters: active/inactive, date range.

**Create/Edit form:** name (required, unique), description, active toggle, question assignment panel with search-and-select, drag-and-drop reordering, duplicate prevention (assigned questions grayed out).

**QuizQuestion admin:** list with type/difficulty/pool count, dynamic options field for multiple choice, question preview.

#### Event Handling

`QuizPoolQuestionAdded` and `QuizPoolQuestionRemoved` events dispatched on changes. Handler updates pool `updated_at`.

### Testing instructions

**Prerequisites:**
- An admin account with access to the admin panel
- At least 5 quiz questions should exist in the system. If not, create them first via the admin panel at `https://your-staging.example.com/admin/quiz-questions` (click "Create New", fill in question text, select type, set difficulty, add answer options)

### Test scenarios

- [ ] **Scenario 1: Create a new quiz pool and assign questions**
  1. Log in as admin
  2. Go to `https://your-staging.example.com/admin/quiz-pools`
  3. Click the "Create New" button
  4. Enter "JavaScript Fundamentals" in the Name field
  5. Enter a description (e.g., "Basic JS questions for beginners")
  6. Toggle "Active" to ON
  7. In the question assignment panel on the right, type a keyword in the search box to find questions
  8. Click on a question to add it to the pool. Repeat for 3-4 questions
  9. Drag and drop the questions to reorder them (e.g., move the third question to first position)
  10. Click "Save"

  **Expected results:**
  - A success message appears
  - The pool "JavaScript Fundamentals" appears in the pools list
  - The pool shows the correct number of assigned questions

- [ ] **Scenario 2: Question ordering persists after reload**
  1. From the quiz pools list, click on "JavaScript Fundamentals" to edit it

  **Expected results:**
  - The questions appear in the exact order you set in Scenario 1
  - The first question is the one you dragged to position 1

- [ ] **Scenario 3: Duplicate question prevention**
  1. While editing the "JavaScript Fundamentals" pool, search for a question that is already assigned to it

  **Expected results:**
  - That question appears grayed out in the search results
  - Clicking on it does nothing (it cannot be added again)

- [ ] **Scenario 4: Question list shows pool count**
  1. Go to `https://your-staging.example.com/admin/quiz-questions`
  2. Find a question you assigned to the pool in Scenario 1

  **Expected results:**
  - The "Pools" column shows "1" (or the correct number of pools it belongs to)
  - If you assigned the same question to multiple pools, the count reflects that

### Database verification

```sql
SELECT id, name, is_active FROM quiz_pool ORDER BY created_at DESC LIMIT 5;

SELECT qp.name, qq.question_text, qqp.position
FROM quiz_question_pool qqp
JOIN quiz_pool qp ON qqp.quiz_pool_id = qp.id
JOIN quiz_question qq ON qqp.quiz_question_id = qq.id
WHERE qp.name = 'JavaScript Fundamentals'
ORDER BY qqp.position ASC;

-- Verify no duplicates
SELECT quiz_pool_id, quiz_question_id, COUNT(*) FROM quiz_question_pool
GROUP BY quiz_pool_id, quiz_question_id HAVING COUNT(*) > 1;
```

### Product changes
- Administrators can organize questions into named, ordered pools
- Questions can be shared across pools
- Foundation for quiz/assessment delivery feature

---

## Example 4: Feature -- Add User Preference Tracking Field

### Title
```
USR-455 Add notification_preference field to user profile
```

### What have I changed

#### Database and Entity/Model Changes

**Updated `User` model** with `notification_preference` (enum: all/important_only/none, nullable). Default `NULL` means unset. Can be updated but not cleared back to `NULL`.

**Migration `20260222140000_add_notification_preference`:**
```sql
ALTER TABLE "user" ADD COLUMN notification_preference VARCHAR(20) DEFAULT NULL;
```

#### API Changes (REST/GraphQL)

**New `setNotificationPreference` mutation** -- requires auth, accepts `ALL`/`IMPORTANT_ONLY`/`NONE`, returns updated profile. Users can only set their own preference.

**Updated `me` query** -- includes `notificationPreference` (null if unset).

#### Security and Permissions

Auth check ensures user matches target. Admins can set any user's preference via `adminSetNotificationPreference`. Rate limited to 10 calls/minute/user.

### Testing instructions

**Prerequisites:**
- A regular user account (e.g., email: `testuser@example.com`)
- An admin account
- Access to GraphQL Playground at `https://your-staging.example.com/graphql`

### Test scenarios

- [ ] **Scenario 1: User sets their notification preference**
  1. Log in as the regular user
  2. Open GraphQL Playground at `https://your-staging.example.com/graphql`
  3. Paste and execute:
     ```graphql
     mutation {
       setNotificationPreference(input: { preference: IMPORTANT_ONLY }) {
         user { id, email, notificationPreference }
         errors { field, message }
       }
     }
     ```

  **Expected results:**
  - The response shows `notificationPreference: "IMPORTANT_ONLY"`
  - The `errors` field is empty/null
  - The user's email matches the logged-in account

- [ ] **Scenario 2: Verify preference is persisted**
  1. Still logged in as the same user, paste and execute:
     ```graphql
     query {
       me { id, notificationPreference }
     }
     ```

  **Expected results:**
  - `notificationPreference` shows `"IMPORTANT_ONLY"` (the value set in Scenario 1)

- [ ] **Scenario 3: Unauthenticated user is rejected**
  1. Log out (or open a new incognito browser tab)
  2. Open GraphQL Playground at `https://your-staging.example.com/graphql`
  3. Run the same mutation from Scenario 1 (without being logged in)

  **Expected results:**
  - The response contains an authentication error (HTTP 401 or an error message saying "not authenticated")
  - No preference is changed

- [ ] **Scenario 4: Invalid preference value is rejected**
  1. Log in as the regular user
  2. Paste and execute:
     ```graphql
     mutation {
       setNotificationPreference(input: { preference: INVALID_VALUE }) {
         user { id, notificationPreference }
         errors { field, message }
       }
     }
     ```

  **Expected results:**
  - The response contains a validation error
  - The user's preference remains unchanged (still `"IMPORTANT_ONLY"` from Scenario 1)

- [ ] **Scenario 5: Admin can override another user's preference**
  1. Log in as the admin
  2. Paste and execute (replace `user-042` with the actual user ID from Scenario 1):
     ```graphql
     mutation {
       adminSetNotificationPreference(input: { userId: "user-042", preference: NONE }) {
         user { id, notificationPreference }
       }
     }
     ```

  **Expected results:**
  - The response shows `notificationPreference: "NONE"` for the target user
  - No error is returned

- [ ] **Scenario 6: Non-admin cannot use the admin override**
  1. Log in as the regular user (not admin)
  2. Run the same admin mutation from Scenario 5, targeting any other user

  **Expected results:**
  - The response contains a permission error
  - The target user's preference is not changed

### Database verification

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user' AND column_name = 'notification_preference';

SELECT id, email, notification_preference FROM "user"
WHERE notification_preference IS NOT NULL ORDER BY updated_at DESC LIMIT 10;

SELECT notification_preference, COUNT(*) FROM "user"
GROUP BY notification_preference ORDER BY COUNT(*) DESC;
```

### Product changes
- Users can set notification preference from profile settings
- Default is unset until user makes explicit choice
- Admins can override via admin panel

---

## Example 5: Bug Fix -- Prevent Double Submit on Checkout

### Title
```
EDU-3301 Add button cooldown to prevent double payment submission
```

### What have I changed

#### Root Cause

Users clicking the pay button multiple times during slow network conditions caused duplicate payment attempts. The button remained active while the request was in flight.

#### Fix

Added a 15-second cooldown on the checkout confirm button. On click, the button immediately disables and shows "Processing..." text. After 15 seconds (or on server response, whichever comes first), the button re-enables.

**Files changed:**
- Checkout payment form -- added cooldown logic to submit handler
- Checkout confirm template -- added processing text data attribute to button
- Payment form tests -- button state tests

### Testing instructions

**Prerequisites:**
- A student account (e.g., email: `qa-student@example.com`, password: `TestPass123!`)
- The student must NOT already have an active subscription
- Payment test mode must be enabled on the staging environment

**Test data:**
- Successful payment card: `4242 4242 4242 4242`, expiry `03/34`, CVC `123`
- Declined card: `4000 0000 0000 0002`, expiry `03/34`, CVC `123`
- 3D Secure card: `4000 0000 0000 3220`, expiry `03/34`, CVC `123`

### Test scenarios

- [ ] **Scenario 1: Button cooldown on checkout page**
  1. Log in as a student
  2. Click "Store" in the main navigation menu (or go directly to `/en/account/internal-store`)
  3. Click "Start your free trial" (or select a package and click "Proceed to checkout")
  4. You are redirected to the checkout page (URL will look like `/en/account/store/m2m-checkout/...`)
  5. Fill in the card details: number `4242 4242 4242 4242`, expiry `03/34`, CVC `123`
  6. Check the "Terms and Conditions" and "Age above 18" checkboxes
  7. Click the confirm/pay button

  **Expected results:**
  - The confirm button immediately becomes disabled (grayed out, not clickable)
  - The button text changes to "Processing..."
  - The button remains disabled for approximately 15 seconds
  - After ~15 seconds (or when the server responds), the button re-enables with the original label
  - If payment succeeded, you are redirected to the success page

- [ ] **Scenario 2: Rapid double-click does NOT create duplicate payments**
  1. Log in as a different student (or clear the previous subscription: `DELETE FROM subscription WHERE user_id = '<user-id>';`)
  2. Navigate to `/en/account/internal-store` and proceed to checkout
  3. Fill in card details: `4242 4242 4242 4242`, expiry `03/34`, CVC `123`
  4. Check both checkboxes
  5. Click the confirm button and immediately try to click it again as fast as possible

  **Expected results:**
  - Only ONE payment attempt is made (the second click does nothing because the button is already disabled)
  - You are redirected to the success page normally
  - Check the database: only one payment record exists for this checkout

- [ ] **Scenario 3: Button re-enables after declined payment**
  1. Navigate to checkout as a student
  2. Fill in the DECLINED card: `4000 0000 0000 0002`, expiry `03/34`, CVC `123`
  3. Check both checkboxes
  4. Click the confirm button

  **Expected results:**
  - The button disables and shows "Processing..."
  - An error message appears (e.g., "Your card was declined")
  - The button re-enables so the user can try again with a different card
  - No payment record is created in the database

- [ ] **Scenario 4: Button re-enables after 3D Secure flow**
  1. Navigate to checkout as a student
  2. Fill in the 3D Secure card: `4000 0000 0000 3220`, expiry `03/34`, CVC `123`
  3. Check both checkboxes
  4. Click the confirm button

  **Expected results:**
  - The button disables and shows "Processing..."
  - A 3D Secure popup/redirect appears
  - Complete the 3D Secure challenge (click "Complete" or "Authenticate" in the test popup)
  - After returning, the payment processes normally and you are redirected to success

### Database verification

```sql
-- Check for duplicate payment attempts for a user
SELECT id, user_id, amount, status, created_at
FROM payment
WHERE user_id = '<user-id>'
ORDER BY created_at DESC LIMIT 5;

-- Verify only one successful payment per checkout session
SELECT checkout_session_id, COUNT(*) as payment_count
FROM payment
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY checkout_session_id
HAVING COUNT(*) > 1;
```

### Product changes
- Checkout confirm button shows "Processing..." and disables during payment
- Prevents accidental double payments from rapid clicking or slow networks
