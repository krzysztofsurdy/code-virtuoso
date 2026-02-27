# Symfony Yaml Component

Parse and dump YAML configuration files efficiently with full support for data types, references, aliases, and merge keys.

## Installation

Install the Yaml component:

```bash
composer require symfony/yaml
```

## Core Classes

### Yaml (Wrapper Class)

Primary interface for parsing and dumping YAML:

```php
use Symfony\Component\Yaml\Yaml;

// Parse YAML string
$array = Yaml::parse("foo: bar");

// Parse YAML file
$array = Yaml::parseFile('/path/to/file.yaml');

// Dump array to YAML string
$yaml = Yaml::dump(['foo' => 'bar']);

// Write YAML to file
file_put_contents('/path/to/file.yaml', $yaml);
```

### Parser

Direct class for parsing YAML:

```php
use Symfony\Component\Yaml\Parser;

$parser = new Parser();
$array = $parser->parse($yaml);
```

### Dumper

Direct class for dumping YAML:

```php
use Symfony\Component\Yaml\Dumper;

$dumper = new Dumper();
$yaml = $dumper->dump(['foo' => 'bar']);
```

## Basic Usage

### Parse YAML Strings

```php
use Symfony\Component\Yaml\Yaml;

$yaml = <<<'YAML'
foo: bar
items:
  - item1
  - item2
YAML;

$data = Yaml::parse($yaml);
// ['foo' => 'bar', 'items' => ['item1', 'item2']]
```

### Parse YAML Files

```php
$data = Yaml::parseFile('/path/to/config.yaml');
```

### Dump Arrays to YAML

```php
$array = [
    'database' => [
        'host' => 'localhost',
        'port' => 5432,
        'credentials' => ['user' => 'admin', 'password' => 'secret']
    ]
];

$yaml = Yaml::dump($array);
// Outputs formatted YAML
```

## Data Types

### Strings

Three styles supported:

```yaml
unquoted: A string in YAML
single_quoted: 'A single-quoted string'
double_quoted: "A double-quoted string\n"
```

Strings require quotes when containing special characters: `: { } [ ] , & * # ? | - < > = ! % @`

### Multi-line Strings

Literal style (preserves newlines):

```yaml
code: |
  line 1
  line 2
```

Folded style (replaces newlines with spaces):

```yaml
description: >
  This is a very long sentence
  that spans several lines in the YAML.
```

### Numbers

```yaml
integer: 12
octal: 0o14
hexadecimal: 0xC
float: 13.4
exponential: 1.2e+34
infinity: .inf
```

### Booleans

```yaml
enabled: true
disabled: false
```

### Null Values

```yaml
nullable: null
shorthand: ~
```

### Dates (ISO-8601)

```yaml
timestamp: 2001-12-14T21:59:43.10-05:00
date: 2002-12-14
```

### Collections - Sequences (Arrays)

Block style:

```yaml
items:
  - PHP
  - Perl
  - Python
```

Flow style:

```yaml
items: [PHP, Perl, Python]
```

### Collections - Mappings (Associative Arrays)

Block style:

```yaml
versions:
  PHP: 5.2
  MySQL: 5.1
  Apache: 2.2.20
```

Flow style:

```yaml
versions: { PHP: 5.2, MySQL: 5.1, Apache: 2.2.20 }
```

### Nested Collections

```yaml
projects:
  symfony1:
    PHP: 5.0
    Propel: 1.2
  symfony2:
    PHP: 5.2
    Propel: 1.3
```

## Advanced Flags and Options

### Parsing Flags

Use flags as bitmask or pass as parameter:

```php
Yaml::parse($yaml, Yaml::PARSE_CONSTANT);
Yaml::parse($yaml, Yaml::PARSE_DATETIME);
Yaml::parse($yaml, Yaml::PARSE_CUSTOM_TAGS);
```

#### PARSE_CONSTANT

Parse PHP constants (`!php/const` tag):

```php
Yaml::parse('value: !php/const App\Pagination\Paginator::PAGE_LIMIT',
    Yaml::PARSE_CONSTANT);
```

YAML:
```yaml
value: !php/const App\Pagination\Paginator::PAGE_LIMIT
```

#### PARSE_DATETIME

Convert ISO-8601 dates to DateTime objects:

```php
Yaml::parse('date: 2001-12-14T21:59:43.10-05:00',
    Yaml::PARSE_DATETIME);
// Returns DateTime object instead of string
```

#### PARSE_OBJECT

Parse PHP objects (`!php/object` tag):

```php
$yaml = <<<'YAML'
data:
  my_object: !php/object 'O:8:"stdClass":1:{s:3:"bar";i:2;}'
YAML;

Yaml::parse($yaml, Yaml::PARSE_OBJECT);
```

#### PARSE_OBJECT_FOR_MAP

Parse objects as associative arrays:

```php
Yaml::parse($yaml, Yaml::PARSE_OBJECT_FOR_MAP);
```

#### PARSE_EXCEPTION_ON_INVALID_TYPE

Throw exception on invalid type instead of silently converting:

```php
Yaml::parse($yaml, Yaml::PARSE_EXCEPTION_ON_INVALID_TYPE);
```

#### PARSE_CUSTOM_TAGS

Enable custom tag parsing:

```php
Yaml::parse($yaml, Yaml::PARSE_CUSTOM_TAGS);
```

### Dumping Flags

#### DUMP_OBJECT

Dump PHP objects as serialized:

```php
$obj = new stdClass();
$obj->foo = 'bar';

Yaml::dump(['obj' => $obj], inline: 2, indent: 4, flags: Yaml::DUMP_OBJECT);
// !php/object 'O:8:"stdClass":1:{s:3:"foo";s:3:"bar";}'
```

#### DUMP_OBJECT_AS_MAP

Dump objects as YAML maps:

```php
Yaml::dump(['obj' => $obj], flags: Yaml::DUMP_OBJECT_AS_MAP);
// obj:
//   foo: bar
```

#### DUMP_EXCEPTION_ON_INVALID_TYPE

Throw exception on invalid type during dump:

```php
Yaml::dump($array, flags: Yaml::DUMP_EXCEPTION_ON_INVALID_TYPE);
```

#### DUMP_MULTI_LINE_LITERAL_BLOCK

Use literal blocks for multi-line strings:

```php
$yaml = Yaml::dump(
    ['text' => "line1\nline2\nline3"],
    flags: Yaml::DUMP_MULTI_LINE_LITERAL_BLOCK
);
// text: |
//   line1
//   line2
//   line3
```

#### DUMP_NULL_AS_TILDE

Dump null values as `~`:

```php
Yaml::dump(['key' => null], flags: Yaml::DUMP_NULL_AS_TILDE);
// key: ~
```

#### DUMP_NULL_AS_EMPTY

Dump null values as empty:

```php
Yaml::dump(['key' => null], flags: Yaml::DUMP_NULL_AS_EMPTY);
// key:
```

#### DUMP_NUMERIC_KEY_AS_STRING

Dump numeric keys as strings:

```php
Yaml::dump([0 => 'item1', 1 => 'item2'], flags: Yaml::DUMP_NUMERIC_KEY_AS_STRING);
```

#### DUMP_FORCE_DOUBLE_QUOTES_ON_VALUES

Force all values to use double quotes:

```php
Yaml::dump(['key' => 'value'], flags: Yaml::DUMP_FORCE_DOUBLE_QUOTES_ON_VALUES);
```

#### DUMP_COMPACT_NESTED_MAPPING

Compact output for nested collections:

```php
Yaml::dump(['items' => [['id' => 1], ['id' => 2]]],
    flags: Yaml::DUMP_COMPACT_NESTED_MAPPING);
```

### Formatting Options

#### Indentation Level

Control when output switches from inline to expanded (default: 2):

```php
Yaml::dump($array, 1);  // Switch at level 1
Yaml::dump($array, 2);  // Switch at level 2
Yaml::dump($array, 4);  // Switch at level 4
```

#### Custom Indentation Spaces

Set indentation width (default: 4):

```php
Yaml::dump($array, inline: 2, indent: 8);  // Use 8 spaces for indentation
```

## References, Aliases, and Merge Keys

### Anchors and Aliases

Define a value once and reference it multiple times:

```yaml
defaults: &defaults
  adapter: postgres
  host: localhost

development:
  <<: *defaults
  database: dev_db
```

### Merge Keys

Merge one mapping into another:

```yaml
common: &common
  adapter: postgres
  host: localhost

development:
  <<: *common
  database: dev_db
```

## Symfony-Specific Features

### PHP Constants

```php
// Enable with PARSE_CONSTANT flag
$yaml = <<<'YAML'
pagination:
  page_limit: !php/const App\Pagination\Paginator::PAGE_LIMIT
YAML;

$config = Yaml::parse($yaml, Yaml::PARSE_CONSTANT);
```

### PHP Enums

```yaml
# Single enum case
operator: !php/enum App\Operator\Enum\Type::Or

# Enum case value
operator_value: !php/enum App\Operator\Enum\Type::Or->value

# All enum cases
operators: !php/enum App\Operator\Enum\Type
```

Parse with:

```php
Yaml::parse($yaml, Yaml::PARSE_CONSTANT);
```

### Binary Data

Base64-encoded non-UTF-8 data:

```yaml
image: !!binary |
  R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXv
  Pz8/f39//z8//v7+/r6+v3+/v///
```

## Error Handling

### ParseException

Handle parsing errors with filename and line numbers:

```php
use Symfony\Component\Yaml\Exception\ParseException;

try {
    $config = Yaml::parseFile('config.yaml');
} catch (ParseException $e) {
    printf('Error parsing YAML: %s at line %d in %s',
        $e->getMessage(),
        $e->getParsedLine(),
        $e->getFile()
    );
}
```

## Syntax Validation (CLI)

Validate YAML files from command line:

```bash
# Validate single file
php -r "require 'vendor/autoload.php'; \
    use Symfony\Component\Yaml\Yaml; \
    Yaml::parseFile('config.yaml');"

# Validate with lint script
php lint.php path/to/file.yaml
php lint.php path/to/directory
cat file.yaml | php lint.php
php lint.php file.yaml --format=json
```

## Common Use Cases

### Configuration Files

```yaml
database:
  driver: pdo_mysql
  host: localhost
  port: 3306
  user: root
  password: secret
  dbname: myapp

cache:
  default: redis
  redis:
    host: localhost
    port: 6379
```

Parse with:

```php
$config = Yaml::parseFile('.env.yaml');
```

### Service Definitions

```yaml
services:
  app.logger:
    class: App\Logger\Logger
    arguments:
      - '@app.handler'

  app.handler:
    class: App\Logger\Handler
```

### Mixed Complex Structures

```yaml
app_config: &app_config
  debug: true
  charset: UTF-8

environments:
  development:
    <<: *app_config
    database: dev_db
  production:
    <<: *app_config
    database: prod_db
    debug: false
```

## Limitations

The Symfony Yaml component does not support:

- Multi-document YAML files (`---` markers)
- Complex mapping keys starting with `?`
- Advanced YAML tags (`!!set`, `!!omap`, `!!pairs`, etc.)
- TAG directives and tag references
- Sequence-like syntax for mappings (use `{foo: ~, bar: ~}`)

Use standard YAML syntax within these constraints. For advanced use cases, consider the full YAML specification parsers.
