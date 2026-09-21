# PHP Version Changes

Per-version summary of breaking changes, deprecations, and new features that affect upgrade decisions.

## Contents

- [PHP 8.0](#php-80)
- [PHP 8.1](#php-81)
- [PHP 8.2](#php-82)
- [PHP 8.3](#php-83)
- [PHP 8.4](#php-84)

---

## PHP 8.0

### New features

**Named arguments:**
```php
// Before
array_slice($array, 0, 3, true);

// After
array_slice($array, offset: 0, length: 3, preserve_keys: true);
```

**Match expressions (replaces switch):**
```php
$result = match($status) {
    'active' => 'User is active',
    'inactive', 'banned' => 'User is not active',
    default => 'Unknown status',
};
```

**Constructor property promotion:**
```php
class User
{
    public function __construct(
        private string $name,
        private string $email,
        private int $age,
    ) {}
}
```

**Union types:**
```php
function processInput(string|int $input): string|false { }
```

**Nullsafe operator:**
```php
$country = $user?->getAddress()?->getCountry()?->getCode();
```

**Attributes:**
```php
#[Route('/api/users', methods: ['GET'])]
public function list(): Response { }
```

### Breaking changes
- `\` is always treated as a literal backslash in strings with no escape sequence
- `match` is a reserved keyword
- Stricter type coercions for internal functions
- Sorting algorithms are now stable
- Concatenation operator precedence changed relative to `+` and `-`
- `0 == "foo"` is now `false` (saner string-to-number comparisons)

---

## PHP 8.1

### New features

**Enums:**
```php
enum Status: string
{
    case Active = 'active';
    case Inactive = 'inactive';

    public function label(): string
    {
        return match($this) {
            self::Active => 'Active User',
            self::Inactive => 'Inactive User',
        };
    }
}
```

**Readonly properties:**
```php
class User
{
    public function __construct(
        public readonly string $name,
        public readonly string $email,
    ) {}
}
```

**Fibers:**
```php
$fiber = new Fiber(function (): void {
    $value = Fiber::suspend('fiber started');
    echo "Fiber resumed with: $value";
});

$result = $fiber->start();       // 'fiber started'
$fiber->resume('hello');         // 'Fiber resumed with: hello'
```

**Intersection types:**
```php
function process(Countable&Iterator $collection): void { }
```

**`never` return type:**
```php
function redirect(string $url): never
{
    header("Location: $url");
    exit;
}
```

**First-class callable syntax:**
```php
$fn = strlen(...);
$fn = $object->method(...);
```

### Breaking changes
- `MYSQLI_STMT_ATTR_UPDATE_MAX_LENGTH` no longer has an effect
- `MYSQLI_STORE_RESULT_COPY_DATA` no longer has an effect
- Serialization of internal classes may have changed
- Several function return types were corrected in internal classes

---

## PHP 8.2

### New features

**Readonly classes:**
```php
readonly class UserDTO
{
    public function __construct(
        public string $name,
        public string $email,
        public int $age,
    ) {}
}
```

**Disjunctive Normal Form (DNF) types:**
```php
function process((Countable&Iterator)|null $input): void { }
```

**`true`, `false`, `null` as standalone types:**
```php
function alwaysTrue(): true { return true; }
function alwaysFalse(): false { return false; }
function alwaysNull(): null { return null; }
```

**Constants in traits:**
```php
trait HasVersion
{
    protected const VERSION = '1.0';
}
```

### Breaking changes and deprecations

**Dynamic properties deprecated (major impact):**
```php
// DEPRECATED - triggers E_DEPRECATED
class User
{
    public string $name;
}

$user = new User();
$user->name = 'John';     // OK
$user->age = 30;           // DEPRECATED - property not declared

// Temporary workaround
#[AllowDynamicProperties]
class LegacyUser { }

// Proper fix: declare all properties
class User
{
    public string $name;
    public int $age;        // declare the property
}
```

**`$GLOBALS` access restrictions:**
```php
// No longer allowed
$GLOBALS = [];
$ref = &$GLOBALS;

// Still allowed
$GLOBALS['key'] = 'value';
$val = $GLOBALS['key'];
```

- `utf8_encode()` and `utf8_decode()` deprecated. Use `mb_convert_encoding()` instead
- `strtolower()`, `strtoupper()`, `ucfirst()`, and related functions no longer depend on the locale
- `${var}` string interpolation deprecated. Use `{$var}` instead

---

## PHP 8.3

### New features

**Typed class constants:**
```php
class Config
{
    public const string DATABASE_HOST = 'localhost';
    public const int MAX_RETRIES = 3;
    protected const array DEFAULT_OPTIONS = ['timeout' => 30];
}
```

**`json_validate()` function:**
```php
if (json_validate($jsonString)) {
    $data = json_decode($jsonString, true);
}
```

**`#[Override]` attribute:**
```php
class ChildClass extends ParentClass
{
    #[Override]
    public function process(): void
    {
        // Compile-time error if parent::process() doesn't exist
    }
}
```

**`Randomizer` additions:**
```php
$randomizer = new \Random\Randomizer();
$randomizer->getBytesFromString('abcdefghijklmnopqrstuvwxyz', 10);
$randomizer->nextFloat();          // [0, 1)
$randomizer->getFloat(0.0, 1.0);   // inclusive bounds
```

**Dynamic class constant fetch:**
```php
$constName = 'MAX_RETRIES';
$value = Config::{$constName};
```

### Breaking changes
- `DateRangeError` replaces `ValueError` for out-of-range epochs in date functions
- `DateInvalidOperationException` for non-special relative time subtraction
- `mb_strimwidth()` with negative widths deprecated
- `NumberFormatter::TYPE_CURRENCY` deprecated
- `ldap_connect()` with 2 parameters deprecated
- Unserialize errors now always throw

---

## PHP 8.4

### New features

**Property hooks:**
```php
class User
{
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
        set (string $value) {
            [$this->firstName, $this->lastName] = explode(' ', $value, 2);
        }
    }

    public function __construct(
        private string $firstName,
        private string $lastName,
    ) {}
}
```

**Asymmetric visibility:**
```php
class BankAccount
{
    public private(set) float $balance;

    public function __construct(float $initial)
    {
        $this->balance = $initial;
    }

    public function deposit(float $amount): void
    {
        $this->balance += $amount;
    }
}

$account = new BankAccount(100.0);
echo $account->balance;      // OK - public read
$account->balance = 200.0;   // ERROR - private set
```

**`new` without wrapping parentheses in chained expressions:**
```php
// Before 8.4: the new expression had to be wrapped
$slug = (new Slugger('Hello World'))->slug();

// 8.4: method calls and property access can follow new directly
$slug = new Slugger('Hello World')->slug();
$result = new Collection([1, 2, 3])->map(fn($x) => $x * 2);
```

**`array_find()`, `array_find_key()`, `array_any()`, `array_all()`:**
```php
$users = [['name' => 'Alice', 'active' => true], ['name' => 'Bob', 'active' => false]];

$firstActive = array_find($users, fn($u) => $u['active']);
$hasActive = array_any($users, fn($u) => $u['active']);
$allActive = array_all($users, fn($u) => $u['active']);
```

### Breaking changes and deprecations

**Implicit nullable types deprecated (high impact):**
```php
// DEPRECATED
function save(string $name = null): void { }

// Fixed
function save(?string $name = null): void { }
```

This is one of the most widespread changes. Rector handles it.

**Other deprecations:**
- Session: changing `session.use_only_cookies`, `session.use_trans_sid`, `session.trans_sid_tags`, `session.trans_sid_hosts`, `session.referer_check`, `session.sid_length`, or `session.sid_bits_per_character` is deprecated, and so is the `SID` constant
- `session_set_save_handler()` with more than two arguments is deprecated. Use the two-argument form with a `SessionHandlerInterface` object
- `E_STRICT` constant deprecated
- `trigger_error()` with `E_USER_ERROR` deprecated. Throw an exception or call `exit()` instead
- Using `_` as a class name deprecated
- `lcg_value()` deprecated. Use `Random\Randomizer::getFloat()`
- DOM: the new `Dom` namespace classes (HTML5-compliant) are added, and the old `DOMDocument` and `DOMNode` classes remain. Only a few properties such as `DOMDocument::$actualEncoding` and the `DOM_PHP_ERR` constant are deprecated

### Rector configuration for 8.4

```php
use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php84: true);
```

Key Rector rules for 8.4:
- `ExplicitNullableParamTypeRector` - fixes implicit nullable parameters
