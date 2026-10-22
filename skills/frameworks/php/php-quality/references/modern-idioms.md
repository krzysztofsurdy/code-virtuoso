# Modern idioms for PHP 8.3 to 8.5

Features from earlier versions are included where the model often misuses them. Check the project's `composer.json` PHP constraint before using anything here. Each section names the manual page it comes from.

## Contents

- [Readonly properties and classes](#readonly-properties-and-classes)
- [Enums with interfaces](#enums-with-interfaces)
- [Typed class constants](#typed-class-constants)
- [Override attribute](#override-attribute)
- [Property hooks](#property-hooks)
- [Asymmetric visibility](#asymmetric-visibility)
- [Other 8.4 additions](#other-84-additions)
- [PHP 8.5 additions](#php-85-additions)
- [Choosing between hooks, asymmetric visibility and readonly](#choosing-between-hooks-asymmetric-visibility-and-readonly)
- [Sources](#sources)

## Readonly properties and classes

Readonly properties (8.1): typed, no default value, written once and only from the declaring scope. Since 8.4 a readonly property is implicitly `protected(set)`, before that `private(set)`. Since 8.3 a readonly property can be reinitialized inside `__clone()`, which makes deep clones possible. Objects held in readonly properties can still change internally.

Readonly classes (8.2): `readonly class` marks every declared property readonly and blocks dynamic properties.

```php
final readonly class Money
{
    public function __construct(
        public int $amount,
        public string $currency,
    ) {}
}
```

Traps:

- A readonly class can be extended only by another readonly class.
- A readonly class cannot declare untyped or static properties, and `#[\AllowDynamicProperties]` on it is a compile error.
- A readonly property cannot have a default value and cannot be initialized by reference.
- Readonly does not make a nested object immutable. A readonly `array` is immutable, a readonly `ArrayObject` is not.
- Readonly properties and property hooks do not combine. Use asymmetric visibility for controlled writes.

## Enums with interfaces

Enums (8.1) can have methods, constants and interfaces, and use traits that hold no properties. Any type check against the interface accepts every case. For a backed enum, the interface goes after the backing type.

```php
interface HasLabel
{
    public function label(): string;
}

enum Status: string implements HasLabel
{
    case Draft = 'draft';
    case Published = 'published';

    public function label(): string
    {
        return match ($this) {
            self::Draft => 'Draft',
            self::Published => 'Published',
        };
    }
}
```

Traps:

- An enum cannot hold per-instance state, and a trait used in an enum must not declare properties.
- Defining your own `cases()` method is not allowed.
- `from()` throws on an unknown value and `tryFrom()` returns `null`. Use `tryFrom()` at input boundaries and handle the null.
- Use an enum, not a class constant list, for a closed set of values. Use a `match` on `$this` in the enum rather than a `switch` in callers.

## Typed class constants

Since 8.3 a class constant can declare a type, including in interfaces. An implementing class must keep a compatible type, and since 8.3 the visibility of an interface constant is checked too.

```php
interface Currency
{
    public const string CODE = 'EUR';
}

final class Euro implements Currency
{
    public const string CODE = 'EUR';
}
```

Related 8.3 addition: dynamic class constant fetch, `Foo::{$name}`. The type may be a scalar type or `array` (arrays hold only scalars).

## Override attribute

`#[\Override]` (8.3) says a method must override a parent method or implement an interface method. If none exists, PHP raises a compile-time error. Since 8.5 it also applies to properties. It is not allowed on `__construct()`.

```php
final class StrictTest extends \PHPUnit\Framework\TestCase
{
    #[\Override]
    protected function setUp(): void
    {
    }
}
```

Add it to every method that overrides or implements one. It turns a typo or a renamed parent method into an immediate error instead of a method that is never called. PER-CS and PHPStan do not require it, so it is a habit to build into reviews. On a project that supports PHP below 8.3, the attribute is ignored by older PHP, so it is safe to add, but the safety net only works on 8.3 or later.

## Property hooks

Property hooks (8.4) put `get` and `set` logic on the property. They apply to non-static properties only, and not to `readonly` properties.

```php
final class User
{
    public string $email {
        set => strtolower($value);
    }

    public string $displayName {
        get => $this->first . ' ' . $this->last;
    }

    public function __construct(
        private string $first,
        private string $last,
        string $email,
    ) {
        $this->email = $email;
    }
}
```

Rules from the manual:

- A property with at least one hook that reads or writes `$this->prop` is backed and stores a value. A property whose hooks never reference itself is virtual, uses no memory, and a missing hook means that operation does not exist.
- `set(string $value)` may take a wider type than the property (contravariant). `set => expr;` stores the expression result.
- Hooks can be `final`. A child can override hooks independently and reach the parent with `parent::$prop::get()` and `parent::$prop::set($v)`.
- Hooks break indirect modification such as `$obj->arr['k'] = 'v'` unless the property defines only `&get`.
- Hooks work with constructor promotion, but the constructor parameter keeps the declared property type.
- Adding hooks in a child class drops the parent's default value, so redeclare it.

Use hooks for validation or normalization that used to live in a getter and setter pair. Do not use them to hide expensive work behind property syntax.

## Asymmetric visibility

Asymmetric visibility (8.4) sets a separate, narrower write scope.

```php
final class Counter
{
    public private(set) int $value = 0;

    public function increment(): void
    {
        $this->value++;
    }
}
```

Rules from the manual:

- Only typed properties may declare set visibility.
- Set visibility must be the same as, or narrower than, the read visibility. `protected public(set)` is a compile-time error.
- On a public property you can omit the read visibility: `private(set)` equals `public private(set)`.
- `private(set)` makes the property final, so a child cannot redeclare it.
- References and array writes follow the set visibility.
- A child may widen visibility, never narrow it.
- No spaces inside `private(set)`.
- Since 8.5, static properties can have set visibility.
- An `8.4` readonly property is implicitly `protected(set)`.

## Other 8.4 additions

| Feature | Use |
|---|---|
| `#[\Deprecated]` | Mark your own functions, methods and class constants so callers get a deprecation notice |
| `new` without parentheses | `new Foo()->bar()`. PER-CS 3.0 says to drop the wrapping parentheses when targeting 8.4 or later |
| `array_find()`, `array_find_key()`, `array_any()`, `array_all()` | Replace `foreach` search loops with a callback |

## PHP 8.5 additions

Pipe operator (`|>`): the right side is a callable that takes one parameter. The left value goes in and the callable result comes out.

```php
$slug = $title
    |> trim(...)
    |> (fn (string $s): string => str_replace(' ', '-', $s))
    |> strtolower(...);
```

Rules from the manual: functions with more than one required parameter fail, functions that take a variable by reference are not allowed, an invalid callable throws `Error`, and arrow functions must be wrapped in parentheses.

`clone` with properties: `clone($this, ['amount' => $amount])` returns a modified copy and supports "with-er" methods on readonly classes. PER-CS 3.1 says to always call `clone` with parentheses.

`#[\NoDiscard]`: PHP warns when the return value of a marked function is ignored. Cast to `(void)` to discard on purpose. Before 8.5 the attribute does nothing and the `(void)` cast is not supported, so use `$_ = f();` on older versions.

Smaller additions listed on the release page: `array_first()` and `array_last()` (return `null` for an empty array), closures and first-class callables in constant expressions, `#[\Override]` on properties, and the URI extension.

## Choosing between hooks, asymmetric visibility and readonly

| Need | Use |
|---|---|
| Immutable value, set once in the constructor | `readonly` property or `readonly class` |
| Public read, internal write that can change over time | `public private(set)` |
| Normalize or validate on write | `set` hook (not on `readonly`) |
| Value computed from other state | Virtual property with a `get` hook |
| Copy with one field changed | `clone($this, [...])` on 8.5, otherwise a constructor call |

## Sources

| Feature | URL |
|---|---|
| Properties and readonly | https://www.php.net/manual/en/language.oop5.properties.php |
| Readonly classes | https://www.php.net/manual/en/language.oop5.basic.php |
| Enums | https://www.php.net/manual/en/language.enumerations.methods.php, https://www.php.net/manual/en/language.enumerations.traits.php |
| Class constants | https://www.php.net/manual/en/language.oop5.constants.php |
| Override | https://www.php.net/manual/en/class.override.php |
| Property hooks | https://www.php.net/manual/en/language.oop5.property-hooks.php |
| Asymmetric visibility | https://www.php.net/manual/en/language.oop5.visibility.php |
| Pipe operator | https://www.php.net/manual/en/language.operators.functional.php |
| NoDiscard | https://www.php.net/manual/en/class.nodiscard.php |
| Release pages | https://www.php.net/releases/8.3/en.php, https://www.php.net/releases/8.4/en.php, https://www.php.net/releases/8.5/en.php |
