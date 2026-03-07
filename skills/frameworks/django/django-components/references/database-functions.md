# Django Database Functions

## Overview

Django provides a rich set of database functions for use in annotations, aggregations, filters, and updates. These functions execute at the database level for optimal performance. All functions are expressions that can be combined with other expressions, F() objects, and values.

## Core Concepts

### Using Database Functions

All functions can be used in `annotate()`, `aggregate()`, `filter()`, and `update()`:

```python
from django.db.models import F
from django.db.models.functions import Lower, Length

# In annotations
Author.objects.annotate(name_lower=Lower("name"))

# In filters
Author.objects.filter(name_length=Length("name")).filter(name_length__gt=10)

# In ordering
Author.objects.order_by(Lower("name"))

# In updates
Author.objects.update(name=Lower("name"))
```

## Comparison and Conversion Functions

### Cast

Force type conversion at the database level:

```python
from django.db.models.functions import Cast
from django.db.models import FloatField

Author.objects.annotate(age_as_float=Cast("age", output_field=FloatField()))
```

### Coalesce

Return the first non-null value from a list of expressions:

```python
from django.db.models.functions import Coalesce
from django.db.models import Value

Author.objects.annotate(
    screen_name=Coalesce("alias", "goes_by", "name", output_field=CharField())
)

# With default fallback
Author.objects.annotate(
    display_name=Coalesce("nickname", Value("Anonymous"))
)
```

### Greatest and Least

Return the greatest or least value from multiple expressions:

```python
from django.db.models.functions import Greatest, Least

Comment.objects.annotate(last_updated=Greatest("modified", "blog__modified"))
Product.objects.annotate(min_price=Least("price", "sale_price"))
```

### NullIf

Return None if two expressions are equal:

```python
from django.db.models.functions import NullIf

Model.objects.annotate(result=NullIf("field1", "field2"))
```

### Collate

Query with a specific database collation:

```python
from django.db.models.functions import Collate
from django.db.models import Value

Author.objects.filter(name=Collate(Value("john"), "nocase"))
```

## Date and Time Functions

### Now

Current database server time:

```python
from django.db.models.functions import Now

Article.objects.filter(published__lte=Now())
Article.objects.annotate(time_since=Now() - F("published"))
```

### Extract

Extract date/time components from a datetime field:

```python
from django.db.models.functions import Extract, ExtractYear, ExtractMonth

# Generic extract
Experiment.objects.annotate(start_year=Extract("start_datetime", "year"))

# Specialized subclasses
Experiment.objects.annotate(
    year=ExtractYear("start_datetime"),
    month=ExtractMonth("start_datetime"),
)
```

Available Extract subclasses:

| Function | Extracts |
|---|---|
| `ExtractYear` | Year |
| `ExtractIsoYear` | ISO 8601 year |
| `ExtractQuarter` | Quarter (1-4) |
| `ExtractMonth` | Month (1-12) |
| `ExtractWeek` | ISO week number |
| `ExtractWeekDay` | Day of week (1=Sunday, 7=Saturday) |
| `ExtractIsoWeekDay` | ISO day of week (1=Monday, 7=Sunday) |
| `ExtractDay` | Day of month |
| `ExtractHour` | Hour (0-23) |
| `ExtractMinute` | Minute (0-59) |
| `ExtractSecond` | Second (0-59) |

### Trunc

Truncate a datetime to a specified precision:

```python
from django.db.models.functions import Trunc, TruncMonth, TruncDay
from django.db.models import Count, DateTimeField

# Group by month
Experiment.objects.annotate(
    month=TruncMonth("start_datetime")
).values("month").annotate(count=Count("id"))

# Generic trunc
Experiment.objects.annotate(
    start_day=Trunc("start_datetime", "day", output_field=DateTimeField())
)
```

Available Trunc subclasses:

| Function | Truncates to |
|---|---|
| `TruncYear` | Year |
| `TruncQuarter` | Quarter |
| `TruncMonth` | Month |
| `TruncWeek` | Week (Monday) |
| `TruncDay` | Day |
| `TruncHour` | Hour |
| `TruncMinute` | Minute |
| `TruncSecond` | Second |
| `TruncDate` | Date part of datetime |
| `TruncTime` | Time part of datetime |

## Text Functions

### Case Conversion

```python
from django.db.models.functions import Upper, Lower

Author.objects.annotate(name_upper=Upper("name"))
Author.objects.annotate(name_lower=Lower("name"))
```

### Concat

Concatenate multiple fields or values:

```python
from django.db.models.functions import Concat
from django.db.models import Value, CharField

Author.objects.annotate(
    full_name=Concat("first_name", Value(" "), "last_name", output_field=CharField())
)
```

### Substring Operations

```python
from django.db.models.functions import Left, Right, Substr, Length

Author.objects.annotate(
    initials=Left("name", 1),
    last_char=Right("name", 1),
    first_five=Substr("name", 1, 5),  # 1-based index
    name_length=Length("name"),
)
```

### Trim, Pad, and Replace

```python
from django.db.models.functions import Trim, LTrim, RTrim, LPad, RPad, Replace

Author.objects.annotate(
    trimmed=Trim("name"),
    left_trimmed=LTrim("name"),
    padded=LPad("name", 20, Value("_")),
    fixed=Replace("bio", Value("old"), Value("new")),
)
```

### Other Text Functions

```python
from django.db.models.functions import (
    Chr, Ord, Repeat, Reverse, StrIndex,
    MD5, SHA1, SHA256,
)

Author.objects.annotate(
    reversed_name=Reverse("name"),
    repeated=Repeat("name", 3),
    position=StrIndex("bio", Value("keyword")),  # 1-indexed
    name_hash=MD5("name"),
)
```

## Math Functions

### Basic Math

```python
from django.db.models.functions import Abs, Ceil, Floor, Round, Sign, Sqrt, Power, Mod

Vector.objects.annotate(
    x_abs=Abs("x"),
    ceiling=Ceil("value"),
    floored=Floor("value"),
    rounded=Round("value", precision=2),
    sign=Sign("value"),
    root=Sqrt("value"),
    squared=Power("value", Value(2)),
    remainder=Mod("value", Value(3)),
)
```

### Trigonometric Functions

```python
from django.db.models.functions import (
    Sin, Cos, Tan, Cot,
    ASin, ACos, ATan, ATan2,
    Degrees, Radians,
    Pi,
)

Point.objects.annotate(
    sin_angle=Sin("angle"),
    cos_angle=Cos("angle"),
    angle_degrees=Degrees("angle_radians"),
    angle_radians=Radians("angle_degrees"),
)
```

### Logarithmic Functions

```python
from django.db.models.functions import Exp, Ln, Log

Data.objects.annotate(
    natural_log=Ln("value"),
    log_base_10=Log(Value(10), "value"),
    exponential=Exp("value"),
)
```

### Random

```python
from django.db.models.functions import Random

# Random ordering
Entry.objects.order_by(Random())
```

## JSON Functions

### JSONObject

Create a JSON object from key-value pairs:

```python
from django.db.models.functions import JSONObject, Lower
from django.db.models import F

Author.objects.annotate(
    json_data=JSONObject(
        name=Lower("name"),
        alias="alias",
        age=F("age") * 2,
    )
)
# Result: {'name': 'margaret smith', 'alias': 'msmith', 'age': 50}
```

### JSONArray

Create a JSON array from expressions:

```python
from django.db.models.functions import JSONArray

Author.objects.annotate(
    json_arr=JSONArray(Lower("name"), "alias", F("age"))
)
# Result: ['margaret smith', 'msmith', 25]
```

## Conditional Expressions

### Case / When

SQL CASE...WHEN expressions for conditional logic:

```python
from django.db.models import Case, When, Value, CharField

Client.objects.annotate(
    discount=Case(
        When(account_type="gold", then=Value("5%")),
        When(account_type="platinum", then=Value("10%")),
        default=Value("0%"),
        output_field=CharField(),
    ),
)
```

### With Field Lookups

```python
from datetime import timedelta, date

a_year_ago = date.today() - timedelta(days=365)

Client.objects.annotate(
    loyalty_tier=Case(
        When(registered_on__lte=a_year_ago, then=Value("veteran")),
        default=Value("new"),
    )
)
```

### With Q Objects

```python
from django.db.models import Q

Client.objects.annotate(
    label=Case(
        When(Q(name__startswith="John") | Q(name__startswith="Jane"), then=Value("J-name")),
        default=Value("other"),
    )
)
```

### Conditional Update

```python
Client.objects.update(
    account_type=Case(
        When(registered_on__lte=a_year_ago, then=Value("platinum")),
        When(registered_on__lte=a_month_ago, then=Value("gold")),
        default=Value("regular"),
    ),
)
```

### Conditional Aggregation

```python
from django.db.models import Count, Q

Client.objects.aggregate(
    regular=Count("pk", filter=Q(account_type="regular")),
    gold=Count("pk", filter=Q(account_type="gold")),
    platinum=Count("pk", filter=Q(account_type="platinum")),
)
# {'regular': 2, 'gold': 1, 'platinum': 3}
```

## Full-Text Search (PostgreSQL)

### Basic Search

```python
# Simple search lookup
Entry.objects.filter(body_text__search="cheese")
```

### SearchVector

Combine multiple fields for full-text search:

```python
from django.contrib.postgres.search import SearchVector

Entry.objects.annotate(
    search=SearchVector("title", "body"),
).filter(search="cheese")
```

### SearchQuery and SearchRank

```python
from django.contrib.postgres.search import SearchVector, SearchQuery, SearchRank

vector = SearchVector("title", weight="A") + SearchVector("body", weight="B")
query = SearchQuery("cheese")

Entry.objects.annotate(
    rank=SearchRank(vector, query)
).filter(rank__gte=0.3).order_by("-rank")
```

### Trigram Similarity

Fuzzy matching using trigram comparison:

```python
Author.objects.filter(name__trigram_similar="Helen")
Author.objects.filter(name__unaccent__lower__trigram_similar="Helene")
```

## Window Functions

```python
from django.db.models import Window, F
from django.db.models.functions import Rank, DenseRank, RowNumber, Lag, Lead, Ntile

Employee.objects.annotate(
    rank=Window(expression=Rank(), partition_by=[F("department")], order_by=F("salary").desc()),
    dense_rank=Window(expression=DenseRank(), order_by=F("salary").desc()),
    row_num=Window(expression=RowNumber(), order_by="hire_date"),
    prev_salary=Window(expression=Lag("salary", offset=1), order_by="hire_date"),
    next_salary=Window(expression=Lead("salary", offset=1), order_by="hire_date"),
    quartile=Window(expression=Ntile(num_buckets=4), order_by=F("salary").desc()),
)
```

Additional window functions: `FirstValue`, `LastValue`, `NthValue`, `CumeDist`, `PercentRank`.

## Best Practices

- Use database functions instead of Python-level processing for better performance
- Combine functions with `annotate()` for per-row computed values
- Use `Coalesce` to handle NULL values gracefully
- Use `Case`/`When` for conditional logic instead of multiple queries
- Use `Exists` subqueries instead of `Count` for boolean checks (more efficient)
- Use `TruncMonth`/`TruncDay` with `values().annotate()` for time-series grouping
- Use conditional aggregation (`filter=Q(...)`) instead of multiple queries
- PostgreSQL full-text search is suitable for moderate search needs; use Elasticsearch/Solr for large-scale search
- Use `distinct=True` in `Count` when combining multiple aggregations to avoid inflated counts
