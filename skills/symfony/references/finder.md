# Symfony Finder Component

## Overview

The Finder Component is a Symfony utility that provides a fluent interface for finding files and directories based on different criteria. It supports glob patterns, regular expressions, file size, modification dates, and custom filtering logic.

## Installation

```bash
composer require symfony/finder
```

## Basic Usage

### Create a Finder Instance and Search

```php
use Symfony\Component\Finder\Finder;

$finder = new Finder();
$finder->files()->in(__DIR__);

// Check if results exist
if ($finder->hasResults()) {
    foreach ($finder as $file) {
        $absolutePath = $file->getRealPath();
        $relativePath = $file->getRelativePathname();
        // Process file
    }
}
```

### Important Notes

- The `in()` method is mandatory - it defines the search directory
- Finder returns `SplFileInfo` instances with extended methods for relative paths
- Finder is stateful - clone it before multiple searches: `foreach ((clone $finder)->name('pattern') as $file)`

## Specifying Search Location

### Single and Multiple Locations

```php
// Single location
$finder->in(__DIR__);

// Multiple locations
$finder->in([__DIR__, '/elsewhere']);
$finder->in(__DIR__)->in('/elsewhere');
```

### Wildcard Patterns

```php
// Wildcard patterns in path
$finder->in('src/Symfony/*/*/Resources');
```

### Exclude Directories

```php
$finder->exclude('ruby');
$finder->exclude(['vendor', 'node_modules']);
```

### Ignore Unreadable Directories

```php
$finder->ignoreUnreadableDirs()->in(__DIR__);
```

### URL Wrappers (FTP, S3, etc.)

```php
$finder->in('ftp://example.com/pub/');
```

## Filtering by Type

### Files and Directories

```php
// Find files only
$finder->files();

// Find directories only
$finder->directories();

// Follow symbolic links
$finder->files()->followLinks();
```

### Version Control Files

```php
// Don't ignore VCS files (Git, SVN, etc.)
$finder->ignoreVCS(false);

// Use .gitignore rules
$finder->ignoreVCSIgnored(true);
```

## Filtering by File Name

### Basic Name Filtering

```php
// Single pattern
$finder->files()->name('*.php');

// Multiple patterns via chaining
$finder->files()->name('*.php')->name('*.twig');

// Multiple patterns via array
$finder->files()->name(['*.php', '*.twig']);

// Exclude patterns
$finder->files()->notName('*.rb');
$finder->files()->notName(['*.rb', '*.py']);

// Regular expressions
$finder->files()->name('/\.php$/');
```

## Filtering by File Contents

### Search File Content

```php
// String search
$finder->files()->contains('lorem ipsum');

// Case-insensitive regex search
$finder->files()->contains('/lorem\s+ipsum$/i');

// Exclude files by content
$finder->files()->notContains('dolor sit amet');
```

## Filtering by Path

### Path Matching

```php
// Match paths containing "data"
$finder->path('data');

// Combine with name filtering
$finder->path('data')->name('*.xml');

// Multiple paths
$finder->path('data')->path('foo/bar');
$finder->path(['data', 'foo/bar']);

// Exclude paths
$finder->notPath('other/dir');
$finder->notPath(['first/dir', 'other/dir']);

// Regular expressions
$finder->path('/^foo\/bar/');
```

## Filtering by File Size

### Size Comparison

```php
// Single size filter
$finder->files()->size('< 1.5K');

// Size range
$finder->files()->size('>= 1K')->size('<= 2K');
$finder->files()->size(['>= 1K', '<= 2K']);
```

### Operators and Units

- Operators: `>`, `>=`, `<`, `<=`, `==`, `!=`
- Units: `k` (kilobytes), `ki` (kibibytes), `m` (megabytes), `mi` (mebibytes), `g` (gigabytes), `gi` (gibibytes)

```php
// Examples
$finder->files()->size('>= 1M')->size('<= 5M');  // 1-5 megabytes
$finder->files()->size('> 1Gi');                 // Greater than 1 gibibyte
$finder->files()->size('== 512k');               // Exactly 512 kilobytes
```

## Filtering by File Date

### Date Comparison

```php
// Date range
$finder->date('>= 2018-01-01')->date('<= 2018-12-31');
$finder->date(['>= 2018-01-01', '<= 2018-12-31']);

// Human-readable formats
$finder->date('since yesterday');
$finder->date('since 2020-01-01');
```

### Operators and Aliases

- Operators: `>`, `>=`, `<`, `<=`, `==`
- Aliases: `since`/`after` (equivalent to `>`), `until`/`before` (equivalent to `<`)
- Accepts any `strtotime()` compatible format

```php
// Examples
$finder->date('>= 2018-01-01');
$finder->date('since yesterday');
$finder->date('until next week');
```

## Filtering by Directory Depth

### Restrict Recursion Levels

```php
// Direct children only
$finder->depth('== 0');

// Less than 3 levels deep
$finder->depth('< 3');

// Depth range
$finder->depth('> 2')->depth('< 5');
$finder->depth(['> 2', '< 5']);
```

## Custom Filtering

### Filter Closure

```php
$filter = function (\SplFileInfo $file) {
    // Return false to exclude
    return strlen($file->getFilename()) <= 10;
};

$finder->files()->filter($filter);
```

### Directory Pruning (Performance Optimization)

```php
// Return false to skip entire directory
$filter = function (\SplFileInfo $file) {
    if ($file->isDir() && $file->getFilename() === '.git') {
        return false;  // Don't recurse into .git
    }
    return true;
};

$finder->filter($filter);
```

## Sorting Results

### Sort by Name

```php
// Standard name sort
$finder->sortByName();

// Natural sort order
$finder->sortByName(true);

// Case-insensitive sort
$finder->sortByCaseInsensitiveName();
$finder->sortByCaseInsensitiveName(true);  // natural sort
```

### Sort by File Properties

```php
$finder->sortByExtension();
$finder->sortBySize();
$finder->sortByType();
```

### Sort by Time

```php
$finder->sortByAccessedTime();
$finder->sortByChangedTime();
$finder->sortByModifiedTime();
```

### Custom Sorting

```php
$finder->sort(function (\SplFileInfo $a, \SplFileInfo $b): int {
    return strcmp($a->getRealPath(), $b->getRealPath());
});
```

### Reverse Sort Order

```php
$finder->sortByName()->reverseSorting();
```

## Converting and Iterating Results

### Convert to Array

```php
// Array with file paths as keys
$files = iterator_to_array($finder);

// Array with numeric keys (prevents key duplication)
$files = iterator_to_array($finder, false);

// Count results
$count = iterator_count($finder);
```

### Iterate Results

```php
foreach ($finder as $file) {
    // $file is SplFileInfo instance
    echo $file->getPathname();
}
```

## Reading File Contents

### Get File Contents

```php
use Symfony\Component\Finder\Finder;

$finder = new Finder();
$finder->files()->in(__DIR__);

foreach ($finder as $file) {
    $contents = $file->getContents();
    // Process contents
}
```

## SplFileInfo Extended Methods

The Finder returns `SplFileInfo` instances with these additional methods:

```php
$file->getRelativePath();      // Relative directory path
$file->getRelativePathname();  // Relative file path with filename
$file->getRealPath();          // Absolute path
$file->getContents();          // File contents
```

## Common Use Cases

### Find All PHP Files in Source Directory

```php
$finder = new Finder();
$finder->files()->name('*.php')->in('src');

foreach ($finder as $file) {
    echo $file->getRelativePathname();
}
```

### Find Large Files Modified Recently

```php
$finder = new Finder();
$finder->files()
    ->size('>= 10M')
    ->date('>= 2024-01-01')
    ->in(__DIR__);
```

### Find Files Matching Multiple Criteria

```php
$finder = new Finder();
$finder->files()
    ->name('*.php')
    ->notPath('*/tests/*')
    ->contains('TODO')
    ->size('<= 100K')
    ->in('src');
```

### Find Specific Files with Custom Filter

```php
$finder = new Finder();
$finder->files()
    ->in(__DIR__)
    ->filter(function (\SplFileInfo $file) {
        return $file->getSize() > 1000;
    });
```

## Performance Considerations

- Sorting methods load all results into memory first, which is slow for large datasets
- For large directory trees, use directory pruning in `filter()` to skip expensive recursion
- Git integration searches for `.gitignore` files from the search directory, not the repository root
- Start from the Git root for consistent `.gitignore` behavior
- Clone Finder instances before multiple searches to avoid state issues
