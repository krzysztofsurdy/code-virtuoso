# Symfony Asset Component

The Asset component manages web asset URLs and versioning. It removes hardcoded asset paths, enables cache busting, and supports CDN distribution.

## Contents

- [Installation](#installation)
- [Core concepts](#core-concepts)
- [Version strategies](#version-strategies)
- [Package classes](#package-classes)
- [Common patterns](#common-patterns)
- [Best practices](#best-practices)
- [PackageInterface](#packageinterface)
- [Integration with Symfony Framework](#integration-with-symfony-framework)

## Installation

```bash
composer require symfony/asset
```

## Core concepts

### Asset Packages
Packages group assets that share the same properties (versioning strategy, base path, CDN hosts). Pick the package type that fits:

- **Package**: Basic package without base path manipulation
- **PathPackage**: Adds a common base path prefix (e.g., `/static/images`)
- **UrlPackage**: Generates absolute URLs for CDN or external hosting
- **Packages**: Manages several named packages with different configurations

### Versioning Strategies
Versioning adds an identifier to asset URLs so browsers download a fresh copy when content changes:

- **EmptyVersionStrategy**: No versioning (basic assets)
- **StaticVersionStrategy**: Appends fixed version (e.g., `?v1`)
- **JsonManifestVersionStrategy**: Uses manifest file from build tools (Webpack, etc.)
- **Custom strategies**: Implement `VersionStrategyInterface` for custom logic

## Version strategies

### EmptyVersionStrategy
No versioning applied:
```php
use Symfony\Component\Asset\Package;
use Symfony\Component\Asset\VersionStrategy\EmptyVersionStrategy;

$package = new Package(new EmptyVersionStrategy());
echo $package->getUrl('/image.png');  // /image.png
```

### StaticVersionStrategy
Appends a fixed version to asset URLs. Suits simple, application-wide versioning:

```php
use Symfony\Component\Asset\Package;
use Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy;

// Default format: asset?version
$package = new Package(new StaticVersionStrategy('v1'));
echo $package->getUrl('/image.png');  // /image.png?v1

// Custom format (sprintf-compatible)
$package = new Package(new StaticVersionStrategy('v1', '%s?version=%s'));
echo $package->getUrl('/image.png');  // /image.png?version=v1

// Version in path instead of query string
$package = new Package(new StaticVersionStrategy('v1', '%2$s/%1$s'));
echo $package->getUrl('/image.png');  // /v1/image.png
```

**Constructor**: `StaticVersionStrategy($version, $format = '%s?%s')`

### JsonManifestVersionStrategy
Reads asset mappings from a JSON manifest file. Use it with Webpack, Gulp, or other build tools:

```php
use Symfony\Component\Asset\Package;
use Symfony\Component\Asset\VersionStrategy\JsonManifestVersionStrategy;

// Local manifest file
$package = new Package(new JsonManifestVersionStrategy('/path/to/rev-manifest.json'));
echo $package->getUrl('css/app.css');
// result: build/css/app.b916426ea1d10021f3f17ce8031f93c2.css

// Remote manifest via HTTP
use Symfony\Component\HttpClient\HttpClient;
$httpClient = HttpClient::create();
$package = new Package(new JsonManifestVersionStrategy(
    'https://cdn.example.com/rev-manifest.json',
    $httpClient
));

// Strict mode (throws exception if asset not in manifest)
$package = new Package(new JsonManifestVersionStrategy(
    '/path/to/rev-manifest.json',
    null,
    true  // strict mode
));
```

**Manifest JSON format**:
```json
{
    "css/app.css": "build/css/app.b916426ea1d10021f3f17ce8031f93c2.css",
    "js/app.js": "build/js/app.13630905267b809161e71d0f8a0c017b.js"
}
```

**Constructor**: `JsonManifestVersionStrategy($manifestPath, $httpClient = null, $strict = false)`

### Custom Version Strategies
Implement `VersionStrategyInterface` for versioning logic specific to your application:

```php
use Symfony\Component\Asset\VersionStrategy\VersionStrategyInterface;

class DateVersionStrategy implements VersionStrategyInterface
{
    private string $version;

    public function __construct()
    {
        $this->version = date('Ymd');  // YYYYMMDD format
    }

    public function getVersion(string $path): string
    {
        return $this->version;
    }

    public function applyVersion(string $path): string
    {
        return sprintf('%s?v=%s', $path, $this->getVersion($path));
    }
}

// Gulp Buster compatible strategy
class GulpBusterVersionStrategy implements VersionStrategyInterface
{
    private array $hashes = [];

    public function __construct(private string $manifestPath, private ?string $format = null)
    {
        $this->format = $format ?: '%s?%s';
    }

    public function getVersion(string $path): string
    {
        if (!$this->hashes) {
            $this->hashes = json_decode(file_get_contents($this->manifestPath), true);
        }
        return $this->hashes[$path] ?? '';
    }

    public function applyVersion(string $path): string
    {
        $version = $this->getVersion($path);
        return $version ? sprintf($this->format, $path, $version) : $path;
    }
}
```

**Required methods**:
- `getVersion(string $path): string` - Return version identifier
- `applyVersion(string $path): string` - Return versioned asset URL

## Package classes

### Package
Basic package without base path manipulation:

```php
use Symfony\Component\Asset\Package;
use Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy;

$package = new Package(new StaticVersionStrategy('v1'));
echo $package->getUrl('/image.png');  // /image.png?v1
echo $package->getUrl('image.png');   // image.png?v1
```

### PathPackage
Groups assets under a common base path, for example by type:

```php
use Symfony\Component\Asset\PathPackage;
use Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy;

$pathPackage = new PathPackage('/static/images', new StaticVersionStrategy('v1'));
echo $pathPackage->getUrl('logo.png');   // /static/images/logo.png?v1
echo $pathPackage->getUrl('/logo.png');  // /logo.png?v1 (absolute paths bypass base path)
```

**With request context** (for subdirectory applications):
```php
use Symfony\Component\Asset\Context\RequestStackContext;

$pathPackage = new PathPackage(
    '/static/images',
    new StaticVersionStrategy('v1'),
    new RequestStackContext($requestStack)
);
echo $pathPackage->getUrl('logo.png');
// result: /somewhere/static/images/logo.png?v1 (includes request base path)
```

**Constructor**: `PathPackage($basePath, $versionStrategy, $context = null)`

### UrlPackage
Generates absolute URLs for CDN or external static file hosting:

```php
use Symfony\Component\Asset\UrlPackage;
use Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy;

// Single CDN
$urlPackage = new UrlPackage(
    'https://static.example.com/images/',
    new StaticVersionStrategy('v1')
);
echo $urlPackage->getUrl('/logo.png');
// result: https://static.example.com/images/logo.png?v1

// Schema-agnostic URL (auto-selects HTTP or HTTPS)
$urlPackage = new UrlPackage(
    '//static.example.com/images/',
    new StaticVersionStrategy('v1')
);
echo $urlPackage->getUrl('/logo.png');
// result: //static.example.com/images/logo.png?v1

// Multiple CDNs (load balancing)
$urls = [
    'https://static1.example.com/images/',
    'https://static2.example.com/images/',
];
$urlPackage = new UrlPackage($urls, new StaticVersionStrategy('v1'));
echo $urlPackage->getUrl('/logo.png');   // https://static1.example.com/images/logo.png?v1
echo $urlPackage->getUrl('/icon.png');   // https://static2.example.com/images/icon.png?v1
// Note: Selection is deterministic (same asset always uses same CDN)
```

**With request context** (auto-select URL scheme):
```php
use Symfony\Component\Asset\Context\RequestStackContext;

$urlPackage = new UrlPackage(
    ['http://example.com/', 'https://example.com/'],
    new StaticVersionStrategy('v1'),
    new RequestStackContext($requestStack)
);
// Automatically uses HTTPS for secure requests, HTTP for insecure
```

**Alternative protocols**:
```php
// File protocol
$localPackage = new UrlPackage(
    'file:///path/to/images/',
    new EmptyVersionStrategy()
);
echo $localPackage->getUrl('/logo.png');  // file:///path/to/images/logo.png

// FTP protocol
$ftpPackage = new UrlPackage(
    'ftp://example.com/images/',
    new EmptyVersionStrategy()
);
echo $ftpPackage->getUrl('/logo.png');    // ftp://example.com/images/logo.png
```

**Constructor**: `UrlPackage($baseUrls, $versionStrategy, $context = null)`

### Packages (Manager)
Manages several named packages for different asset types:

```php
use Symfony\Component\Asset\Packages;
use Symfony\Component\Asset\Package;
use Symfony\Component\Asset\PathPackage;
use Symfony\Component\Asset\UrlPackage;
use Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy;

$versionStrategy = new StaticVersionStrategy('v1');

// Default package for generic assets
$defaultPackage = new Package($versionStrategy);

// Named packages for specific asset types
$namedPackages = [
    'img' => new UrlPackage('https://img.example.com/', $versionStrategy),
    'doc' => new PathPackage('/documents', $versionStrategy),
    'cdn' => new UrlPackage(['https://cdn1.example.com/', 'https://cdn2.example.com/'], $versionStrategy),
];

$packages = new Packages($defaultPackage, $namedPackages);

// Usage
echo $packages->getUrl('/main.css');        // /main.css?v1 (default)
echo $packages->getUrl('/logo.png', 'img'); // https://img.example.com/logo.png?v1
echo $packages->getUrl('resume.pdf', 'doc'); // /documents/resume.pdf?v1
echo $packages->getUrl('/app.js', 'cdn');   // https://cdn1.example.com/app.js?v1
```

**Methods**:
- `getUrl(string $path, ?string $packageName = null): string`
- `getVersion(string $path, ?string $packageName = null): string`

## Common patterns

### Cache busting with static version
Update version when deploying to force browser cache refresh:

```php
$versionStrategy = new StaticVersionStrategy($_ENV['ASSET_VERSION'] ?? 'v1');
$package = new Package($versionStrategy);
```

### CDN with multiple providers
Spread load across several CDN endpoints:

```php
$urlPackage = new UrlPackage(
    [
        'https://cdn-eu.example.com/',
        'https://cdn-us.example.com/',
        'https://cdn-asia.example.com/',
    ],
    new JsonManifestVersionStrategy($manifestPath)
);
```

### Manifest-based versioning (Webpack/Vite)
Use the build tool output for asset paths:

```php
$package = new Package(
    new JsonManifestVersionStrategy(
        __DIR__ . '/../public/build/manifest.json',
        strict: true  // Fail fast on missing assets
    )
);
```

### Environment-specific configuration
Use different strategies for development and production:

```php
if ($isDevelopment) {
    $versionStrategy = new EmptyVersionStrategy();
} else {
    $versionStrategy = new JsonManifestVersionStrategy(__DIR__ . '/manifest.json');
}
$package = new Package($versionStrategy);
```

## Best practices

1. **Centralize asset management**: Use the Asset component instead of hardcoding URLs in templates
2. **Match the strategy to the environment**: `EmptyVersionStrategy` for development, `JsonManifestVersionStrategy` for production with build tools
3. **Write a custom strategy when the standard ones do not fit**
4. **Use named packages**: Organize assets by type (images, documents, scripts)
5. **Use request context**: Applications in subdirectories need it to build correct URLs
6. **Cache manifest files**: Load the manifest once and keep it in memory
7. **Handle missing assets**: In custom strategies, return an empty string or handle the error explicitly
8. **Use multiple CDNs for load distribution**: Selection is deterministic, so the same asset always comes from the same host
9. **Use schema-agnostic URLs**: Protocol-relative URLs (`//cdn.example.com/`) let the browser pick HTTP or HTTPS
10. **Test asset URLs**: Check them in both development and production

## PackageInterface

All package types implement `PackageInterface`:

```php
interface PackageInterface
{
    public function getUrl(string $path): string;
    public function getVersion(string $path): string;
}
```

Use this interface for type hints when passing packages around.

## Integration with Symfony Framework

In a full Symfony application, configure assets in `config/packages/framework.yaml`:

```yaml
framework:
    assets:
        version_strategy: 'Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy'
        version: 'v1'
        base_path: '/static/'
        base_urls:
            - 'https://cdn.example.com/'
```

Or register named packages as services for dependency injection.
