# Symfony Intl Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core classes and methods](#core-classes-and-methods)
- [Form field types](#form-field-types)
- [Common patterns](#common-patterns)
- [Reducing disk usage](#reducing-disk-usage)
- [Key concepts](#key-concepts)
- [Related components](#related-components)

## Overview

The Intl component gives access to localization data from the ICU (International Components for Unicode) library: names and codes for languages, scripts, countries, currencies, locales, and timezones, translated into the requested locale.

## Installation

```bash
composer require symfony/intl
```

## Core classes and methods

### Languages

Language names and codes in ISO 639-1 (alpha-2) and ISO 639-2 (alpha-3) formats.

```php
use Symfony\Component\Intl\Languages;

// Get all language names in current locale
$languages = Languages::getNames(); // ['en' => 'English', 'fr' => 'French', ...]

// Get name for specific language code
$name = Languages::getName('fr'); // 'French'
$name = Languages::getAlpha3Name('fra'); // 'French'

// Convert between code formats
$alpha3 = Languages::getAlpha3Code('en'); // 'eng'
$alpha2 = Languages::getAlpha2Code('eng'); // 'en'

// Validate language codes
$exists = Languages::exists('en'); // true
$exists = Languages::alpha3CodeExists('xyz'); // false

// Get all names in alpha-3 format
$names = Languages::getAlpha3Names(); // ['eng' => 'English', 'fra' => 'French', ...]
```

### Scripts

Script names for writing systems (e.g., Simplified and Traditional Chinese).

```php
use Symfony\Component\Intl\Scripts;

// Get all script names
$scripts = Scripts::getNames(); // ['Hans' => 'Simplified', 'Hant' => 'Traditional', ...]

// Get name for specific script
$name = Scripts::getName('Hans'); // 'Simplified'

// Validate script codes
$exists = Scripts::exists('Latn'); // true
```

### Countries

Country names and codes in ISO 3166-1 alpha-2, alpha-3, and numeric formats.

```php
use Symfony\Component\Intl\Countries;

// Get all country names
$countries = Countries::getNames(); // ['US' => 'United States', 'FR' => 'France', ...]

// Get name for specific country
$name = Countries::getName('US'); // 'United States'
$name = Countries::getAlpha3Name('USA'); // 'United States'

// Convert between code formats
$alpha3 = Countries::getAlpha3Code('US'); // 'USA'
$alpha2 = Countries::getAlpha2Code('USA'); // 'US'
$numeric = Countries::getNumericCode('US'); // '840'

// Reverse numeric lookups
$alpha2 = Countries::getAlpha2FromNumeric('840'); // 'US'

// Validate country codes
$exists = Countries::exists('US'); // true
$exists = Countries::alpha3CodeExists('XYZ'); // false
$exists = Countries::numericCodeExists('840'); // true

// Get all names in alpha-3 format
$names = Countries::getAlpha3Names(); // ['USA' => 'United States', ...]
```

### Currencies

Currency names, symbols, and metadata.

```php
use Symfony\Component\Intl\Currencies;

// Get all currency names
$currencies = Currencies::getNames(); // ['USD' => 'US Dollar', 'EUR' => 'Euro', ...]

// Get currency details
$name = Currencies::getName('USD'); // 'US Dollar'
$symbol = Currencies::getSymbol('EUR'); // '€'
$digits = Currencies::getFractionDigits('USD'); // 2
$roundingIncrement = Currencies::getRoundingIncrement('USD'); // 0

// Cash variants (for handling cash transactions)
$cashDigits = Currencies::getCashFractionDigits('USD'); // 2
$cashRounding = Currencies::getCashRoundingIncrement('USD'); // 0

// Get currencies for a specific country
$currencies = Currencies::forCountry('US'); // ['USD', ...]

// Validate currency usage
$valid = Currencies::isValidInCountry('USD', 'US'); // true
$valid = Currencies::isValidInAnyCountry('USD'); // true
$exists = Currencies::exists('USD'); // true
```

### Locales

Full locale identifiers (language, region, and parameters).

```php
use Symfony\Component\Intl\Locales;

// Get all locale names
$locales = Locales::getNames(); // ['en' => 'English', 'en_US' => 'English (United States)', ...]

// Get name for specific locale
$name = Locales::getName('en_US'); // 'English (United States)'

// Validate locale codes
$exists = Locales::exists('en_US'); // true
```

### Timezones

Timezone names and UTC/GMT offsets.

```php
use Symfony\Component\Intl\Timezones;

// Get all timezone names
$timezones = Timezones::getNames(); // ['America/New_York' => 'Eastern Time', ...]

// Get name for specific timezone
$name = Timezones::getName('America/New_York'); // 'Eastern Time'

// Get timezones for a country
$tzs = Timezones::forCountryCode('US'); // ['America/New_York', 'America/Chicago', ...]

// Get country for a timezone
$country = Timezones::getCountryCode('America/New_York'); // 'US'

// Get UTC offsets
$offset = Timezones::getRawOffset('America/New_York'); // -18000 (in seconds)
$gmtOffset = Timezones::getGmtOffset('America/New_York'); // 'GMT-5'

// Validate timezone codes
$exists = Timezones::exists('America/New_York'); // true
```

## Form field types

These Form field types use Intl data:

### CountryType

Selects a country by ISO 3166-1 alpha-2 code.

```php
use Symfony\Component\Form\Extension\Core\Type\CountryType;

$builder->add('country', CountryType::class, [
    'placeholder' => 'Select a country',
    'alpha3' => false, // Use 2-letter codes (default)
    'choice_translation_locale' => 'fr', // Display in French
]);

// With alpha-3 codes
$builder->add('country', CountryType::class, [
    'alpha3' => true, // Use 3-letter codes (USA instead of US)
]);
```

### CurrencyType

Selects a currency by ISO 4217 code, with filtering options.

```php
use Symfony\Component\Form\Extension\Core\Type\CurrencyType;

$builder->add('currency', CurrencyType::class, [
    'placeholder' => 'Choose a currency',
]);

// Filter by legal tender status
$builder->add('currency', CurrencyType::class, [
    'legal_tender' => true, // Show only current currencies
]);

// Filter by date
$builder->add('currency', CurrencyType::class, [
    'active_at' => new \DateTimeImmutable('2007-01-15'),
    'legal_tender' => true,
]);

// Show legacy currencies
$builder->add('currency', CurrencyType::class, [
    'legal_tender' => false,
]);
```

### LanguageType

Selects a language by ISO 639 code.

```php
use Symfony\Component\Form\Extension\Core\Type\LanguageType;

$builder->add('language', LanguageType::class, [
    'placeholder' => 'Choose a language',
]);

// Use 3-letter codes
$builder->add('language', LanguageType::class, [
    'alpha3' => true, // fra instead of fr
]);

// Display each language in its own language
$builder->add('language', LanguageType::class, [
    'choice_self_translation' => true, // Spanish: 'español', Chinese: '中文'
]);

// Custom translation locale
$builder->add('language', LanguageType::class, [
    'choice_translation_locale' => 'de', // Display in German
]);
```

### LocaleType

Selects a locale (language and country combination).

```php
use Symfony\Component\Form\Extension\Core\Type\LocaleType;

$builder->add('locale', LocaleType::class, [
    'placeholder' => 'Choose a locale',
    'choice_translation_locale' => 'fr', // Display in French
]);
```

### TimezoneType

Selects a timezone, in either PHP or ICU format.

```php
use Symfony\Component\Form\Extension\Core\Type\TimezoneType;

$builder->add('timezone', TimezoneType::class, [
    'placeholder' => 'Choose a timezone',
    'intl' => false, // Use PHP timezones (default)
]);

// Use ICU timezones (translatable to any language)
$builder->add('timezone', TimezoneType::class, [
    'intl' => true,
    'choice_translation_locale' => 'es', // Display in Spanish
]);

// Accept DateTimeZone objects
$builder->add('timezone', TimezoneType::class, [
    'input' => 'datetimezone', // Store as \DateTimeZone object
]);
```

## Common patterns

### Locale-aware data retrieval

```php
use Symfony\Component\Intl\Countries;

// Names in the default locale
$countries = Countries::getNames(\Locale::getDefault());
// Names in a specific locale
Countries::getNames('es_ES');
```

### Validate user input

```php
use Symfony\Component\Intl\Countries;
use Symfony\Component\Intl\Currencies;

$userCountry = 'US';
if (!Countries::exists($userCountry)) {
    throw new \InvalidArgumentException('Invalid country code');
}

$userCurrency = 'USD';
if (!Currencies::exists($userCurrency)) {
    throw new \InvalidArgumentException('Invalid currency code');
}
```

### Build custom select options

```php
use Symfony\Component\Intl\Languages;

$options = [];
foreach (Languages::getNames() as $code => $name) {
    $options[$name] = $code;
}
asort($options);
```

## Reducing disk usage

Compress the internal ICU data files to save disk space:

```bash
php ./vendor/symfony/intl/Resources/bin/compress
```

This compresses the binary data files with zlib and does not change behavior.

## Key concepts

- **Locale support**: most methods accept an optional locale parameter (defaults to `Locale::getDefault()`).
- **Error handling**: invalid codes throw `Symfony\Component\Intl\Exception\MissingResourceException`.
- **ISO standards**: ISO 639 for languages, ISO 3166-1 for countries, ISO 4217 for currencies.
- **ICU data**: all data comes from the Unicode Consortium's ICU project.
- **Form integration**: the Form field types use Intl data without extra configuration.

## Related components

- [Form Component](form.md) - form field integration
- [Validator Component](validator.md) - constraint validation
- [Translation Component](https://symfony.com/doc/current/translation.html) - message translation
