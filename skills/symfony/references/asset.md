# Symfony Asset Component

The Asset component provides a robust solution for managing web asset URLs and versioning. It eliminates hardcoded asset paths, enables cache busting, supports CDN distribution, and handles complex asset management scenarios at scale.

## Installation

```bash
composer require symfony/asset
```

## Core Concepts

### Asset Packages
Packages group assets sharing the same properties (versioning strategy, base path, CDN hosts, etc.). Choose the appropriate package type for your use case:

- **Package**: Basic package without base path manipulation
- **PathPackage**: Adds a common base path prefix (e.g., `/static/images`)
- **UrlPackage**: Generates absolute URLs for CDN or external hosting
- **Packages**: Manages multiple named packages with different configurations

### Versioning Strategies
Versioning adds identifiers to asset URLs to force browsers to download fresh versions when content changes:

- **EmptyVersionStrategy**: No versioning (basic assets)
- **StaticVersionStrategy**: Appends fixed version (e.g., `?v1`)
- **JsonManifestVersionStrategy**: Uses manifest file from build tools (Webpack, etc.)
- **Custom Strategies**: Implement `VersionStrategyInterface` for custom logic

## Version Strategies

### EmptyVersionStrategy
No versioning applied:
```php
use Symfony\Component\Asset\Package;
use Symfony\Component\Asset\VersionStrategy\EmptyVersionStrategy;

$package = new Package(new EmptyVersionStrategy());
echo $package->getUrl('/image.png');  // /image.png
```

### StaticVersionStrategy
Appends fixed version to asset URLs. Useful for simple, application-wide versioning:

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
Reads asset mappings from JSON manifest file. Use with Webpack, Gulp, or other build tools:

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

**Manifest JSON Format**:
```json
{
    "css/app.css": "build/css/app.b916426ea1d10021f3f17ce8031f93c2.css",
    "js/app.js": "build/js/app.13630905267b809161e71d0f8a0c017b.js"
}
```

**Constructor**: `JsonManifestVersionStrategy($manifestPath, $httpClient = null, $strict = false)`

### Custom Version Strategies
Implement `VersionStrategyInterface` for domain-specific versioning logic:

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

**Required Methods**:
- `getVersion(string $path): string` - Return version identifier
- `applyVersion(string $path): string` - Return versioned asset URL

## Package Classes

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
Groups assets with common base path. Useful for organizing assets by type:

```php
use Symfony\Component\Asset\PathPackage;
use Symfony\Component\Asset\VersionStrategy\StaticVersionStrategy;

$pathPackage = new PathPackage('/static/images', new StaticVersionStrategy('v1'));
echo $pathPackage->getUrl('logo.png');   // /static/images/logo.png?v1
echo $pathPackage->getUrl('/logo.png');  // /logo.png?v1 (absolute paths bypass base path)
```

**With Request Context** (for subdirectory applications):
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

**With Request Context** (auto-select URL scheme):
```php
use Symfony\Component\Asset\Context\RequestStackContext;

$urlPackage = new UrlPackage(
    ['http://example.com/', 'https://example.com/'],
    new StaticVersionStrategy('v1'),
    new RequestStackContext($requestStack)
);
// Automatically uses HTTPS for secure requests, HTTP for insecure
```

**Alternative Protocols**:
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
Manages multiple named packages for different asset types:

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

## Common Patterns

### Cache Busting with Static Version
Update version when deploying to force browser cache refresh:

```php
$versionStrategy = new StaticVersionStrategy($_ENV['ASSET_VERSION'] ?? 'v1');
$package = new Package($versionStrategy);
```

### CDN with Multiple Providers
Distribute load across multiple CDN endpoints:

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

### Manifest-Based Versioning (Webpack/Vite)
Use build tool output for optimized asset paths:

```php
$package = new Package(
    new JsonManifestVersionStrategy(
        __DIR__ . '/../public/build/manifest.json',
        strict: true  // Fail fast on missing assets
    )
);
```

### Environment-Specific Configuration
Different strategies for development and production:

```php
if ($isDevelopment) {
    $versionStrategy = new EmptyVersionStrategy();
} else {
    $versionStrategy = new JsonManifestVersionStrategy(__DIR__ . '/manifest.json');
}
$package = new Package($versionStrategy);
```

## Best Practices

1. **Use Centralized Asset Management**: Always use the Asset component instead of hardcoding URLs in templates
2. **Choose Appropriate Strategy**: Use `EmptyVersionStrategy` for development, `JsonManifestVersionStrategy` for production with build tools
3. **Implement Custom Strategies for Complex Logic**: When standard strategies don't fit your requirements
4. **Leverage Named Packages**: Organize assets by type (images, documents, scripts) using named packages
5. **Use Request Context**: Enable context awareness for applications in subdirectories
6. **Cache Manifest Files**: Load manifest files once and cache in memory for performance
7. **Handle Missing Assets Gracefully**: In custom strategies, return empty string or handle errors appropriately
8. **Use Multiple CDNs Wisely**: Deterministic selection ensures consistency; use for load distribution
9. **Schema-Agnostic URLs**: Use protocol-relative URLs (`//cdn.example.com/`) for auto-detection of HTTP/HTTPS
10. **Test Asset URLs**: Verify asset URLs in both development and production environments

## PackageInterface

All package types implement `PackageInterface`:

```php
interface PackageInterface
{
    public function getUrl(string $path): string;
    public function getVersion(string $path): string;
}
```

Use this interface for type hints when passing packages around your application.

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
