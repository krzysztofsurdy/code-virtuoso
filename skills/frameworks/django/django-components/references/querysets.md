# Django QuerySets

## Overview

QuerySets represent a collection of objects from the database. They are lazy (no database hit until evaluated), chainable, and cacheable. Django's QuerySet API provides methods for filtering, ordering, aggregating, and manipulating data without writing raw SQL.

## Core Concepts

### QuerySet Evaluation

QuerySets are lazy -- no database query executes until the QuerySet is evaluated through:

- Iteration: `for obj in queryset`
- Slicing with step: `queryset[::2]`
- `len()`, `list()`, `bool()`, `repr()`
- Pickling/caching

Use `exists()` instead of `bool()` and `count()` instead of `len()` for efficiency.

### Creating and Saving Objects

```python
# Method 1: Instantiate and save
entry = Entry(headline="Hello", pub_date=date.today())
entry.save()

# Method 2: create() -- single step
entry = Entry.objects.create(headline="Hello", pub_date=date.today())

# ForeignKey assignment
entry.blog = blog_instance
entry.save()

# ManyToMany -- use add()
entry.authors.add(author1, author2)
entry.authors.set([author1, author2])
```

## Methods That Return New QuerySets

### filter() and exclude()

```python
Entry.objects.filter(pub_date__year=2024)
Entry.objects.filter(pub_date__year=2024, headline__startswith="What")
Entry.objects.exclude(pub_date__gte=date.today())

# Chaining
Entry.objects.filter(headline__startswith="What").exclude(pub_date__gte=date.today())
```

### Field Lookups

Lookups use double-underscore syntax: `field__lookup=value`.

| Lookup | Description | Example |
|---|---|---|
| `exact` | Exact match (default) | `name__exact="John"` |
| `iexact` | Case-insensitive exact | `name__iexact="john"` |
| `contains` | Case-sensitive substring | `headline__contains="Lennon"` |
| `icontains` | Case-insensitive substring | `headline__icontains="lennon"` |
| `startswith` | Starts with | `name__startswith="J"` |
| `istartswith` | Case-insensitive starts with | `name__istartswith="j"` |
| `endswith` | Ends with | `name__endswith="son"` |
| `iendswith` | Case-insensitive ends with | `name__iendswith="SON"` |
| `gt` / `gte` | Greater than / greater or equal | `age__gt=18` |
| `lt` / `lte` | Less than / less or equal | `price__lt=100` |
| `in` | In a list | `id__in=[1, 3, 4]` |
| `range` | Between two values | `date__range=[start, end]` |
| `isnull` | Is NULL | `email__isnull=True` |
| `regex` | Regular expression | `name__regex=r'^[A-Z]'` |
| `iregex` | Case-insensitive regex | `name__iregex=r'^[a-z]'` |
| `year` / `month` / `day` | Date component | `pub_date__year=2024` |
| `hour` / `minute` / `second` | Time component | `created__hour=14` |
| `week_day` | Day of week (1=Sunday) | `date__week_day=2` |
| `date` | Date part of datetime | `created__date=date.today()` |

### Spanning Relationships

```python
# Forward: entry -> blog
Entry.objects.filter(blog__name="Beatles Blog")

# Reverse: blog -> entry
Blog.objects.filter(entry__headline__contains="Lennon")

# Multi-level
Blog.objects.filter(entry__authors__name="John")
```

### annotate()

Adds computed values to each object in the QuerySet.

```python
from django.db.models import Count, Avg

Blog.objects.annotate(num_entries=Count("entry"))
Blog.objects.annotate(avg_rating=Avg("entry__rating"))

# Use in subsequent filters
Blog.objects.annotate(num_entries=Count("entry")).filter(num_entries__gt=5)
```

### alias()

Like `annotate()` but does not select the value -- for intermediate calculations.

```python
Blog.objects.alias(entries=Count("entry")).filter(entries__gt=5)
```

### order_by()

```python
Entry.objects.order_by("headline")             # Ascending
Entry.objects.order_by("-pub_date")             # Descending
Entry.objects.order_by("blog__name", "-pub_date")  # Multiple fields
Entry.objects.order_by("?")                     # Random (expensive)
Entry.objects.order_by()                        # Clear ordering
```

### values() and values_list()

```python
# Dictionaries
Blog.objects.values("id", "name")
# <QuerySet [{'id': 1, 'name': 'Beatles Blog'}]>

# With expressions
from django.db.models.functions import Lower
Blog.objects.values(lower_name=Lower("name"))

# Tuples
Entry.objects.values_list("id", "headline")
# <QuerySet [(1, 'First entry'), ...]>

# Flat list (single field only)
Entry.objects.values_list("id", flat=True)
# <QuerySet [1, 2, 3]>

# Named tuples
Entry.objects.values_list("id", "headline", named=True)
# <QuerySet [Row(id=1, headline='First entry')]>
```

### select_related() and prefetch_related()

```python
# select_related: SQL JOIN for ForeignKey/OneToOne (single query)
Entry.objects.select_related("blog").get(id=5)
Book.objects.select_related("author__hometown").all()

# prefetch_related: separate queries joined in Python (for M2M, reverse FK)
Pizza.objects.prefetch_related("toppings")
Restaurant.objects.prefetch_related("pizzas__toppings")

# Custom prefetch with Prefetch object
from django.db.models import Prefetch
Restaurant.objects.prefetch_related(
    Prefetch("pizzas", queryset=Pizza.objects.filter(vegetarian=True), to_attr="veggie_pizzas")
)
```

### distinct()

```python
Author.objects.distinct()

# PostgreSQL: DISTINCT ON specific fields
Entry.objects.order_by("pub_date").distinct("pub_date")
```

### defer() and only()

```python
Entry.objects.defer("body")         # Load everything except body
Entry.objects.only("headline")      # Load only headline (+ pk)
```

### union(), intersection(), difference()

```python
qs1.union(qs2, qs3)
qs1.union(qs2, all=True)           # Include duplicates
qs1.intersection(qs2)
qs1.difference(qs2)
```

### select_for_update()

```python
from django.db import transaction

with transaction.atomic():
    entries = Entry.objects.select_for_update().filter(author=user)
    for entry in entries:
        entry.status = "locked"
        entry.save()

# Non-blocking
Entry.objects.select_for_update(nowait=True)
Entry.objects.select_for_update(skip_locked=True)
```

### Slicing (LIMIT/OFFSET)

```python
Entry.objects.all()[:5]         # LIMIT 5
Entry.objects.all()[5:10]       # OFFSET 5 LIMIT 5
Entry.objects.order_by("headline")[0]  # Single object
```

Negative indexing is not supported.

## Methods That Do NOT Return QuerySets

### get()

```python
entry = Entry.objects.get(pk=1)
# Raises Entry.DoesNotExist or Entry.MultipleObjectsReturned
```

### create(), get_or_create(), update_or_create()

```python
person = Person.objects.create(first_name="Bruce", last_name="Wayne")

obj, created = Person.objects.get_or_create(
    first_name="John",
    defaults={"birthday": date(1940, 10, 9)},
)

obj, created = Person.objects.update_or_create(
    first_name="John",
    defaults={"age": 80},
)
```

### bulk_create() and bulk_update()

```python
Entry.objects.bulk_create([
    Entry(headline="Entry 1"),
    Entry(headline="Entry 2"),
], batch_size=1000)

entries = list(Entry.objects.all())
for e in entries:
    e.headline = e.headline.upper()
Entry.objects.bulk_update(entries, ["headline"], batch_size=1000)
```

### count() and exists()

```python
Entry.objects.count()                              # SELECT COUNT(*)
Entry.objects.filter(pub_date__year=2024).count()
Entry.objects.filter(pk=1).exists()                # Efficient boolean check
```

### aggregate()

Returns a dictionary of computed values across the entire QuerySet.

```python
from django.db.models import Avg, Max, Min, Sum, Count

Entry.objects.aggregate(
    avg_rating=Avg("rating"),
    max_rating=Max("rating"),
    total=Count("id"),
)
# {'avg_rating': 4.5, 'max_rating': 5, 'total': 100}
```

### first(), last(), earliest(), latest()

```python
Entry.objects.order_by("headline").first()   # First or None
Entry.objects.order_by("headline").last()    # Last or None
Entry.objects.earliest("pub_date")           # Earliest by field
Entry.objects.latest("pub_date")             # Latest by field
```

### in_bulk()

```python
entries = Entry.objects.in_bulk([1, 2, 3])
# {1: <Entry>, 2: <Entry>, 3: <Entry>}
```

### delete() and update()

```python
Entry.objects.filter(pub_date__year=2005).delete()
# (5, {'blog.Entry': 5})

Entry.objects.filter(pub_date__year=2007).update(headline="Updated")
# Returns count of updated rows

# update() with F expressions
Entry.objects.update(views=F("views") + 1)
```

## Q Objects (Complex Queries)

```python
from django.db.models import Q

# OR
Entry.objects.filter(Q(headline__startswith="What") | Q(headline__startswith="Who"))

# AND
Entry.objects.filter(Q(pub_date__year=2024) & Q(status="published"))

# NOT
Entry.objects.filter(~Q(status="draft"))

# XOR
Entry.objects.filter(Q(a=1) ^ Q(b=2))

# Combined with keyword args (Q objects must come first)
Entry.objects.filter(Q(pub_date=date(2024, 1, 1)) | Q(pub_date=date(2024, 6, 1)), headline="Hello")
```

## F Expressions

Reference field values in queries without pulling data into Python.

```python
from django.db.models import F

# Field comparison
Entry.objects.filter(comments__gt=F("pingbacks"))
Entry.objects.filter(comments__gt=F("pingbacks") * 2)

# Update without race conditions
reporter.stories_filed = F("stories_filed") + 1
reporter.save()

# Bulk update
Reporter.objects.update(stories_filed=F("stories_filed") + 1)

# Spanning relationships
Entry.objects.filter(authors__name=F("blog__name"))

# Date arithmetic
from datetime import timedelta
Entry.objects.filter(mod_date__gt=F("pub_date") + timedelta(days=3))

# Ordering with nulls control
Entry.objects.order_by(F("last_contacted").desc(nulls_last=True))
```

## Aggregation

### aggregate() vs annotate()

```python
from django.db.models import Avg, Count, Max, Min, Sum

# aggregate(): single summary across entire QuerySet
Book.objects.aggregate(avg_price=Avg("price"))
# {'avg_price': 34.35}

# annotate(): per-object summary
Book.objects.annotate(num_authors=Count("authors"))
book.num_authors  # 3
```

### Aggregation Functions

| Function | Description |
|---|---|
| `Avg` | Average value |
| `Count` | Number of items |
| `Max` | Maximum value |
| `Min` | Minimum value |
| `Sum` | Total sum |
| `StdDev` | Standard deviation |
| `Variance` | Variance |

### Combining Multiple Aggregations

Use `distinct=True` to avoid incorrect counts from JOINs:

```python
Book.objects.annotate(
    num_authors=Count("authors", distinct=True),
    num_stores=Count("store", distinct=True),
)
```

### Conditional Aggregation

```python
from django.db.models import Q

Client.objects.aggregate(
    regular=Count("pk", filter=Q(account_type="regular")),
    premium=Count("pk", filter=Q(account_type="premium")),
)
```

### Order of filter() and annotate() Matters

```python
# Filter THEN annotate: annotation applies to filtered set
Publisher.objects.filter(book__rating__gt=3).annotate(num_books=Count("book"))

# Annotate THEN filter: annotation applies to full set, then filtered
Publisher.objects.annotate(num_books=Count("book")).filter(num_books__gt=5)
```

### Default Values for Empty Sets

```python
Book.objects.filter(name="nonexistent").aggregate(Sum("price", default=0))
# {"price__sum": Decimal("0")} instead of {"price__sum": None}
```

## Subquery and Exists

```python
from django.db.models import OuterRef, Subquery, Exists

# Subquery: use a queryset as a subquery
newest_comment = Comment.objects.filter(post=OuterRef("pk")).order_by("-created_at")
Post.objects.annotate(newest_email=Subquery(newest_comment.values("email")[:1]))

# Exists: efficient boolean check
recent_comments = Comment.objects.filter(
    post=OuterRef("pk"),
    created_at__gte=one_day_ago,
)
Post.objects.filter(Exists(recent_comments))
Post.objects.filter(~Exists(recent_comments))  # NOT EXISTS
```

## Window Functions

```python
from django.db.models import Avg, F, Window
from django.db.models.functions import Rank

Movie.objects.annotate(
    avg_rating=Window(
        expression=Avg("rating"),
        partition_by=[F("genre")],
        order_by="released__year",
    ),
    rank=Window(
        expression=Rank(),
        partition_by=[F("genre")],
        order_by=F("rating").desc(),
    ),
)
```

## QuerySet Caching

```python
queryset = Entry.objects.all()
# First iteration: hits database and caches results
for entry in queryset:
    print(entry.headline)

# Second iteration: uses cached results
for entry in queryset:
    print(entry.pub_date)

# Indexing without full evaluation does NOT cache
queryset[5]  # Hits database each time
```

## Async QuerySet API

```python
async for entry in Entry.objects.filter(pub_date__year=2024):
    print(entry.headline)

entry = await Entry.objects.aget(pk=1)
count = await Entry.objects.acount()
exists = await Entry.objects.filter(pk=1).aexists()
```

## Best Practices

- Use `select_related()` for ForeignKey/OneToOne to avoid N+1 queries
- Use `prefetch_related()` for ManyToMany and reverse ForeignKey relations
- Use `exists()` instead of `bool(queryset)` or `len(queryset) > 0`
- Use `count()` instead of `len(queryset)` when you only need the count
- Use `only()` or `defer()` to load only needed fields for large models
- Use `values_list(flat=True)` when you need a flat list of single field values
- Use `iterator()` for large querysets to avoid caching all results in memory
- Use `bulk_create()` and `bulk_update()` for batch operations
- Use `F()` expressions to avoid race conditions in updates
- Remember that `update()` and `delete()` bypass `save()` and signals
