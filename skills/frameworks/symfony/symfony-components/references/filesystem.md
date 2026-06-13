# Symfony Filesystem Component

The Filesystem component gives one interface for filesystem operations on Windows, UNIX, and Linux. It throws exceptions on failure and supports atomic file writes.

## Contents

- [Installation](#installation)
- [Core classes](#core-classes)
- [Filesystem methods](#filesystem-methods)
- [Path manipulation methods](#path-manipulation-methods)
- [Error handling](#error-handling)
- [Common use cases](#common-use-cases)
- [Key features](#key-features)

## Installation

```bash
composer require symfony/filesystem
```

## Core classes

### Filesystem class

The main class for filesystem operations:

```php
use Symfony\Component\Filesystem\Filesystem;

$filesystem = new Filesystem();
```

### Path class

Utility class for platform-independent path manipulation. Its methods are static:

```php
use Symfony\Component\Filesystem\Path;

$normalized = Path::canonicalize('/var/www/vhost/../config.ini');
```

## Filesystem methods

### Directory operations

**mkdir()** - Create directories recursively, with optional permissions:

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

**mirror()** - Copy a whole directory structure recursively:

```php
$filesystem->mirror('/path/to/source', '/path/to/target');

// With options
$filesystem->mirror('/source', '/target', null, [
    'override' => true,      // Overwrite newer files
    'copy_on_windows' => false, // Use symlinks instead
    'delete' => false,       // Delete non-source files
]);
```

### File operations

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

**readFile()** - Read the entire contents of a file:

```php
$contents = $filesystem->readFile('/path/to/file.txt');
```

**appendToFile()** - Append content to a file:

```php
$filesystem->appendToFile('logs.txt', 'New log entry');
```

**tempnam()** - Create a temporary file:

```php
$tempFile = $filesystem->tempnam('/tmp', 'prefix_', '.png');
```

### Permission operations

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

### Symlink operations

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

## Path manipulation methods

### Canonicalization

Removes "." and "..", converts backslashes, and resolves the tilde (~):

```php
Path::canonicalize('/var/www/vhost/webmozart/../config.ini');
// => /var/www/vhost/config.ini

Path::canonicalize('~/config.yaml');
// => /home/user/config.yaml

Path::canonicalize('C:\\Program Files\\..\\PHP');
// => C:/PHP
```

### Joining paths

Concatenate paths with proper separators:

```php
Path::join('/var/www', 'vhost', 'config.ini');
// => /var/www/vhost/config.ini

Path::join('C:\\Programs', 'Apache', 'Config');
// => C:/Programs/Apache/Config
```

### Normalizing paths

Convert to forward slashes and standard format:

```php
Path::normalize('C:\\Program Files\\PHP');
// => C:/Program Files/PHP
```

### Absolute and relative paths

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

### Finding a common base path

**getLongestCommonBasePath()** - Find longest common base path:

```php
$basePath = Path::getLongestCommonBasePath(
    '/var/www/vhosts/project/httpdocs/config/config.yaml',
    '/var/www/vhosts/project/httpdocs/images/banana.gif'
);
// => /var/www/vhosts/project/httpdocs
```

**isBasePath()** - Check whether a path is the base of another:

```php
Path::isBasePath("/var/www", "/var/www/project");        // => true
Path::isBasePath("/var/www", "/var/www-backup");         // => false
Path::isBasePath("/var/www", "/var/www");                // => true
```

### Directory information

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

## Error handling

All operations throw exceptions on failure:

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

Exception types:

- `ExceptionInterface` - Base interface for all exceptions
- `IOExceptionInterface` - I/O operation failures
- `IOException` - Directory creation failures

## Common use cases

### Safe configuration file writing

```php
$config = ['debug' => true, 'version' => '1.0'];
$filesystem->dumpFile('/path/config.json', json_encode($config));
```

### Batch directory creation

```php
$paths = [
    '/app/cache',
    '/app/logs',
    '/app/uploads'
];
$filesystem->mkdir($paths);
```

### Mirror a project structure

```php
$filesystem->mirror(
    '/source/project',
    '/backup/project',
    null,
    ['delete' => true, 'override' => true]
);
```

### Convert path references

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

### Clean up temporary files

```php
if ($filesystem->exists($tempFile)) {
    $filesystem->remove($tempFile);
}
```

## Key features

- Cross-platform support (Windows, UNIX, Linux)
- Atomic file write operations
- Recursive directory operations
- Batch operations with array support
- Exceptions on every failure
- Symlink support with fallback mechanisms
- Safe path manipulation without filesystem access
