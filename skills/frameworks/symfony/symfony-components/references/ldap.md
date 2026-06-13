# Symfony Ldap Component

The Ldap component connects to LDAP servers and works with them. It supports connection options, authentication (bind and SASL), queries, and create, update, and delete operations on directory entries.

## Contents

- [Installation](#installation)
- [Connection and authentication](#connection-and-authentication)
- [Querying and searching](#querying-and-searching)
- [Creating and updating entries](#creating-and-updating-entries)
- [Batch Operations](#batch-operations)
- [Security configuration](#security-configuration)
- [Security best practices](#security-best-practices)

## Installation

```bash
composer require symfony/ldap
```

## Connection and authentication

### Create an LDAP connection

Create an `Ldap` instance with the `ext_ldap` adapter:

```php
use Symfony\Component\Ldap\Ldap;

// SSL connection
$ldap = Ldap::create('ext_ldap', [
    'host' => 'my-server',
    'port' => 636,
    'encryption' => 'ssl',
]);

// TLS connection
$ldap = Ldap::create('ext_ldap', [
    'host' => 'my-server',
    'port' => 389,
    'encryption' => 'tls',
]);

// Alternative using connection string
$ldap = Ldap::create('ext_ldap', [
    'connection_string' => 'ldaps://my-server:636',
]);
```

### Connection options

- `host` - IP or hostname of LDAP server
- `port` - Port number (389 default, 636 for SSL)
- `version` - LDAP protocol version (3 recommended)
- `encryption` - `ssl`, `tls`, or `none`
- `connection_string` - Alternative to host/port
- `optReferrals` - Auto-follow referrals (true/false)
- `options` - Additional LDAP server options

### Authenticate to the server

Bind with a DN and password:

```php
// Simple bind
$ldap->bind($dn, $password);

// SASL bind (alternative method)
$ldap->saslBind($dn, $password);

// Get authenticated user DN
$dn = $ldap->whoami();
```

Warning: a blank password is always accepted by LDAP servers that allow unauthenticated binds, so reject blank passwords in your application.

## Querying and searching

### Execute LDAP queries

```php
// Basic query
$query = $ldap->query('dc=symfony,dc=com', '(&(objectclass=person)(ou=Maintainers))');
$results = $query->execute();

// Filter specific attributes
$query = $ldap->query('dc=symfony,dc=com', '(cn=*)', [
    'filter' => ['cn', 'mail', 'telephoneNumber'],
]);
$results = $query->execute();

// Iterate results
foreach ($results as $entry) {
    $cn = $entry->getAttribute('cn');
}

// Convert to array
$all_results = $query->execute()->toArray();
```

### Query scopes

The `scope` option controls search depth:

```php
use Symfony\Component\Ldap\Adapter\QueryInterface;

// Subtree search (default) - searches recursively
$query = $ldap->query('dc=symfony,dc=com', '(cn=*)', [
    'scope' => QueryInterface::SCOPE_SUB,
]);

// Base search - only the specified entry
$query = $ldap->query('dc=symfony,dc=com', '(cn=*)', [
    'scope' => QueryInterface::SCOPE_BASE,
]);

// One level - immediate children only
$query = $ldap->query('dc=symfony,dc=com', '(cn=*)', [
    'scope' => QueryInterface::SCOPE_ONE,
]);
```

## Creating and updating entries

### Create entry objects

```php
use Symfony\Component\Ldap\Entry;

$entry = new Entry('cn=Fabien Potencier,dc=symfony,dc=com', [
    'sn' => ['Potencier'],
    'cn' => ['Fabien Potencier'],
    'mail' => ['fabien@symfony.com'],
    'objectClass' => ['inetOrgPerson', 'person'],
]);
```

### Add, update, and delete entries

```php
$entryManager = $ldap->getEntryManager();

// Create entry
$entryManager->add($entry);

// Update entry attributes
$entry->setAttribute('email', ['new-email@example.com']);
$entryManager->update($entry);

// Remove entry
$entryManager->remove($entry);

// Delete entry by DN
$entryManager->remove(new Entry('cn=Test User,dc=symfony,dc=com'));
```

### Manage entry attributes

```php
// Get single attribute value
$phoneNumber = $entry->getAttribute('phoneNumber');

// Check attribute exists (case-insensitive if false)
$hasContractor = $entry->hasAttribute('contractorCompany', false);

// Add multi-valued attributes
$entryManager->addAttributeValues($entry, 'mail', [
    'user1@example.com',
    'user2@example.com',
]);

// Remove specific attribute values
$entryManager->removeAttributeValues($entry, 'mail', [
    'old-email@example.com',
]);
```

## Batch Operations

### Apply several attribute operations

Batch operations update several attributes in one call:

```php
use Symfony\Component\Ldap\Adapter\ExtLdap\UpdateOperation;

$entryManager->applyOperations($entry->getDn(), [
    new UpdateOperation(LDAP_MODIFY_BATCH_ADD, 'mail', 'new1@example.com'),
    new UpdateOperation(LDAP_MODIFY_BATCH_ADD, 'mail', 'new2@example.com'),
    new UpdateOperation(LDAP_MODIFY_BATCH_REPLACE, 'description', 'Updated user'),
    new UpdateOperation(LDAP_MODIFY_BATCH_REMOVE_ALL, 'labeledURI', null),
]);
```

Operation types:
- `LDAP_MODIFY_BATCH_ADD` - Add attribute value
- `LDAP_MODIFY_BATCH_REMOVE` - Remove specific value
- `LDAP_MODIFY_BATCH_REMOVE_ALL` - Remove all values (set values to null)
- `LDAP_MODIFY_BATCH_REPLACE` - Replace attribute value

## Security configuration

### LDAP client service

Configure the client in `services.yaml`:

```yaml
# config/services.yaml
services:
    Symfony\Component\Ldap\Ldap:
        arguments: ['@Symfony\Component\Ldap\Adapter\ExtLdap\Adapter']
    Symfony\Component\Ldap\Adapter\ExtLdap\Adapter:
        arguments:
            -   host: my-server
                port: 389
                encryption: tls
                options:
                    protocol_version: 3
                    referrals: false
```

### LDAP user provider

Loads users directly from the LDAP server:

```yaml
# config/packages/security.yaml
security:
    providers:
        my_ldap:
            ldap:
                service: Symfony\Component\Ldap\Ldap
                base_dn: dc=example,dc=com
                search_dn: 'cn=admin,dc=example,dc=com'
                search_password: '%env(LDAP_PASSWORD)%'
                default_roles: [ROLE_USER]
                uid_key: uid
                extra_fields: ['mail', 'telephoneNumber']
                filter: '(&(uid={user_identifier})(accountStatus=active))'
```

User provider options:
- `service` - Ldap service name
- `base_dn` - Base distinguished name
- `search_dn` - Read-only admin DN for queries
- `search_password` - Admin password (use an environment variable)
- `default_roles` - Roles assigned to fetched users
- `uid_key` - User identifier attribute (uid, sAMAccountName, userPrincipalName)
- `extra_fields` - Extra attributes to fetch
- `filter` - Custom query filter
- `role_fetcher` - Custom RoleFetcherInterface service

### Form login LDAP authentication

Authenticates users through a login form against LDAP:

```yaml
# config/packages/security.yaml
security:
    firewalls:
        main:
            form_login_ldap:
                service: Symfony\Component\Ldap\Ldap
                dn_string: 'uid={user_identifier},dc=example,dc=com'
```

### HTTP Basic LDAP authentication

Authenticates through HTTP Basic auth:

```yaml
# config/packages/security.yaml
security:
    firewalls:
        main:
            stateless: true
            http_basic_ldap:
                service: Symfony\Component\Ldap\Ldap
                dn_string: 'uid={user_identifier},dc=example,dc=com'
```

### Dynamic DN discovery with query_string

When users are spread across several DN branches, use `query_string`:

```yaml
# config/packages/security.yaml
security:
    firewalls:
        main:
            form_login_ldap:
                service: Symfony\Component\Ldap\Ldap
                dn_string: 'dc=example,dc=com'
                query_string: '(&(uid={user_identifier})(memberOf=cn=users,ou=Services,dc=example,dc=com))'
                search_dn: 'cn=admin,dc=example,dc=com'
                search_password: '%env(LDAP_PASSWORD)%'
```

## Security best practices

- Store credentials such as `search_password` in environment variables.
- The Security component escapes input automatically when you use the LDAP user provider. When you use the Ldap component directly, escape input yourself to prevent LDAP injection.
- Reject blank passwords in your application.
- Use TLS or SSL for LDAP connections.
- Set `referrals: false` in the adapter options to prevent LDAP injection via referrals.
