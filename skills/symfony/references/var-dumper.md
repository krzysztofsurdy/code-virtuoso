# Symfony VarDumper Component

Debug and inspect PHP variables with powerful alternatives to var_dump(). VarDumper provides formatted output, reference tracking, custom object representation, and integration with dump servers for non-intrusive debugging.

## Installation

Install via Composer as a development dependency:

```bash
composer require --dev symfony/var-dumper
```

## Core Functions

### dump()
Output variable state with automatic format selection:

```php
require __DIR__.'/vendor/autoload.php';

$someVar = ['key' => 'value'];
dump($someVar);              // Returns $someVar for chaining
dump($obj)->someMethod();    // Method chaining support

// CLI outputs to STDOUT; other SAPIs output HTML
```

**Features:**
- Per-object and resource-type specialized views
- Reference tracking (soft and hard references)
- Output buffering compatible
- Returns the dumped variable for chainable operations

### dd()
Dump and die - equivalent to dump() followed by exit:

```php
dd($variable); // Dumps and terminates execution
```

## Output Formats

Control format via environment variable or code:

```bash
VAR_DUMPER_FORMAT=html php script.php    # Force HTML output
VAR_DUMPER_FORMAT=cli php script.php     # Force colored CLI
VAR_DUMPER_FORMAT=server php script.php  # Send to dump server
```

## Core Classes

### VarCloner
Creates intermediate `Data` representations of PHP variables:

```php
use Symfony\Component\VarDumper\Cloner\VarCloner;

$cloner = new VarCloner();
$data = $cloner->cloneVar($myVariable);  // Returns Data object

// Configuration methods
$cloner->setMaxItems(1000);              // -1 for unlimited
$cloner->setMinDepth(1);                 // Depth before item limit
$cloner->setMaxString(1000);             // Character limit per string
$cloner->addCasters($myCasters);         // Register custom casters
```

**Data object methods:**
```php
$data->withMaxDepth(2);                  // Limit output depth
$data->withMaxItemsPerDepth(50);         // Items per level
$data->withRefHandles(false);            // Remove object handles
$data->seek('key1', 'key2');             // Select sub-parts
```

### HtmlDumper
Outputs formatted HTML for browser display:

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
Outputs optionally colored command-line format:

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
Send dumps to a remote dump server instead of displaying locally:

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

## Dumper Flags

Combine using bitwise OR to control output formatting:

```php
use Symfony\Component\VarDumper\Dumper\AbstractDumper;

$dumper = new CliDumper(null, null,
    AbstractDumper::DUMP_STRING_LENGTH      // Show "(4) "text""
    | AbstractDumper::DUMP_LIGHT_ARRAY       // Use [...] format
    | AbstractDumper::DUMP_COMMA_SEPARATOR   // Add commas after items
);
```

## Custom Casters

Customize object and resource representation during cloning:

### Caster Signature

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

### Register Casters

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

### Stub Types for Semantics

Wrap values to add meaning and formatting:

**ConstStub** - PHP constants:
```php
use Symfony\Component\VarDumper\Caster\ConstStub;

$array['error_level'] = new ConstStub('E_WARNING', E_WARNING);
```

**ClassStub** - Class/method identifiers:
```php
use Symfony\Component\VarDumper\Caster\ClassStub;

$array['class_name'] = new ClassStub('MyClass');
```

**LinkStub** - Clickable URLs and file paths:
```php
use Symfony\Component\VarDumper\Caster\LinkStub;

$array['documentation'] = new LinkStub('https://example.com/docs');
$array['file'] = new LinkStub('/path/to/file.txt');
```

**CutStub** - Ellipsis replacement for large objects:
```php
use Symfony\Component\VarDumper\Caster\CutStub;

if (strlen($largeString) > 1000) {
    $array['data'] = new CutStub($largeString);
}
```

**CutArrayStub** - Keep only specific array keys:
```php
use Symfony\Component\VarDumper\Caster\CutArrayStub;

$array['config'] = new CutArrayStub($largeConfig, ['key1', 'key2']);
```

**ImgStub** - Embed images:
```php
use Symfony\Component\VarDumper\Caster\ImgStub;

$array['thumbnail'] = new ImgStub('path/to/image.jpg');
```

**EnumStub** - Virtual computed values:
```php
use Symfony\Component\VarDumper\Caster\EnumStub;

$array['computed'] = new EnumStub(['virtual_prop' => 'result']);
```

**TraceStub/FrameStub/ArgsStub** - Stack traces:
```php
use Symfony\Component\VarDumper\Caster\TraceStub;

$array['trace'] = new TraceStub(debug_backtrace());
```

### Caster Example

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

## Capture Output as String

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

## PHPUnit Integration

Test dumped output with assertions:

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

**Available assertion methods:**
- `assertDumpEquals(string $expected, mixed $var)` - Exact match
- `assertDumpMatchesFormat(string $pattern, mixed $var)` - Pattern matching
- `setUpVarDumper()` / `tearDownVarDumper()` - Manual setup/teardown

## Symfony DebugBundle Integration

When used in Symfony with DebugBundle:

```php
// In controllers or services
dump($variable);  // Appears in web debug toolbar

// In Twig templates
{{ dump(variable) }}        {# Single variable #}
{% dump variable1, variable2 %}  {# Multiple variables #}
{{ dump() }}                {# All context variables #}
```

## Configuration

Set via environment variables:

```bash
VAR_DUMPER_FORMAT=html          # html, cli, or server
VAR_DUMPER_SERVER=127.0.0.1:9912  # Dump server address
```

Or configure in Symfony:

```yaml
# config/packages/debug.yaml
debug:
    dump_destination: "tcp://%env(VAR_DUMPER_SERVER)%"
    dump_format: "%env(VAR_DUMPER_FORMAT)%"
```

## Common Use Cases

**Debug in API responses:**
```php
dump($data);
// Appears in web toolbar, not in JSON output
```

**Custom object inspection:**
```php
$cloner = new VarCloner(['MyClass' => 'customCaster']);
$dumper = new CliDumper();
$output = $dumper->dump($cloner->cloneVar($obj), true);
```

**Remote debugging:**
```bash
php bin/console server:dump
# In another terminal:
VAR_DUMPER_FORMAT=server php your-script.php
```

**Test output verification:**
```php
$this->assertDumpMatchesFormat(
    "array:%d [\n  'status' => %s\n]",
    $response
);
```

## Key Implementation Details

- **Property prefixes**: Protected: `\0*\0`, Private: classname, Virtual: `\0~\0`, Dynamic: `\0+\0`
- **Resource types**: Prefix with `:` when registering casters (e.g., `:curl resource`)
- **Caster chaining**: Interfaces → parent classes → main class
- **Reference tracking**: Avoids repetition of circular references
- **Output buffering**: Compatible with ob_start() and related functions
- **No side effects**: Casters should not modify object state
