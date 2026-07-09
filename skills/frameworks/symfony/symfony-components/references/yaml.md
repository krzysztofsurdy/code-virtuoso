# Symfony Yaml component

Parse and dump YAML files, including data types, references, aliases, and merge keys.

## Contents

- [Installation](#installation)
- [Core classes](#core-classes)
- [Basic Usage](#basic-usage)
- [Data types](#data-types)
- [Advanced flags and options](#advanced-flags-and-options)
- [References, aliases, and merge keys](#references-aliases-and-merge-keys)
- [Symfony-specific features](#symfony-specific-features)
- [Error handling](#error-handling)
- [Syntax validation (CLI)](#syntax-validation-cli)
- [Common use cases](#common-use-cases)
- [Limitations](#limitations)

## Installation

Install the component:

```bash
composer require symfony/yaml
```

## Core classes

### Yaml (wrapper class)

The main entry point for parsing and dumping YAML:

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

The underlying parser class:

```php
use Symfony\Component\Yaml\Parser;

$parser = new Parser();
$array = $parser->parse($yaml);
```

### Dumper

The underlying dumper class:

```php
use Symfony\Component\Yaml\Dumper;

$dumper = new Dumper();
$yaml = $dumper->dump(['foo' => 'bar']);
```

## Basic Usage

### Parse YAML strings

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

### Parse YAML files

```php
$data = Yaml::parseFile('/path/to/config.yaml');
```

### Dump arrays to YAML

```php
$array = [
    'database' => [
        'host' => 'localhost',
        'port' => 5432,
        'credentials' => ['user' => 'admin', 'password' => 'secret']
    ]
];

$yaml = Yaml::dump($array);
// Produces formatted YAML
```

## Data types

### Strings

Three styles are supported:

```yaml
unquoted: A string in YAML
single_quoted: 'A single-quoted string'
double_quoted: "A double-quoted string\n"
```

Quote a string that contains special characters: `: { } [ ] , & * # ? | - < > = ! % @`

### Multi-line strings

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

### Null values

```yaml
nullable: null
shorthand: ~
```

### Dates (ISO-8601)

```yaml
timestamp: 2001-12-14T21:59:43.10-05:00
date: 2002-12-14
```

### Collections: sequences (arrays)

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

### Collections: mappings (associative arrays)

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

### Nested collections

```yaml
projects:
  symfony1:
    PHP: 5.0
    Propel: 1.2
  symfony2:
    PHP: 5.2
    Propel: 1.3
```

## Advanced flags and options

### Parsing flags

Pass flags as a parameter, or combine them as a bitmask:

```php
Yaml::parse($yaml, Yaml::PARSE_CONSTANT);
Yaml::parse($yaml, Yaml::PARSE_DATETIME);
Yaml::parse($yaml, Yaml::PARSE_CUSTOM_TAGS);
```

#### PARSE_CONSTANT

Resolves PHP constants (`!php/const` tag):

```php
Yaml::parse('value: !php/const App\Pagination\Paginator::PAGE_LIMIT',
    Yaml::PARSE_CONSTANT);
```

YAML:

```yaml
value: !php/const App\Pagination\Paginator::PAGE_LIMIT
```

#### PARSE_DATETIME

Converts ISO-8601 dates to DateTime objects:

```php
Yaml::parse('date: 2001-12-14T21:59:43.10-05:00',
    Yaml::PARSE_DATETIME);
// Returns DateTime object instead of string
```

#### PARSE_OBJECT

Parses PHP objects (`!php/object` tag):

```php
$yaml = <<<'YAML'
data:
  my_object: !php/object 'O:8:"stdClass":1:{s:3:"bar";i:2;}'
YAML;

Yaml::parse($yaml, Yaml::PARSE_OBJECT);
```

#### PARSE_OBJECT_FOR_MAP

Parses objects as associative arrays:

```php
Yaml::parse($yaml, Yaml::PARSE_OBJECT_FOR_MAP);
```

#### PARSE_EXCEPTION_ON_INVALID_TYPE

Throws an exception on an invalid type instead of silently converting it:

```php
Yaml::parse($yaml, Yaml::PARSE_EXCEPTION_ON_INVALID_TYPE);
```

#### PARSE_CUSTOM_TAGS

Enables custom tag parsing:

```php
Yaml::parse($yaml, Yaml::PARSE_CUSTOM_TAGS);
```

### Dumping flags

#### DUMP_OBJECT

Dumps PHP objects in serialized form:

```php
$obj = new stdClass();
$obj->foo = 'bar';

Yaml::dump(['obj' => $obj], inline: 2, indent: 4, flags: Yaml::DUMP_OBJECT);
// !php/object 'O:8:"stdClass":1:{s:3:"foo";s:3:"bar";}'
```

#### DUMP_OBJECT_AS_MAP

Dumps objects as YAML maps:

```php
Yaml::dump(['obj' => $obj], flags: Yaml::DUMP_OBJECT_AS_MAP);
// obj:
//   foo: bar
```

#### DUMP_EXCEPTION_ON_INVALID_TYPE

Throws an exception on an invalid type during a dump:

```php
Yaml::dump($array, flags: Yaml::DUMP_EXCEPTION_ON_INVALID_TYPE);
```

#### DUMP_MULTI_LINE_LITERAL_BLOCK

Uses literal blocks for multi-line strings:

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

Dumps null values as `~`:

```php
Yaml::dump(['key' => null], flags: Yaml::DUMP_NULL_AS_TILDE);
// key: ~
```

#### DUMP_NULL_AS_EMPTY

Dumps null values as empty:

```php
Yaml::dump(['key' => null], flags: Yaml::DUMP_NULL_AS_EMPTY);
// key:
```

#### DUMP_NUMERIC_KEY_AS_STRING

Dumps numeric keys as strings:

```php
Yaml::dump([0 => 'item1', 1 => 'item2'], flags: Yaml::DUMP_NUMERIC_KEY_AS_STRING);
```

#### DUMP_FORCE_DOUBLE_QUOTES_ON_VALUES

Forces double quotes on all values:

```php
Yaml::dump(['key' => 'value'], flags: Yaml::DUMP_FORCE_DOUBLE_QUOTES_ON_VALUES);
```

#### DUMP_COMPACT_NESTED_MAPPING

Produces compact output for nested collections:

```php
Yaml::dump(['items' => [['id' => 1], ['id' => 2]]],
    flags: Yaml::DUMP_COMPACT_NESTED_MAPPING);
```

### Formatting options

#### Indentation level

Sets the nesting level at which output switches from inline to expanded (default: 2):

```php
Yaml::dump($array, 1);  // Switch at level 1
Yaml::dump($array, 2);  // Switch at level 2
Yaml::dump($array, 4);  // Switch at level 4
```

#### Custom indentation spaces

Set indentation width (default: 4):

```php
Yaml::dump($array, inline: 2, indent: 8);  // Use 8 spaces for indentation
```

## References, aliases, and merge keys

### Anchors and aliases

Define a value once and reference it in several places:

```yaml
defaults: &defaults
  adapter: postgres
  host: localhost

development:
  <<: *defaults
  database: dev_db
```

### Merge keys

Merge one mapping into another:

```yaml
common: &common
  adapter: postgres
  host: localhost

development:
  <<: *common
  database: dev_db
```

## Symfony-specific features

### PHP constants

```php
// Enable with PARSE_CONSTANT flag
$yaml = <<<'YAML'
pagination:
  page_limit: !php/const App\Pagination\Paginator::PAGE_LIMIT
YAML;

$config = Yaml::parse($yaml, Yaml::PARSE_CONSTANT);
```

### PHP enums

```yaml
# Single enum case
operator: !php/enum App\Operator\Enum\Type::Or

# Enum case value
operator_value: !php/enum App\Operator\Enum\Type::Or->value

# All enum cases
operators: !php/enum App\Operator\Enum\Type
```

Parse it with:

```php
Yaml::parse($yaml, Yaml::PARSE_CONSTANT);
```

### Binary data

Base64-encoded data that is not valid UTF-8:

```yaml
image: !!binary |
  R0lGODlhDAAMAIQAAP//9/X17unp5WZmZgAAAOfn515eXv
  Pz8/f39//z8//v7+/r6+v3+/v///
```

## Error handling

### ParseException

Parsing errors carry the filename and line number:

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

## Syntax validation (CLI)

Validate YAML files from the command line:

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

## Common use cases

### Configuration files

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

Parse it with:

```php
$config = Yaml::parseFile('.env.yaml');
```

### Service definitions

```yaml
services:
  app.logger:
    class: App\Logger\Logger
    arguments:
      - '@app.handler'

  app.handler:
    class: App\Logger\Handler
```

### Mixed complex structures

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

Stay within standard YAML syntax. If you need these features, use a parser that implements the full YAML specification.
