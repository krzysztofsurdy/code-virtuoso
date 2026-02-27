# Symfony Ldap Component

The Ldap Component provides utilities for connecting to and interacting with LDAP servers. It supports configuration options for connections, authentication methods (bind, SASL), querying, and CRUD operations on directory entries.

## Installation

```bash
composer require symfony/ldap
```

## Basic Connection & Authentication

### Create LDAP Connection

Create an Ldap instance using the ext_ldap adapter:

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

### Connection Configuration Options

- `host` - IP or hostname of LDAP server
- `port` - Port number (389 default, 636 for SSL)
- `version` - LDAP protocol version (3 recommended)
- `encryption` - `ssl`, `tls`, or `none`
- `connection_string` - Alternative to host/port
- `optReferrals` - Auto-follow referrals (true/false)
- `options` - Additional LDAP server options

### Authenticate to LDAP Server

Bind with DN and password:

```php
// Simple bind
$ldap->bind($dn, $password);

// SASL bind (alternative method)
$ldap->saslBind($dn, $password);

// Get authenticated user DN
$dn = $ldap->whoami();
```

Warning: Blank passwords are always valid on LDAP servers that allow unauthenticated binds. Validate passwords in your application.

## Querying & Searching

### Execute LDAP Queries

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

### Query Scopes

Control search depth with scope parameter:

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

## Creating & Updating Entries

### Create Entry Objects

Create new LDAP entries with attributes:

```php
use Symfony\Component\Ldap\Entry;

$entry = new Entry('cn=Fabien Potencier,dc=symfony,dc=com', [
    'sn' => ['Potencier'],
    'cn' => ['Fabien Potencier'],
    'mail' => ['fabien@symfony.com'],
    'objectClass' => ['inetOrgPerson', 'person'],
]);
```

### Add, Update & Delete Entries

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

### Manage Entry Attributes

Access and modify entry attributes:

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

### Apply Multiple Attribute Operations

Use batch operations for complex multi-attribute updates:

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

## Security Configuration

### LDAP Client Service Configuration

Configure LDAP in services.yaml:

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

### LDAP User Provider

Load users directly from LDAP server:

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

LDAP user provider options:
- `service` - Ldap service name
- `base_dn` - Base distinguished name
- `search_dn` - Read-only admin DN for queries
- `search_password` - Admin password (use env vars)
- `default_roles` - Roles assigned to fetched users
- `uid_key` - User identifier attribute (uid, sAMAccountName, userPrincipalName)
- `extra_fields` - Additional attributes to fetch
- `filter` - Custom query filter
- `role_fetcher` - Custom RoleFetcherInterface service

### Form Login LDAP Authentication

Authenticate users via login form with LDAP:

```yaml
# config/packages/security.yaml
security:
    firewalls:
        main:
            form_login_ldap:
                service: Symfony\Component\Ldap\Ldap
                dn_string: 'uid={user_identifier},dc=example,dc=com'
```

### HTTP Basic LDAP Authentication

Authenticate via HTTP Basic auth:

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

### Advanced: Query String for Dynamic DN Discovery

When users span multiple DN branches, use query_string:

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

## Security Best Practices

- Store sensitive credentials (search_password) as environment variables
- The Security component auto-escapes input when using LDAP user providers
- When using Ldap component directly, prevent LDAP injection attacks manually
- Always validate passwords in your application (avoid accepting blank passwords)
- Use TLS or SSL encryption for LDAP connections
- Set `referrals: false` in adapter options to prevent LDAP injection via referrals
