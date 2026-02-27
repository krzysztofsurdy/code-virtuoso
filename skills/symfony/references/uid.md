# Symfony UID Component

## Installation

```bash
composer require symfony/uid
```

## UUIDs

UUIDs are 128-bit numbers represented as `xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx` (M = version, N = variant).

### UUID Versions

```php
use Symfony\Component\Uid\Uuid;

// v1: Time-based (timestamp + MAC address)
$uuid = Uuid::v1();

// v3: Name-based (MD5 hash)
$uuid = Uuid::v3(Uuid::fromString(Uuid::NAMESPACE_DNS), 'example.com');

// v4: Random
$uuid = Uuid::v4();

// v5: Name-based (SHA-1 hash, more secure than v3)
$uuid = Uuid::v5(Uuid::fromString(Uuid::NAMESPACE_DNS), 'example.com');

// v6: Reordered time-based (lexicographically sortable)
$uuid = Uuid::v6();

// v7: UNIX Timestamp (RECOMMENDED - time-ordered, better entropy)
$uuid = Uuid::v7();

// v8: Custom/experimental
$uuid = Uuid::v8('d9e7a184-5d5b-11ea-a62a-3499710062d0');
```

**Named UUID Namespaces:** `Uuid::NAMESPACE_DNS`, `Uuid::NAMESPACE_URL`, `Uuid::NAMESPACE_OID`, `Uuid::NAMESPACE_X500`

### Creating from Existing Values

```php
$uuid = Uuid::fromString('d9e7a184-5d5b-11ea-a62a-3499710062d0');
$uuid = Uuid::fromBinary("\xd9\xe7\xa1\x84\x5d\x5b\x11\xea\xa6\x2a\x34\x99\x71\x00\x62\xd0");
$uuid = Uuid::fromBase32('6SWYGR8QAV27NACAHMK5RG0RPG');
$uuid = Uuid::fromBase58('TuetYWNHhmuSQ3xPoVLv9M');
$uuid = Uuid::fromRfc4122('d9e7a184-5d5b-11ea-a62a-3499710062d0');
```

### Converting UUIDs

```php
$uuid = Uuid::fromString('d9e7a184-5d5b-11ea-a62a-3499710062d0');

$uuid->toBinary();   // 16-byte binary string
$uuid->toBase32();   // "6SWYGR8QAV27NACAHMK5RG0RPG"
$uuid->toBase58();   // "TuetYWNHhmuSQ3xPoVLv9M"
$uuid->toRfc4122();  // "d9e7a184-5d5b-11ea-a62a-3499710062d0"
$uuid->toHex();      // "0xd9e7a1845d5b11eaa62a3499710062d0"
$uuid->toString();   // "d9e7a184-5d5b-11ea-a62a-3499710062d0"
```

### Converting Between UUID Versions

```php
$uuid = Uuid::v1();
$uuid->toV6(); // returns UuidV6
$uuid->toV7(); // returns UuidV7

$uuid = Uuid::v6();
$uuid->toV7(); // returns UuidV7
```

### Validating and Comparing

```php
// Validate
Uuid::isValid('d9e7a184-5d5b-11ea-a62a-3499710062d0'); // true

// Validate specific formats
Uuid::isValid($value, Uuid::FORMAT_RFC_4122);
Uuid::isValid($value, Uuid::FORMAT_BASE_32 | Uuid::FORMAT_BASE_58);

// Compare
$uuid1->equals($uuid2);  // bool
$uuid1->compare($uuid2); // int (<0, 0, >0)

// Get datetime (time-based UUIDs only)
$uuid = Uuid::v1();
$uuid->getDateTime(); // \DateTimeImmutable

// Check type
$uuid instanceof \Symfony\Component\Uid\UuidV4; // true
$uuid instanceof \Symfony\Component\Uid\NilUuid; // false
```

**Format constants:** `FORMAT_BINARY`, `FORMAT_BASE_32`, `FORMAT_BASE_58`, `FORMAT_RFC_4122`, `FORMAT_RFC_9562`, `FORMAT_ALL`

### UUID Factory

```php
use Symfony\Component\Uid\Factory\UuidFactory;

class FooService
{
    public function __construct(private UuidFactory $uuidFactory) {}

    public function generate(): void
    {
        $uuid = $this->uuidFactory->create();              // default (v7)
        $uuid = $this->uuidFactory->randomBased()->create(); // v4
        $uuid = $this->uuidFactory->nameBased($namespace)->create($name); // v5
        $uuid = $this->uuidFactory->timeBased()->create();  // v7
    }
}
```

**Configure factory defaults:**

```yaml
# config/packages/uid.yaml
framework:
    uid:
        default_uuid_version: 7
        name_based_uuid_version: 5
        name_based_uuid_namespace: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
        time_based_uuid_version: 7
        time_based_uuid_node: 121212121212
```

## ULIDs

ULIDs are 128-bit numbers represented as 26-character strings (`TTTTTTTTTTRRRRRRRRRRRRRRRR`, T=timestamp, R=random). They are lexicographically sortable and UUID-compatible.

### Generating ULIDs

```php
use Symfony\Component\Uid\Ulid;

$ulid = new Ulid(); // e.g. 01AN4Z07BY79KA1307SR9X4MV3
```

### Creating from Existing Values

```php
$ulid = Ulid::fromString('01E439TP9XJZ9RPFH3T1PYBCR8');
$ulid = Ulid::fromBinary($binaryString);
$ulid = Ulid::fromBase32('01E439TP9XJZ9RPFH3T1PYBCR8');
$ulid = Ulid::fromBase58('1BKocMc5BnrVcuq2ti4Eqm');
$ulid = Ulid::fromRfc4122('0171069d-593d-97d3-8b3e-23d06de5b308');
```

### Converting ULIDs

```php
$ulid = Ulid::fromString('01E439TP9XJZ9RPFH3T1PYBCR8');

$ulid->toBinary();   // 16-byte binary
$ulid->toBase32();   // "01E439TP9XJZ9RPFH3T1PYBCR8"
$ulid->toBase58();   // "1BKocMc5BnrVcuq2ti4Eqm"
$ulid->toRfc4122();  // "0171069d-593d-97d3-8b3e-23d06de5b308"
$ulid->toHex();      // "0x0171069d593d97d38b3e23d06de5b308"
```

### Working with ULIDs

```php
Ulid::isValid($value);       // bool
$ulid->getDateTime();        // \DateTimeImmutable
$ulid1->equals($ulid2);     // bool
$ulid1->compare($ulid2);    // int
```

### ULID Factory

```php
use Symfony\Component\Uid\Factory\UlidFactory;

class FooService
{
    public function __construct(private UlidFactory $ulidFactory) {}

    public function generate(): void
    {
        $ulid = $this->ulidFactory->create();
    }
}
```

## Doctrine Integration

### UUID Column

```php
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Types\UuidType;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
class Product
{
    #[ORM\Column(type: UuidType::NAME)]
    private Uuid $someProperty;
}
```

### UUID Primary Key (Auto-generated)

```php
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Types\UuidType;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
class User
{
    #[ORM\Id]
    #[ORM\Column(type: UuidType::NAME, unique: true)]
    #[ORM\GeneratedValue(strategy: 'CUSTOM')]
    #[ORM\CustomIdGenerator('doctrine.uuid_generator')]
    private ?Uuid $id;

    public function getId(): ?Uuid { return $this->id; }
}
```

### ULID Column and Primary Key

```php
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\IdGenerator\UlidGenerator;
use Symfony\Bridge\Doctrine\Types\UlidType;
use Symfony\Component\Uid\Ulid;

#[ORM\Entity]
class Product
{
    #[ORM\Id]
    #[ORM\Column(type: UlidType::NAME, unique: true)]
    #[ORM\GeneratedValue(strategy: 'CUSTOM')]
    #[ORM\CustomIdGenerator(class: UlidGenerator::class)]
    private ?Ulid $id;

    public function getId(): ?Ulid { return $this->id; }
}
```

### Using UIDs in Doctrine Queries

```php
use Symfony\Bridge\Doctrine\Types\UuidType;

$qb = $this->createQueryBuilder('p')
    ->where('p.userId = :user')
    ->setParameter('user', $user->getUuid(), UuidType::NAME);
```

## Console Commands

```bash
# Generate UUIDs
php bin/console uuid:generate --random-based
php bin/console uuid:generate --time-based=now --node=fb3502dc-137e-4849-8886-ac90d07f64a7
php bin/console uuid:generate --count=2 --format=base58

# Generate ULIDs
php bin/console ulid:generate
php bin/console ulid:generate --time="2021-02-02 14:00:00"
php bin/console ulid:generate --count=2 --format=rfc4122

# Inspect UIDs
php bin/console uuid:inspect d0a3a023-f515-4fe0-915c-575e63693998
php bin/console ulid:inspect 01F2TTCSYK1PDRH73Z41BN1C4X
```

## Testing with MockUuidFactory

```php
use Symfony\Component\Uid\Factory\MockUuidFactory;
use Symfony\Component\Uid\UuidV4;

$factory = new MockUuidFactory([
    UuidV4::fromString('11111111-1111-4111-8111-111111111111'),
    UuidV4::fromString('22222222-2222-4222-8222-222222222222'),
]);

$service = new UserService($factory);
$service->createUserId(); // "11111111-1111-4111-8111-111111111111"
$service->createUserId(); // "22222222-2222-4222-8222-222222222222"
```

## UUID Version Recommendations

| Version | Type | Sortable | Recommended |
|---------|------|----------|-------------|
| v1 | Time + MAC | No | No (privacy concerns) |
| v3 | Name (MD5) | No | No (use v5) |
| v4 | Random | No | Yes (when sorting not needed) |
| v5 | Name (SHA-1) | No | Yes (deterministic IDs) |
| v6 | Reordered time | Yes | No (use v7) |
| v7 | UNIX timestamp | Yes | Yes (best for databases) |
| v8 | Custom | Varies | Special cases only |
