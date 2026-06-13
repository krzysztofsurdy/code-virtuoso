# Symfony Finder Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Basic usage](#basic-usage)
- [Specifying the search location](#specifying-the-search-location)
- [Filtering by type](#filtering-by-type)
- [Filtering by file name](#filtering-by-file-name)
- [Filtering by file contents](#filtering-by-file-contents)
- [Filtering by path](#filtering-by-path)
- [Filtering by file size](#filtering-by-file-size)
- [Filtering by file date](#filtering-by-file-date)
- [Filtering by directory depth](#filtering-by-directory-depth)
- [Custom filtering](#custom-filtering)
- [Sorting results](#sorting-results)
- [Converting and iterating results](#converting-and-iterating-results)
- [Reading file contents](#reading-file-contents)
- [SplFileInfo extended methods](#splfileinfo-extended-methods)
- [Common use cases](#common-use-cases)
- [Performance](#performance)

## Overview

The Finder component has a fluent interface for finding files and directories. It filters by glob pattern, regular expression, file size, modification date, content, depth, and custom closures.

## Installation

```bash
composer require symfony/finder
```

## Basic usage

### Create a Finder and search

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

### Notes

- `in()` is mandatory. It defines the search directory.
- Finder returns `SplFileInfo` instances with extra methods for relative paths.
- Finder is stateful, so clone it before running several searches: `foreach ((clone $finder)->name('pattern') as $file)`

## Specifying the search location

### Single and multiple locations

```php
// Single location
$finder->in(__DIR__);

// Multiple locations
$finder->in([__DIR__, '/elsewhere']);
$finder->in(__DIR__)->in('/elsewhere');
```

### Wildcard patterns

```php
// Wildcard patterns in path
$finder->in('src/Symfony/*/*/Resources');
```

### Exclude directories

```php
$finder->exclude('ruby');
$finder->exclude(['vendor', 'node_modules']);
```

### Ignore unreadable directories

```php
$finder->ignoreUnreadableDirs()->in(__DIR__);
```

### URL wrappers (FTP, S3, etc.)

```php
$finder->in('ftp://example.com/pub/');
```

## Filtering by type

### Files and directories

```php
// Find files only
$finder->files();

// Find directories only
$finder->directories();

// Follow symbolic links
$finder->files()->followLinks();
```

### Version control files

```php
// Don't ignore VCS files (Git, SVN, etc.)
$finder->ignoreVCS(false);

// Use .gitignore rules
$finder->ignoreVCSIgnored(true);
```

## Filtering by file name

### Name filtering

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

## Filtering by file contents

### Search file content

```php
// String search
$finder->files()->contains('lorem ipsum');

// Case-insensitive regex search
$finder->files()->contains('/lorem\s+ipsum$/i');

// Exclude files by content
$finder->files()->notContains('dolor sit amet');
```

## Filtering by path

### Path matching

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

## Filtering by file size

### Size comparison

```php
// Single size filter
$finder->files()->size('< 1.5K');

// Size range
$finder->files()->size('>= 1K')->size('<= 2K');
$finder->files()->size(['>= 1K', '<= 2K']);
```

### Operators and units

- Operators: `>`, `>=`, `<`, `<=`, `==`, `!=`
- Units: `k` (kilobytes), `ki` (kibibytes), `m` (megabytes), `mi` (mebibytes), `g` (gigabytes), `gi` (gibibytes)

```php
// Examples
$finder->files()->size('>= 1M')->size('<= 5M');  // 1-5 megabytes
$finder->files()->size('> 1Gi');                 // Greater than 1 gibibyte
$finder->files()->size('== 512k');               // Exactly 512 kilobytes
```

## Filtering by file date

### Date comparison

```php
// Date range
$finder->date('>= 2018-01-01')->date('<= 2018-12-31');
$finder->date(['>= 2018-01-01', '<= 2018-12-31']);

// Human-readable formats
$finder->date('since yesterday');
$finder->date('since 2020-01-01');
```

### Operators and aliases

- Operators: `>`, `>=`, `<`, `<=`, `==`
- Aliases: `since`/`after` (equivalent to `>`), `until`/`before` (equivalent to `<`)
- Accepts any format `strtotime()` understands

```php
// Examples
$finder->date('>= 2018-01-01');
$finder->date('since yesterday');
$finder->date('until next week');
```

## Filtering by directory depth

### Restrict recursion levels

```php
// Direct children only
$finder->depth('== 0');

// Less than 3 levels deep
$finder->depth('< 3');

// Depth range
$finder->depth('> 2')->depth('< 5');
$finder->depth(['> 2', '< 5']);
```

## Custom filtering

### Filter closure

```php
$filter = function (\SplFileInfo $file) {
    // Return false to exclude
    return strlen($file->getFilename()) <= 10;
};

$finder->files()->filter($filter);
```

### Directory pruning

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

## Sorting results

### Sort by name

```php
// Standard name sort
$finder->sortByName();

// Natural sort order
$finder->sortByName(true);

// Case-insensitive sort
$finder->sortByCaseInsensitiveName();
$finder->sortByCaseInsensitiveName(true);  // natural sort
```

### Sort by file properties

```php
$finder->sortByExtension();
$finder->sortBySize();
$finder->sortByType();
```

### Sort by time

```php
$finder->sortByAccessedTime();
$finder->sortByChangedTime();
$finder->sortByModifiedTime();
```

### Custom sorting

```php
$finder->sort(function (\SplFileInfo $a, \SplFileInfo $b): int {
    return strcmp($a->getRealPath(), $b->getRealPath());
});
```

### Reverse sort order

```php
$finder->sortByName()->reverseSorting();
```

## Converting and iterating results

### Convert to array

```php
// Array with file paths as keys
$files = iterator_to_array($finder);

// Array with numeric keys (avoids key collisions)
$files = iterator_to_array($finder, false);

// Count results
$count = iterator_count($finder);
```

### Iterate results

```php
foreach ($finder as $file) {
    // $file is SplFileInfo instance
    echo $file->getPathname();
}
```

## Reading file contents

### Get file contents

```php
use Symfony\Component\Finder\Finder;

$finder = new Finder();
$finder->files()->in(__DIR__);

foreach ($finder as $file) {
    $contents = $file->getContents();
    // Process contents
}
```

## SplFileInfo extended methods

Finder returns `SplFileInfo` instances with these additional methods:

```php
$file->getRelativePath();      // Relative directory path
$file->getRelativePathname();  // Relative file path with filename
$file->getRealPath();          // Absolute path
$file->getContents();          // File contents
```

## Common use cases

### Find all PHP files in a source directory

```php
$finder = new Finder();
$finder->files()->name('*.php')->in('src');

foreach ($finder as $file) {
    echo $file->getRelativePathname();
}
```

### Find large, recently modified files

```php
$finder = new Finder();
$finder->files()
    ->size('>= 10M')
    ->date('>= 2024-01-01')
    ->in(__DIR__);
```

### Find files matching several criteria

```php
$finder = new Finder();
$finder->files()
    ->name('*.php')
    ->notPath('*/tests/*')
    ->contains('TODO')
    ->size('<= 100K')
    ->in('src');
```

### Find files with a custom filter

```php
$finder = new Finder();
$finder->files()
    ->in(__DIR__)
    ->filter(function (\SplFileInfo $file) {
        return $file->getSize() > 1000;
    });
```

## Performance

- Sorting methods load all results into memory first, which is slow for large result sets.
- For large directory trees, prune directories in `filter()` to skip expensive recursion.
- Git integration looks for `.gitignore` files starting from the search directory, not the repository root. Start from the Git root for consistent `.gitignore` behavior.
- Clone Finder instances before running several searches.
