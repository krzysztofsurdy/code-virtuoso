# PHP Version Changes

Per-version summary of breaking changes, deprecations, and new features that affect upgrade decisions.

---

## PHP 8.0

### New Features

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

### Breaking Changes
- `\` is now always treated as a literal backslash in strings with no escape sequence
- `match` is a reserved keyword
- Stricter type coercions for internal functions
- Sorting algorithms are now stable
- Concatenation operator precedence changed relative to `+` and `-`
- `0 == "foo"` is now `false` (saner string-to-number comparisons)

---

## PHP 8.1

### New Features

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

### Breaking Changes
- `MYSQLI_STMT_ATTR_UPDATE_MAX_LENGTH` no longer has an effect
- `MYSQLI_STORE_RESULT_COPY_DATA` no longer has an effect
- Serialization of internal classes may have changed
- Several function return types were corrected in internal classes

---

## PHP 8.2

### New Features

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

### Breaking Changes and Deprecations

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

- `utf8_encode()` and `utf8_decode()` deprecated - use `mb_convert_encoding()` instead
- `${var}` string interpolation deprecated - use `{$var}` instead

---

## PHP 8.3

### New Features

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

### Breaking Changes
- `DateRangeError` replaces `ValueError` for out-of-range epochs in date functions
- `DateInvalidOperationException` for non-special relative time subtraction
- `mb_strimwidth()` with negative widths deprecated
- `NumberFormatter::TYPE_CURRENCY` deprecated
- `ldap_connect()` with 2 parameters deprecated
- Unserialize errors now always throw

---

## PHP 8.4

### New Features

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

**`new` without parentheses in expressions:**
```php
$length = new String('hello')->length();
$result = new Collection([1, 2, 3])->map(fn($x) => $x * 2);
```

**`array_find()`, `array_find_key()`, `array_any()`, `array_all()`:**
```php
$users = [['name' => 'Alice', 'active' => true], ['name' => 'Bob', 'active' => false]];

$firstActive = array_find($users, fn($u) => $u['active']);
$hasActive = array_any($users, fn($u) => $u['active']);
$allActive = array_all($users, fn($u) => $u['active']);
```

### Breaking Changes and Deprecations

**Implicit nullable types deprecated (high impact):**
```php
// DEPRECATED
function save(string $name = null): void { }

// Fixed
function save(?string $name = null): void { }
```

This is one of the most widespread changes - Rector handles it automatically.

**Other deprecations:**
- GET/POST session tracking deprecated (non-cookie session handling)
- `session_set_save_handler()` with individual callbacks deprecated - use `SessionHandlerInterface`
- DOM extension: `DOMDocument`, `DOMElement` etc. old methods deprecated in favor of `\Dom\` namespace classes
- `E_STRICT` constant deprecated
- `strtolower()`/`strtoupper()` no longer locale-sensitive
- Calling `new` without parentheses on no-argument constructors deprecated: `new Foo;` should be `new Foo()`

### Rector Configuration for 8.4

```php
use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php84: true);
```

Key Rector rules for 8.4:
- `ExplicitNullableParamTypeRector` - fixes implicit nullable parameters
- `NullToStrictStringFuncCallArgRector` - fixes null arguments to string functions
