# Symfony Validator Component

## Installation

Install the Validator component via Composer:

```bash
composer require symfony/validator
```

## Core Concepts

The Validator component validates values against **Constraints** (rules) using **Validators** (logic):

- **Constraints**: Define validation rules applied to properties, getters, or entire classes
- **Validators**: Execute constraint logic and report violations
- **ConstraintViolationList**: Collects and provides access to validation errors

## Creating and Using Validators

### Create a Basic Validator

```php
use Symfony\Component\Validator\Validation;

$validator = Validation::createValidator();
```

### Validate Simple Values

```php
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validation;

$validator = Validation::createValidator();
$violations = $validator->validate('test', new Assert\Length(min: 10));

if (count($violations) > 0) {
    foreach ($violations as $violation) {
        echo $violation->getMessage();
    }
}
```

### Validate Objects

Define constraints using attributes, YAML, XML, or PHP mapping:

```php
use Symfony\Component\Validator\Constraints as Assert;

class User
{
    #[Assert\NotBlank]
    #[Assert\Email]
    private string $email;

    #[Assert\NotBlank]
    #[Assert\Length(min: 7)]
    private string $password;
}

$user = new User();
$violations = $validator->validate($user);
```

## Defining Constraints

### Using Attributes (Recommended)

```php
class Author
{
    #[Assert\NotBlank]
    #[Assert\Length(min: 3)]
    private string $firstName;

    #[Assert\Email]
    private string $email;
}
```

### Using YAML Mapping

```yaml
App\Entity\Author:
    properties:
        firstName:
            - NotBlank: ~
            - Length: { min: 3 }
        email:
            - Email: ~
```

### Using PHP Mapping with loadValidatorMetadata

```php
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Mapping\ClassMetadata;

class Author
{
    public static function loadValidatorMetadata(ClassMetadata $metadata): void
    {
        $metadata->addPropertyConstraint('firstName', new Assert\NotBlank());
        $metadata->addPropertyConstraint('firstName', new Assert\Length(min: 3));
        $metadata->addPropertyConstraint('email', new Assert\Email());
    }
}
```

Enable this loader:

```php
$validator = Validation::createValidatorBuilder()
    ->addMethodMapping('loadValidatorMetadata')
    ->getValidator();
```

## Loading Validation Resources

Configure the validator builder to load constraints from multiple sources:

```php
use Symfony\Component\Validator\Validation;

$validator = Validation::createValidatorBuilder()
    ->enableAttributeMapping()
    ->addMethodMapping('loadValidatorMetadata')
    ->addYamlMapping('config/validation.yaml')
    ->addXmlMapping('config/validation.xml')
    ->getValidator();
```

Add PSR-6 caching for performance:

```php
$validator = Validation::createValidatorBuilder()
    ->setMappingCache(new SomePsr6Cache())
    ->getValidator();
```

## Built-In Constraints

### Basic Constraints
- `NotBlank` - Value must not be blank
- `NotNull` - Value must not be null
- `IsNull` - Value must be null
- `IsTrue` - Value must be true
- `IsFalse` - Value must be false
- `Blank` - Value must be blank
- `Type(type: 'string')` - Value must be of specified type

### String Constraints
- `Email` - Valid email address
- `Url` - Valid URL
- `Uuid` - Valid UUID
- `Ulid` - Valid ULID format
- `Regex(pattern: '/.../')` - Matches regex pattern
- `Length(min: 3, max: 10)` - String length validation
- `Charset(charset: 'UTF-8')` - Valid character set
- `Json` - Valid JSON format
- `Hostname` - Valid hostname
- `Ip` - Valid IP address
- `Cidr` - Valid CIDR notation
- `MacAddress` - Valid MAC address
- `CssColor` - Valid CSS color
- `Twig` - Valid Twig syntax
- `Yaml` - Valid YAML syntax
- `ExpressionSyntax` - Valid expression syntax
- `PasswordStrength(minScore: 4)` - Strong password validation
- `NotCompromisedPassword` - Password not in breach databases
- `WordCount(max: 100)` - Word count validation
- `NoSuspiciousCharacters` - No suspicious Unicode characters

### Comparison Constraints
- `EqualTo(value: 5)` - Equal to a value
- `NotEqualTo(value: 5)` - Not equal to a value
- `IdenticalTo(value: 5)` - Identical to a value
- `NotIdenticalTo(value: 5)` - Not identical to a value
- `LessThan(value: 10)` - Less than a value
- `LessThanOrEqual(value: 10)` - Less than or equal
- `GreaterThan(value: 0)` - Greater than a value
- `GreaterThanOrEqual(value: 0)` - Greater than or equal
- `Range(min: 0, max: 100)` - Within a range
- `DivisibleBy(value: 5)` - Divisible by a number
- `Unique` - Unique value

### Number Constraints
- `Positive` - Must be positive
- `PositiveOrZero` - Must be positive or zero
- `Negative` - Must be negative
- `NegativeOrZero` - Must be negative or zero

### Date/Time Constraints
- `Date` - Valid date format
- `DateTime` - Valid datetime format
- `Time` - Valid time format
- `Timezone` - Valid timezone
- `Week` - Valid week format

### Choice Constraints
- `Choice(choices: ['a', 'b'])` - Value from predefined choices
- `Country` - Valid country code
- `Language` - Valid language code
- `Locale` - Valid locale

### File Constraints
- `File(maxSize: '5M')` - Valid file validation
- `Image(maxWidth: 800)` - Valid image file
- `Video` - Valid video file

### Financial Constraints
- `Iban` - Valid IBAN
- `Bic` - Valid BIC code
- `CardScheme(schemes: ['VISA'])` - Valid card scheme
- `Currency` - Valid currency code
- `Isbn` - Valid ISBN
- `Issn` - Valid ISSN
- `Isin` - Valid ISIN
- `Luhn` - Valid Luhn checksum

### Collection Constraints
- `Collection(fields: ['name' => ...])` - Validate array structures
- `Count(min: 1, max: 10)` - Collection size validation
- `All(constraints: [...])` - All items must pass constraints
- `Valid` - Validate nested objects
- `Cascade` - Cascade validation to nested objects

### Composite Constraints
- `AtLeastOneOf(constraints: [...])` - At least one constraint must pass
- `When(expression: '...', then: [...])` - Conditional constraint validation
- `Compound` - Combine multiple constraints
- `Sequentially(constraints: [...])` - Sequential constraint validation
- `Traverse` - Traverse nested structures
- `GroupSequence` - Define validation sequence

### Custom Logic Constraints
- `Callback(callback: 'validate')` - Custom callback validation
- `Expression(expression: '...')` - Expression-based validation

### Doctrine Constraints (with DoctrineBundle)
- `UniqueEntity(fields: ['email'])` - Unique database entity
- `EnableAutoMapping` - Enable automatic mapping
- `DisableAutoMapping` - Disable automatic mapping

## Creating Custom Constraints

### Create the Constraint Class

```php
use Symfony\Component\Validator\Constraint;

#[\Attribute]
class ContainsAlphanumeric extends Constraint
{
    public string $message = 'String contains illegal character: {{ string }}';
    public string $mode = 'strict';

    public function __construct(
        ?string $mode = null,
        ?string $message = null,
        ?array $groups = null,
        $payload = null
    ) {
        $this->mode = $mode ?? $this->mode;
        $this->message = $message ?? $this->message;
        parent::__construct(null, $groups, $payload);
    }
}
```

### Create the Validator Class

Auto-discovered by appending `Validator` to the constraint name:

```php
use Symfony\Component\Validator\Constraint;
use Symfony\Component\Validator\ConstraintValidator;
use Symfony\Component\Validator\Exception\UnexpectedTypeException;
use Symfony\Component\Validator\Exception\UnexpectedValueException;

class ContainsAlphanumericValidator extends ConstraintValidator
{
    public function validate(mixed $value, Constraint $constraint): void
    {
        if (!$constraint instanceof ContainsAlphanumeric) {
            throw new UnexpectedTypeException($constraint, ContainsAlphanumeric::class);
        }

        if (null === $value || '' === $value) {
            return;
        }

        if (!is_string($value)) {
            throw new UnexpectedValueException($value, 'string');
        }

        if (preg_match('/^[a-zA-Z0-9]+$/', $value)) {
            return;
        }

        $this->context->buildViolation($constraint->message)
            ->setParameter('{{ string }}', $value)
            ->addViolation();
    }
}
```

### Use Custom Constraints

```php
#[ContainsAlphanumeric(mode: 'loose')]
private string $username;
```

## Validation Groups

Validate specific groups of constraints instead of all constraints:

```php
class User
{
    #[Assert\Email(groups: ['registration'])]
    #[Assert\NotBlank(groups: ['registration'])]
    private string $email;

    #[Assert\Length(min: 2)]  // Default group
    private string $city;
}

$violations = $validator->validate($user, null, ['registration']);
```

## Sequential Group Validation

Stop validation at the first failed group:

```php
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\GroupSequenceProviderInterface;

#[Assert\GroupSequence(['User', 'Strict'])]
class User implements GroupSequenceProviderInterface
{
    #[Assert\NotBlank(groups: ['User'])]
    private string $username;

    #[Assert\IsTrue(
        message: 'Password cannot match username',
        groups: ['Strict']
    )]
    public function isPasswordSafe(): bool
    {
        return $this->username !== $this->password;
    }

    public function getGroupSequence(): array
    {
        return ['User', 'Strict'];
    }
}
```

## Validation by Metadata

Validate using property, getter, or class-level constraints:

```php
class Author
{
    #[Assert\Length(min: 3)]
    private string $firstName;

    #[Assert\IsTrue]
    public function isPasswordSafe(): bool
    {
        return $this->firstName !== $this->password;
    }

    #[Assert\Callback]
    public function validate(ExecutionContextInterface $context): void
    {
        // Custom class-level validation
    }
}
```

## Validating Arrays

```php
use Symfony\Component\Validator\Constraints as Assert;

$constraint = new Assert\Collection(fields: [
    'name' => [
        new Assert\NotBlank(),
        new Assert\Length(min: 3)
    ],
    'email' => new Assert\Email(),
    'tags' => new Assert\Optional(constraints: [
        new Assert\Type(type: 'array'),
        new Assert\All(constraints: [
            new Assert\NotBlank()
        ])
    ])
]);

$violations = $validator->validate($data, $constraint);
```

## Error Severity Levels

Assign different severity levels to constraints:

```php
class User
{
    #[Assert\NotBlank(payload: ['severity' => 'error'])]
    private string $username;

    #[Assert\Iban(payload: ['severity' => 'warning'])]
    private string $bankAccount;
}

// Access severity level
foreach ($violations as $violation) {
    $constraint = $violation->getConstraint();
    $severity = $constraint->payload['severity'] ?? null;
}
```

## Translation of Constraint Messages

Create translation files in the `validators` domain:

```yaml
# translations/validators/validators.en.yaml
author.name.not_blank: Please enter an author name.
```

Use custom message keys in constraints:

```php
#[Assert\NotBlank(message: 'author.name.not_blank')]
private string $name;
```

Or set a custom translation domain:

```php
public function validate($value, Constraint $constraint): void
{
    $this->context->buildViolation($constraint->message)
        ->setTranslationDomain('validation_errors')
        ->addViolation();
}
```

## Handling Constraint Violations

```php
$violations = $validator->validate($object);

if (count($violations) > 0) {
    foreach ($violations as $violation) {
        echo $violation->getPropertyPath() . ': ' . $violation->getMessage();
    }
}

// Filter by error code
$errors = $violations->findByCodes(['SOME_ERROR_CODE']);
```

## Common Configuration Options for Constraints

- `message` - Error message (supports parameter placeholders like `{{ value }}`)
- `groups` - Validation groups this constraint belongs to
- `payload` - Custom metadata for the constraint
- `when` - Conditional validation expression
- `allowNull` - Allow null values (bypasses constraint)
- `min`, `max` - Range limits
- `pattern`, `regex` - Pattern matching
- `charset` - Character set validation
- `mode` - Validation mode (e.g., 'strict', 'loose')

## Best Practices

- Always allow `null` and empty values in custom validators; let `NotBlank` and `NotNull` handle them
- Use validation groups to organize constraints logically
- Use custom constraints for business logic that can't be expressed with built-in constraints
- Apply constraints at the property level when validating individual fields
- Use class-level validation (Callback) for cross-field validation
- Leverage `payload` for metadata like severity levels or custom error handling
- Cache validator metadata with PSR-6 caching for production performance
- Test custom constraints with `ConstraintValidatorTestCase`
