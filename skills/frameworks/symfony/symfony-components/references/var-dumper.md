# Symfony VarDumper component

Debug and inspect PHP variables with replacements for `var_dump()`. VarDumper gives formatted output, reference tracking, custom object representation, and dump servers that keep debug output out of the page.

## Contents

- [Installation](#installation)
- [Core functions](#core-functions)
- [Output formats](#output-formats)
- [Core classes](#core-classes)
- [Dumper flags](#dumper-flags)
- [Custom casters](#custom-casters)
- [Capture output as a string](#capture-output-as-a-string)
- [PHPUnit integration](#phpunit-integration)
- [Symfony DebugBundle integration](#symfony-debugbundle-integration)
- [Configuration](#configuration)
- [Common use cases](#common-use-cases)
- [Implementation details](#implementation-details)

## Installation

Install it as a development dependency:

```bash
composer require --dev symfony/var-dumper
```

## Core functions

### dump()
Outputs a variable and picks the format automatically:

```php
require __DIR__.'/vendor/autoload.php';

$someVar = ['key' => 'value'];
dump($someVar);              // Returns $someVar for chaining
dump($obj)->someMethod();    // Method chaining support

// CLI outputs to STDOUT; other SAPIs output HTML
```

Behavior:

- Specialized views per object and resource type
- Reference tracking (soft and hard references)
- Works with output buffering
- Returns the dumped variable, so calls can be chained

### dd()
Dump and die, equivalent to `dump()` followed by `exit`:

```php
dd($variable); // Dumps and terminates execution
```

## Output formats

Set the format with an environment variable:

```bash
VAR_DUMPER_FORMAT=html php script.php    # Force HTML output
VAR_DUMPER_FORMAT=cli php script.php     # Force colored CLI
VAR_DUMPER_FORMAT=server php script.php  # Send to dump server
```

## Core classes

### VarCloner
Turns a PHP variable into an intermediate `Data` representation:

```php
use Symfony\Component\VarDumper\Cloner\VarCloner;

$cloner = new VarCloner();
$data = $cloner->cloneVar($myVariable);  // Returns Data object

// Configuration
$cloner->setMaxItems(1000);              // -1 for unlimited
$cloner->setMinDepth(1);                 // Depth before item limit
$cloner->setMaxString(1000);             // Character limit per string
$cloner->addCasters($myCasters);         // Register custom casters
```

`Data` object methods:

```php
$data->withMaxDepth(2);                  // Limit output depth
$data->withMaxItemsPerDepth(50);         // Items per level
$data->withRefHandles(false);            // Remove object handles
$data->seek('key1', 'key2');             // Select sub-parts
```

### HtmlDumper
Renders HTML for browser display:

```php
use Symfony\Component\VarDumper\Dumper\HtmlDumper;

$dumper = new HtmlDumper();
$dumper->setTheme('light');              // 'light' or 'dark' (default)

// Dump to output or return as string
$dumper->dump($data);                    // To output stream
$output = $dumper->dump($data, true);    // Return as string

// Custom output destination
$dumper->setOutput($resource_or_callable);
```

### CliDumper
Renders command-line output, optionally colored:

```php
use Symfony\Component\VarDumper\Dumper\CliDumper;
use Symfony\Component\VarDumper\Dumper\AbstractDumper;

$dumper = new CliDumper(
    'php://stdout',
    null,
    AbstractDumper::DUMP_STRING_LENGTH | AbstractDumper::DUMP_LIGHT_ARRAY
);

$output = $dumper->dump($cloner->cloneVar($var), true);
```

### ServerDumper
Sends dumps to a remote dump server instead of displaying them locally:

```php
use Symfony\Component\VarDumper\Dumper\ServerDumper;
use Symfony\Component\VarDumper\Dumper\CliDumper;
use Symfony\Component\VarDumper\Dumper\ContextProvider\CliContextProvider;
use Symfony\Component\VarDumper\Dumper\ContextProvider\SourceContextProvider;

$fallback = new CliDumper();
$dumper = new ServerDumper('tcp://127.0.0.1:9912', $fallback, [
    'cli' => new CliContextProvider(),
    'source' => new SourceContextProvider(),
]);

// Configure global handler
VarDumper::setHandler(function (mixed $var) use ($cloner, $dumper): ?string {
    return $dumper->dump($cloner->cloneVar($var));
});
```

Start the dump server:

```bash
./vendor/bin/var-dump-server        # Standalone
php bin/console server:dump         # Symfony console (formats CLI)
php bin/console server:dump --format=html > dump.html  # HTML format
```

## Dumper flags

Combine flags with bitwise OR to control output formatting:

```php
use Symfony\Component\VarDumper\Dumper\AbstractDumper;

$dumper = new CliDumper(null, null,
    AbstractDumper::DUMP_STRING_LENGTH      // Show "(4) "text""
    | AbstractDumper::DUMP_LIGHT_ARRAY       // Use [...] format
    | AbstractDumper::DUMP_COMMA_SEPARATOR   // Add commas after items
);
```

## Custom casters

Casters change how objects and resources are represented during cloning.

### Caster signature

```php
use Symfony\Component\VarDumper\Cloner\Stub;

function myCaster(
    mixed $object,           // The object/resource being cast
    array $array,            // Pre-populated array to modify
    Stub $stub,              // Main object metadata
    bool $isNested,          // Nested in another structure
    int $filter = 0          // Bit field for Caster::EXCLUDE_* flags
): array {
    // Customize $array representation
    return $array;
}
```

### Register casters

```php
$casters = [
    'MyClass' => $myClassCaster,
    ':resource_type' => $myResourceCaster,  // Prefix : for resources
    'ParentClass' => $parentCaster,         // Inheritable
];

$cloner = new VarCloner($casters);
// or dynamically
$cloner->addCasters($casters);
```

### Stub types

Wrap values in a stub to add meaning and formatting.

`ConstStub` for PHP constants:

```php
use Symfony\Component\VarDumper\Caster\ConstStub;

$array['error_level'] = new ConstStub('E_WARNING', E_WARNING);
```

`ClassStub` for class and method identifiers:

```php
use Symfony\Component\VarDumper\Caster\ClassStub;

$array['class_name'] = new ClassStub('MyClass');
```

`LinkStub` for clickable URLs and file paths:

```php
use Symfony\Component\VarDumper\Caster\LinkStub;

$array['documentation'] = new LinkStub('https://example.com/docs');
$array['file'] = new LinkStub('/path/to/file.txt');
```

`CutStub` replaces large values with an ellipsis:

```php
use Symfony\Component\VarDumper\Caster\CutStub;

if (strlen($largeString) > 1000) {
    $array['data'] = new CutStub($largeString);
}
```

`CutArrayStub` keeps only the listed array keys:

```php
use Symfony\Component\VarDumper\Caster\CutArrayStub;

$array['config'] = new CutArrayStub($largeConfig, ['key1', 'key2']);
```

`ImgStub` embeds images:

```php
use Symfony\Component\VarDumper\Caster\ImgStub;

$array['thumbnail'] = new ImgStub('path/to/image.jpg');
```

`EnumStub` shows virtual computed values:

```php
use Symfony\Component\VarDumper\Caster\EnumStub;

$array['computed'] = new EnumStub(['virtual_prop' => 'result']);
```

`TraceStub`, `FrameStub`, and `ArgsStub` for stack traces:

```php
use Symfony\Component\VarDumper\Caster\TraceStub;

$array['trace'] = new TraceStub(debug_backtrace());
```

### Caster example

```php
use Symfony\Component\VarDumper\Caster\LinkStub;
use Symfony\Component\VarDumper\Caster\CutStub;
use Symfony\Component\VarDumper\Cloner\Stub;

class Product {
    public string $name;
    public string $brochure;
    public array $metadata;
}

function ProductCaster(
    Product $obj,
    array $array,
    Stub $stub,
    bool $isNested,
    int $filter = 0
): array {
    // Make brochure URL clickable
    $array['brochure'] = new LinkStub($array['brochure']);

    // Hide large metadata with ellipsis
    $array['metadata'] = new CutStub($array['metadata']);

    return $array;
}

$cloner = new VarCloner(['Product' => 'ProductCaster']);
dump($product);  // Uses custom caster
```

## Capture output as a string

```php
use Symfony\Component\VarDumper\Cloner\VarCloner;
use Symfony\Component\VarDumper\Dumper\CliDumper;

$cloner = new VarCloner();
$dumper = new CliDumper();

// Method 1: Second parameter as true
$output = $dumper->dump($cloner->cloneVar($var), true);

// Method 2: Callable output handler
$output = '';
$dumper->dump($cloner->cloneVar($var), function (string $line, int $depth) use (&$output) {
    if ($depth >= 0) {
        $output .= str_repeat('  ', $depth) . $line . "\n";
    }
});

// Method 3: PHP stream
$stream = fopen('php://memory', 'r+b');
$dumper->dump($cloner->cloneVar($var), $stream);
$output = stream_get_contents($stream, -1, 0);
fclose($stream);
```

## PHPUnit integration

Assert on dumped output:

```php
use Symfony\Component\VarDumper\Test\VarDumperTestTrait;
use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase
{
    use VarDumperTestTrait;

    public function testDumpEquality(): void
    {
        $expected = <<<EOF
            array:2 [
              'key' => 'value'
              'nested' => [...]
            ]
            EOF;

        $this->assertDumpEquals($expected, $testedVar);
    }

    public function testDumpFormat(): void
    {
        $pattern = <<<EOF
            array:%d [
              %s => %s
            ]
            EOF;

        $this->assertDumpMatchesFormat($pattern, $testedVar);
    }
}
```

Assertion methods:

- `assertDumpEquals(string $expected, mixed $var)` - Exact match
- `assertDumpMatchesFormat(string $pattern, mixed $var)` - Pattern matching
- `setUpVarDumper()` / `tearDownVarDumper()` - Manual setup/teardown

## Symfony DebugBundle integration

With DebugBundle installed:

```php
// In controllers or services
dump($variable);  // Appears in web debug toolbar

// In Twig templates
{{ dump(variable) }}        {# Single variable #}
{% dump variable1, variable2 %}  {# Multiple variables #}
{{ dump() }}                {# All context variables #}
```

## Configuration

Set these environment variables:

```bash
VAR_DUMPER_FORMAT=html          # html, cli, or server
VAR_DUMPER_SERVER=127.0.0.1:9912  # Dump server address
```

Or configure it in Symfony:

```yaml
# config/packages/debug.yaml
debug:
    dump_destination: "tcp://%env(VAR_DUMPER_SERVER)%"
    dump_format: "%env(VAR_DUMPER_FORMAT)%"
```

## Common use cases

Debug in API responses:

```php
dump($data);
// Appears in web toolbar, not in JSON output
```

Custom object inspection:

```php
$cloner = new VarCloner(['MyClass' => 'customCaster']);
$dumper = new CliDumper();
$output = $dumper->dump($cloner->cloneVar($obj), true);
```

Remote debugging:

```bash
php bin/console server:dump
# In another terminal:
VAR_DUMPER_FORMAT=server php your-script.php
```

Test output verification:

```php
$this->assertDumpMatchesFormat(
    "array:%d [\n  'status' => %s\n]",
    $response
);
```

## Implementation details

- **Property prefixes**: Protected: `\0*\0`, Private: classname, Virtual: `\0~\0`, Dynamic: `\0+\0`
- **Resource types**: Prefix with `:` when registering casters (e.g., `:curl resource`)
- **Caster chaining**: Interfaces → parent classes → main class
- **Reference tracking**: Avoids repetition of circular references
- **Output buffering**: Compatible with ob_start() and related functions
- **No side effects**: Casters should not modify object state
