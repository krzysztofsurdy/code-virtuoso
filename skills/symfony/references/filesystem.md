# Symfony Filesystem Component

The Filesystem component offers a unified interface for filesystem operations across Windows, UNIX, and Linux platforms, with built-in error handling and atomic file operations.

## Installation

```bash
composer require symfony/filesystem
```

## Core Classes

### Filesystem Class

The main class for all filesystem operations. Initialize it with:

```php
use Symfony\Component\Filesystem\Filesystem;

$filesystem = new Filesystem();
```

### Path Class

Utility class for platform-independent path manipulation. Use static methods directly:

```php
use Symfony\Component\Filesystem\Path;

$normalized = Path::canonicalize('/var/www/vhost/../config.ini');
```

## Filesystem Methods

### Directory Operations

**mkdir()** - Create directories recursively with optional permissions:

```php
$filesystem->mkdir('/path/to/dir');
$filesystem->mkdir('/path/to/dir', 0700);  // Set permissions
$filesystem->mkdir(['/path/1', '/path/2']); // Create multiple
```

**exists()** - Check if files or directories exist:

```php
if ($filesystem->exists('/path/to/file')) {
    // File exists
}

$filesystem->exists(['/path/1', '/path/2']); // Check multiple
```

**remove()** - Delete files, directories, or symlinks:

```php
$filesystem->remove('/path/to/file.txt');
$filesystem->remove('/path/to/directory');
$filesystem->remove(['/path/1', '/path/2']); // Remove multiple
```

**mirror()** - Copy entire directory structure recursively:

```php
$filesystem->mirror('/path/to/source', '/path/to/target');

// With options
$filesystem->mirror('/source', '/target', null, [
    'override' => true,      // Overwrite newer files
    'copy_on_windows' => false, // Use symlinks instead
    'delete' => false,       // Delete non-source files
]);
```

### File Operations

**copy()** - Copy a single file:

```php
$filesystem->copy('source.jpg', 'destination.jpg');
$filesystem->copy('source.jpg', 'destination.jpg', true); // Overwrite
```

**touch()** - Set file access and modification time:

```php
$filesystem->touch('file.txt');
$filesystem->touch('file.txt', time() + 3600); // Set to 1 hour from now
$filesystem->touch('file.txt', time(), time()); // Both atime and mtime
```

**rename()** - Rename or move files and directories:

```php
$filesystem->rename('/tmp/file.ogg', '/path/file.ogg');
```

**dumpFile()** - Write file contents atomically (safe for concurrent access):

```php
$filesystem->dumpFile('file.txt', 'Hello World');
$filesystem->dumpFile('/path/config.json', json_encode($data));
```

**readFile()** - Read entire file contents:

```php
$contents = $filesystem->readFile('/path/to/file.txt');
```

**appendToFile()** - Append content to a file:

```php
$filesystem->appendToFile('logs.txt', 'New log entry');
```

**tempnam()** - Create temporary file:

```php
$tempFile = $filesystem->tempnam('/tmp', 'prefix_', '.png');
```

### Permission Operations

**chmod()** - Change file permissions:

```php
$filesystem->chmod('video.ogg', 0600);
$filesystem->chmod(['/path/1', '/path/2'], 0755);
```

**chown()** - Change file owner:

```php
$filesystem->chown('file.txt', 'www-data');
$filesystem->chown(['/path/1', '/path/2'], 'nginx');
```

**chgrp()** - Change file group:

```php
$filesystem->chgrp('file.txt', 'www-data');
$filesystem->chgrp(['/path/1', '/path/2'], 'nginx');
```

### Symlink Operations

**symlink()** - Create symbolic links:

```php
$filesystem->symlink('/path/to/source', '/path/to/link');

// Force overwrite existing symlink
$filesystem->symlink('/path/to/source', '/path/to/link', true);
```

**readlink()** - Read symlink target:

```php
$target = $filesystem->readlink('/path/to/link');

// Resolve all intermediate symlinks
$target = $filesystem->readlink('/path/to/link', true);
```

**makePathRelative()** - Get relative path between two absolute paths:

```php
$relative = $filesystem->makePathRelative(
    '/var/lib/symfony/src/Symfony/',
    '/var/lib/symfony/src/Symfony/Component'
);
// => ../

$relative = $filesystem->makePathRelative('/a/b/c', '/a/c');
// => ../b/c/
```

## Path Manipulation Methods

### Canonicalization

Remove ".", "..", backslashes, and resolve tilde (~):

```php
Path::canonicalize('/var/www/vhost/webmozart/../config.ini');
// => /var/www/vhost/config.ini

Path::canonicalize('~/config.yaml');
// => /home/user/config.yaml

Path::canonicalize('C:\\Program Files\\..\\PHP');
// => C:/PHP
```

### Joining Paths

Concatenate paths with proper separators:

```php
Path::join('/var/www', 'vhost', 'config.ini');
// => /var/www/vhost/config.ini

Path::join('C:\\Programs', 'Apache', 'Config');
// => C:/Programs/Apache/Config
```

### Normalizing Paths

Convert to forward slashes and standard format:

```php
Path::normalize('C:\\Program Files\\PHP');
// => C:/Program Files/PHP
```

### Absolute vs Relative Paths

**isAbsolute()** - Check if path is absolute:

```php
Path::isAbsolute('/var/www');        // => true
Path::isAbsolute('config.yaml');     // => false
Path::isAbsolute('C:\\Programs');    // => true
Path::isAbsolute('\\\\server\\share'); // => true
```

**isRelative()** - Check if path is relative:

```php
Path::isRelative('../config.yaml');  // => true
Path::isRelative('/var/www');        // => false
```

**makeAbsolute()** - Convert relative to absolute:

```php
Path::makeAbsolute('config/config.yaml', '/var/www/project');
// => /var/www/project/config/config.yaml
```

**makeRelative()** - Convert absolute to relative:

```php
Path::makeRelative('/var/www/project/config/config.yaml', '/var/www/project');
// => config/config.yaml
```

### Finding Common Base Path

**getLongestCommonBasePath()** - Find longest common base path:

```php
$basePath = Path::getLongestCommonBasePath(
    '/var/www/vhosts/project/httpdocs/config/config.yaml',
    '/var/www/vhosts/project/httpdocs/images/banana.gif'
);
// => /var/www/vhosts/project/httpdocs
```

**isBasePath()** - Check if path is base of another:

```php
Path::isBasePath("/var/www", "/var/www/project");        // => true
Path::isBasePath("/var/www", "/var/www-backup");         // => false
Path::isBasePath("/var/www", "/var/www");                // => true
```

### Directory Information

**getDirectory()** - Get directory component:

```php
Path::getDirectory('/etc/apache2/sites-available/default');
// => /etc/apache2/sites-available

Path::getDirectory('config.yaml');
// => .

Path::getDirectory("C:\\Programs\\Apache");
// => C:/Programs
```

**getRoot()** - Get root directory:

```php
Path::getRoot('/etc/apache2/sites-available');
// => /

Path::getRoot('C:\\Programs\\Apache\\Config');
// => C:/

Path::getRoot('//server/share/file.txt');
// => //server/share
```

## Error Handling

All operations throw exceptions on failure. Catch them for graceful handling:

```php
use Symfony\Component\Filesystem\Exception\IOExceptionInterface;
use Symfony\Component\Filesystem\Filesystem;

$filesystem = new Filesystem();

try {
    $filesystem->mkdir('/tmp/photos', 0700);
} catch (IOExceptionInterface $exception) {
    echo "Error creating directory at ".$exception->getPath();
}
```

**Exception Types:**

- `ExceptionInterface` - Base interface for all exceptions
- `IOExceptionInterface` - I/O operation failures
- `IOException` - Directory creation failures

## Common Use Cases

### Safe Configuration File Writing

```php
$config = ['debug' => true, 'version' => '1.0'];
$filesystem->dumpFile('/path/config.json', json_encode($config));
```

### Batch Directory Creation

```php
$paths = [
    '/app/cache',
    '/app/logs',
    '/app/uploads'
];
$filesystem->mkdir($paths);
```

### Mirror Project Structure

```php
$filesystem->mirror(
    '/source/project',
    '/backup/project',
    null,
    ['delete' => true, 'override' => true]
);
```

### Convert Path References

```php
$absolute = Path::makeAbsolute(
    $relativePath,
    __DIR__
);
$relative = Path::makeRelative(
    $absolutePath,
    sys_get_temp_dir()
);
```

### Clean Up Temporary Files

```php
if ($filesystem->exists($tempFile)) {
    $filesystem->remove($tempFile);
}
```

## Key Features

- Cross-platform support (Windows, UNIX, Linux)
- Atomic file write operations
- Recursive directory operations
- Batch operations with array support
- Comprehensive exception handling
- Symlink support with fallback mechanisms
- Safe path manipulation without filesystem access
