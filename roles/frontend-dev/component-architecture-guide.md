# Component Architecture Guide

Principles and patterns for designing frontend component hierarchies. Covers decomposition, composition patterns, state management decisions, prop design, and naming conventions.

## Contents

- [Component types](#component-types)
- [Decomposition strategy](#decomposition-strategy)
- [Composition patterns](#composition-patterns)
- [State management decisions](#state-management-decisions)
- [Prop design](#prop-design)
- [Naming conventions](#naming-conventions)
- [Component checklist](#component-checklist)
- [Anti-patterns](#anti-patterns)

---

## Component types

| Type | Purpose | Characteristics |
|---|---|---|
| **Presentational** | Render UI based on props | No side effects, no data fetching, easily testable |
| **Container** | Manage state and data fetching | Orchestrate presentational components, handle API calls |
| **Layout** | Define page structure | Grid, sidebar, header, footer arrangements |
| **Page** | Route-level entry points | Compose containers and layouts for a specific route |
| **Shared/Library** | Reusable across features | Button, Modal, Table, Input (generic and configurable) |

---

## Decomposition strategy

### When to split a component

| Signal | Action |
|---|---|
| Component file exceeds 200 lines | Extract sub-components |
| Component has more than 5 props related to different concerns | Split by concern |
| A section of the component is reused elsewhere | Extract to shared component |
| Component manages both data fetching and rendering | Split into container + presentational |
| Testing requires mocking many dependencies | Component has too many responsibilities |

### How to decompose

1. **Identify boundaries**: Each visual section or logical concern becomes a candidate component
2. **Name the component**: If you struggle to name it, the boundary is wrong
3. **Define the interface**: What props does it need? What events does it emit?
4. **Extract from the top down**: Start with the page, identify containers, then presentational components
5. **Verify independence**: Can this component be tested without rendering its parent?

### Component tree example

```
ProductListPage (page)
  ProductListContainer (container - fetches data, manages filters)
    SearchBar (shared - text input with debounce)
    FilterPanel (presentational - displays filter options)
      FilterGroup (presentational - single filter category)
    ProductGrid (presentational - renders product cards in grid)
      ProductCard (presentational - single product display)
        PriceDisplay (shared - formats and displays price)
        StockBadge (shared - shows in-stock/out-of-stock)
    Pagination (shared - page navigation controls)
    EmptyState (shared - displayed when no results)
    ErrorBanner (shared - displayed on fetch failure)
```

---

## Composition patterns

### Slot/Children Pattern

Pass content to a component instead of configuring it with props. Prefer composition over configuration.

**Instead of:**

```
<Card title="Product" subtitle="Details" icon="box" footer="Save" />
```

**Prefer:**

```
<Card>
  <CardHeader>
    <Icon name="box" />
    <h2>Product</h2>
  </CardHeader>
  <CardBody>
    <ProductDetails />
  </CardBody>
  <CardFooter>
    <Button>Save</Button>
  </CardFooter>
</Card>
```

### Compound Component Pattern

Group related components that share implicit state.

```
<Tabs defaultActive="details">
  <TabList>
    <Tab id="details">Details</Tab>
    <Tab id="reviews">Reviews</Tab>
    <Tab id="specs">Specifications</Tab>
  </TabList>
  <TabPanel id="details"><ProductDetails /></TabPanel>
  <TabPanel id="reviews"><ProductReviews /></TabPanel>
  <TabPanel id="specs"><ProductSpecs /></TabPanel>
</Tabs>
```

Benefits:
- Each piece is independently styleable and testable
- The parent (`Tabs`) manages shared state internally
- Consumers do not need to wire up state manually

### Render Prop / Function-as-Child Pattern

Delegate rendering decisions to the consumer.

```
<DataLoader url="/api/products">
  {({ data, loading, error }) => {
    if (loading) return <Spinner />;
    if (error) return <ErrorBanner message={error} />;
    return <ProductGrid products={data} />;
  }}
</DataLoader>
```

Use when:
- The data-fetching or state logic is reusable but the rendering varies
- You want to avoid creating multiple wrapper components for different displays

### Higher-Order Component Pattern

Wrap a component to add behavior. Use it sparingly, because composition is usually clearer.

```
const withAuth = (Component) => {
  return (props) => {
    const user = useAuth();
    if (!user) return <RedirectToLogin />;
    return <Component {...props} user={user} />;
  };
};
```

---

## State management decisions

### State location matrix

| State Type | Where to Keep It | Examples |
|---|---|---|
| **UI state** | Local component state | Open/closed toggles, hover state, form input values |
| **Shared UI state** | Lifted to nearest common parent | Active tab shared between sibling components |
| **Server state** | Data fetching library with cache | API responses, paginated lists |
| **URL state** | Router/URL parameters | Filters, pagination, selected tab, search query |
| **Global app state** | State management store | Authenticated user, feature flags, theme preference |

### Decision flowchart

```
Is this state used by only one component?
  YES -> Local state
  NO  -> Is it used by siblings or nearby components?
    YES -> Lift to nearest common parent
    NO  -> Is it server data (from an API)?
      YES -> Data fetching library with cache
      NO  -> Is it URL-dependent (filters, pagination)?
        YES -> URL/router state
        NO  -> Global state store
```

### Rules for state

| Rule | Rationale |
|---|---|
| Keep state as local as possible | Reduces coupling and re-render scope |
| Derive values instead of storing them | If a value can be computed from other state, do not duplicate it |
| Single source of truth | Each piece of state has exactly one owner |
| URL is state | Anything the user should be able to bookmark or share belongs in the URL |
| Minimize global state | Global state is shared mutable state, so the less the better |

---

## Prop design

### Prop guidelines

| Guideline | Example |
|---|---|
| Use descriptive names | `isLoading` not `flag`, `onSubmit` not `handler` |
| Prefer primitives over objects | `userName` not `user` when only the name is needed |
| Use consistent naming for callbacks | `onSomething` pattern: `onClick`, `onChange`, `onSubmit` |
| Provide defaults | `limit = 25` instead of requiring every consumer to set it |
| Avoid boolean props that invert meaning | `isVisible` not `isHidden` (double negatives are confusing) |

### Prop count limits

| Prop Count | Assessment | Action |
|---|---|---|
| 1-3 | Good | No action needed |
| 4-6 | Acceptable | Review if any props can be grouped |
| 7-10 | Warning | Consider splitting the component |
| 10+ | Too many | Split the component or use composition |

---

## Naming conventions

### Component names

| Convention | Example |
|---|---|
| PascalCase for components | `ProductCard`, `SearchBar` |
| Prefix shared components with context | `FormInput`, `FormSelect`, `FormError` |
| Suffix page-level components with Page | `ProductListPage`, `CheckoutPage` |
| Suffix containers with Container (if using the pattern) | `ProductListContainer` |
| Be specific, not generic | `UserAvatarUploader` not `Uploader` |

### File structure

```
src/
  components/
    shared/           - Reusable across features
      Button/
      Modal/
      Table/
      FormInput/
    features/
      products/       - Feature-specific components
        ProductCard/
        ProductGrid/
        ProductFilters/
      checkout/
        CheckoutForm/
        OrderSummary/
    layouts/
      MainLayout/
      SidebarLayout/
    pages/
      ProductListPage/
      ProductDetailPage/
```

---

## Component checklist

Before considering a component done:

| # | Check |
|---|---|
| 1 | Component has a single, clear responsibility |
| 2 | Props interface is minimal and typed |
| 3 | Component handles its error state (not only the happy path) |
| 4 | Component handles empty/loading states |
| 5 | Component is keyboard accessible |
| 6 | Component does not fetch data it does not directly need |
| 7 | Component can be tested by rendering it with props (no complex setup) |
| 8 | Component follows project naming conventions |
| 9 | Reusable components have no feature-specific logic baked in |
| 10 | Event handlers are named with the `on` prefix and describe the action |

---

## Anti-patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Prop drilling through 4+ levels | Tight coupling, painful refactoring | Use composition, context, or state management |
| God component (500+ lines) | Untestable, hard to understand | Decompose into focused sub-components |
| Unnecessary abstraction | Wrapper components that add nothing | Inline simple logic, extract only when reuse is proven |
| Premature optimization | Memoizing everything "just in case" | Measure first, optimize only proven bottlenecks |
| Component knows about its parent | Child adjusts behavior based on parent context | Pass behavior via props, keep components independent |
| Mixed concerns | Data fetching, business logic, and rendering in one component | Split into container and presentational |
