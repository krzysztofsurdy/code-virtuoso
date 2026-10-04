# GraphQL API Patterns

The current released GraphQL specification is the September 2025 edition (it follows October 2021). Serving GraphQL over HTTP is covered by the separate GraphQL over HTTP spec, which is still a working draft.

## Contents

- [Schema design](#schema-design)
- [Query design](#query-design)
- [Mutation design](#mutation-design)
- [Pagination with Relay-style connections](#pagination-with-relay-style-connections)
- [Performance](#performance)
- [Schema evolution](#schema-evolution)
- [Security](#security)

## Schema design

### Types

Model domain concepts as object types. Use non-null (`!`) for fields that are always present:

```graphql
type Product {
  id: ID!
  name: String!
  description: String
  price: Float!
  category: Category!
  tags: [String!]!
}
```

### Interfaces and unions

Use interfaces when types share common fields:

```graphql
interface Node {
  id: ID!
}

interface Timestamped {
  createdAt: DateTime!
  updatedAt: DateTime!
}

type User implements Node & Timestamped {
  id: ID!
  name: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

Use unions for types that share no common fields:

```graphql
union SearchResult = User | Product | Article
```

### Enums

Use enums for finite sets of values:

```graphql
enum OrderStatus {
  PENDING
  CONFIRMED
  SHIPPED
  DELIVERED
  CANCELLED
}
```

## Query design

- Keep queries flat where possible. Avoid schemas that encourage deeply nested queries (5+ levels).
- Name queries descriptively: `user`, `users`, `ordersByCustomer`, not `getData` or `fetch`.
- Use arguments for filtering and scoping:

```graphql
type Query {
  user(id: ID!): User
  users(filter: UserFilter, first: Int, after: String): UserConnection!
  orders(customerId: ID!, status: OrderStatus): OrderConnection!
}
```

## Mutation design

### Input types

Always use dedicated input types for mutations:

```graphql
input CreateUserInput {
  name: String!
  email: String!
  role: UserRole = MEMBER
}
```

### Payload types

Return a payload type that includes both the result and potential user errors:

```graphql
type CreateUserPayload {
  user: User
  errors: [UserError!]!
}

type UserError {
  field: String!
  code: String!
  message: String!
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
}
```

This pattern separates **user errors** (validation failures, business rule violations) from **system errors** (returned in the top-level `errors` array). Clients can handle each category differently.

## Pagination with Relay-style connections

The Relay connection specification is the standard for paginated lists in GraphQL:

```graphql
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

Usage in queries:

```graphql
query {
  users(first: 10, after: "cursor123") {
    edges {
      node { id name email }
      cursor
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

**Why connections over simple lists:** they give stable cursor-based pagination, room for metadata on edges (e.g., relationship properties), and one pattern across the whole schema.

## Performance

### DataLoader pattern for N+1

Without batching, resolving a list of orders with their customers triggers one database query per order. The dataloader pattern collects all IDs within a single tick and issues one batched query:

```
Without DataLoader:        With DataLoader:
SELECT * FROM orders       SELECT * FROM orders
SELECT * FROM users/1      SELECT * FROM users WHERE id IN (1, 2, 3)
SELECT * FROM users/2
SELECT * FROM users/3
```

Create dataloaders per request so stale data is never cached across requests.

### Query complexity and depth limits

Prevent expensive queries by assigning a cost to each field and rejecting queries that exceed a budget:

- **Depth limiting:** reject queries nested beyond a threshold (e.g., 10 levels)
- **Complexity analysis:** assign cost per field (scalar = 1, list = cost x estimated size), reject if total exceeds limit
- Use both together for defense in depth

## Schema evolution

GraphQL schemas can evolve without versioning if changes are additive only:

**Non-breaking (safe):**
- Adding new types, fields, enum values, or arguments with defaults
- Deprecating fields (they remain functional)

**Breaking (avoid):**
- Removing types or fields
- Renaming types or fields
- Changing a field's type
- Making a nullable field non-null
- Removing enum values

Use `@deprecated` to signal fields for removal:

```graphql
type User {
  name: String! @deprecated(reason: "Use firstName and lastName instead")
  firstName: String!
  lastName: String!
}
```

Monitor deprecated field usage via query analytics before removing them.

## Security

- **Query depth limiting:** reject queries exceeding a maximum depth
- **Cost analysis:** assign and enforce a per-query complexity budget
- **Persisted queries:** allow only pre-approved query hashes in production, which rules out arbitrary query execution
- **Introspection:** disable in production or restrict to authenticated admin users
- **Timeouts:** set per-resolver and per-request execution time limits
- **Rate limiting:** limit by query complexity, not only request count
