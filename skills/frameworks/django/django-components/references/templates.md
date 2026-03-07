# Django Templates

## Overview

Django's template system separates presentation from business logic, providing a powerful yet intentionally restricted language for generating HTML and other text-based formats. It supports multiple backends (Django Template Language and Jinja2), template inheritance, automatic HTML escaping, and extensibility through custom tags and filters.

## Core Concepts

### Template Configuration

Templates are configured via the `TEMPLATES` setting in `settings.py`:

```python
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
            "autoescape": True,
            "string_if_invalid": "",
            "debug": True,
            "libraries": {
                "myapp_tags": "path.to.myapp.tags",
            },
            "builtins": ["myapp.builtins"],
        },
    },
]
```

| Key | Purpose |
|-----|---------|
| `BACKEND` | Template engine class (`DjangoTemplates` or `Jinja2`) |
| `DIRS` | Directories to search for templates |
| `APP_DIRS` | Search `templates/` subdirectory in installed apps |
| `OPTIONS` | Backend-specific settings (context processors, loaders, etc.) |

### Variables

Variables output context values using double curly braces. Dot notation triggers dictionary, attribute, and index lookups in order:

```django
{{ user.name }}
{{ my_dict.key }}
{{ my_list.0 }}
{{ object.get_absolute_url }}
```

### Tags

Tags provide control flow and logic, enclosed in `{% %}`:

```django
{% if user.is_authenticated %}
    Hello, {{ user.username }}.
{% endif %}

{% for item in item_list %}
    <li>{{ item.name }}</li>
{% empty %}
    <li>No items found.</li>
{% endfor %}
```

### Filters

Filters transform variable values using the pipe character:

```django
{{ name|lower }}
{{ text|truncatewords:30 }}
{{ value|default:"nothing" }}
{{ my_date|date:"Y-m-d" }}
{{ list|join:", " }}
```

### Comments

```django
{# Single-line comment #}

{% comment "Optional note" %}
    Multi-line comment block
{% endcomment %}
```

## Built-in Template Tags

### Control Flow

```django
{% if athlete_list and coach_list %}
    Both available.
{% elif athlete_list %}
    Only athletes.
{% else %}
    No one.
{% endif %}

{% for athlete in athlete_list %}
    {{ forloop.counter }}. {{ athlete.name }}
{% empty %}
    No athletes.
{% endfor %}

{% with total=business.employees.count %}
    {{ total }} employee{{ total|pluralize }}
{% endwith %}
```

The `for` tag provides loop variables: `forloop.counter`, `forloop.counter0`, `forloop.revcounter`, `forloop.first`, `forloop.last`, `forloop.parentloop`.

The `if` tag supports operators: `and`, `or`, `not`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `in`, `not in`, `is`, `is not`.

### Template Inheritance

```django
{# base.html #}
<!DOCTYPE html>
<html>
<head><title>{% block title %}My Site{% endblock %}</title></head>
<body>
    {% block sidebar %}
        <ul><li><a href="/">Home</a></li></ul>
    {% endblock %}
    {% block content %}{% endblock %}
</body>
</html>

{# child.html #}
{% extends "base.html" %}

{% block title %}My Blog{% endblock %}

{% block content %}
    {% for entry in blog_entries %}
        <h2>{{ entry.title }}</h2>
        <p>{{ entry.body }}</p>
    {% endfor %}
{% endblock %}
```

Key rules: `{% extends %}` must be the first tag. Use `{{ block.super }}` to include parent content. Three-level inheritance is recommended: base -> section -> page.

### Template Partials (Django 6.0)

```django
{% partialdef user-card %}
    <div class="card">
        <h3>{{ user.name }}</h3>
        <p>{{ user.bio }}</p>
    </div>
{% endpartialdef %}

{% partial user-card %}
```

Partials can be accessed from views: `render(request, "template.html#user-card", context)`.

### URL Reversing

```django
{% url 'some-url-name' arg1 arg2 %}
{% url 'some-url-name' arg1=value1 arg2=value2 %}
{% url 'some-url-name' as the_url %}
```

### Other Tags

```django
{% csrf_token %}
{% include "snippet.html" with greeting="Hello" only %}
{% load humanize %}
{% cycle 'odd' 'even' as rowcolors %}
{% now "Y-m-d H:i" %}
{% spaceless %}<p><a href="/">Link</a></p>{% endspaceless %}
{% verbatim %}{{ not_rendered }}{% endverbatim %}
{% autoescape off %}{{ raw_html }}{% endautoescape %}

{% regroup cities by country as country_list %}
{% for country in country_list %}
    <h2>{{ country.grouper }}</h2>
    {% for city in country.list %}
        <li>{{ city.name }}</li>
    {% endfor %}
{% endfor %}

{% querystring color="red" size="S" %}
```

## Built-in Filters

### String Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `lower` | `{{ name\|lower }}` | Lowercase |
| `upper` | `{{ name\|upper }}` | Uppercase |
| `title` | `{{ name\|title }}` | Title Case |
| `capfirst` | `{{ name\|capfirst }}` | Capitalize first char |
| `slugify` | `{{ title\|slugify }}` | URL slug |
| `truncatechars` | `{{ text\|truncatechars:50 }}` | Truncate to N chars |
| `truncatewords` | `{{ text\|truncatewords:30 }}` | Truncate to N words |
| `cut` | `{{ value\|cut:" " }}` | Remove all occurrences |
| `striptags` | `{{ html\|striptags }}` | Remove HTML tags |
| `linebreaks` | `{{ text\|linebreaks }}` | Newlines to `<p>` and `<br>` |
| `linebreaksbr` | `{{ text\|linebreaksbr }}` | Newlines to `<br>` |
| `wordwrap` | `{{ text\|wordwrap:5 }}` | Wrap at N chars |
| `wordcount` | `{{ text\|wordcount }}` | Count words |
| `center` | `{{ val\|center:"15" }}` | Center in field |
| `ljust` | `{{ val\|ljust:"10" }}` | Left-justify |
| `rjust` | `{{ val\|rjust:"10" }}` | Right-justify |
| `urlize` | `{{ text\|urlize }}` | Convert URLs to links |

### Date/Time Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `date` | `{{ value\|date:"D d M Y" }}` | Format date |
| `time` | `{{ value\|time:"H:i" }}` | Format time |
| `timesince` | `{{ date\|timesince }}` | Time elapsed |
| `timeuntil` | `{{ date\|timeuntil }}` | Time remaining |

### List/Data Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `join` | `{{ list\|join:", " }}` | Join list items |
| `first` | `{{ list\|first }}` | First item |
| `last` | `{{ list\|last }}` | Last item |
| `length` | `{{ list\|length }}` | Length |
| `random` | `{{ list\|random }}` | Random item |
| `slice` | `{{ list\|slice:":2" }}` | Slice list |
| `dictsort` | `{{ list\|dictsort:"name" }}` | Sort dicts by key |
| `unordered_list` | `{{ list\|unordered_list }}` | Nested HTML list |

### Default/Safety Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `default` | `{{ val\|default:"n/a" }}` | Fallback for falsy values |
| `default_if_none` | `{{ val\|default_if_none:"n/a" }}` | Fallback only for None |
| `safe` | `{{ html\|safe }}` | Mark as safe (no escaping) |
| `escape` | `{{ val\|escape }}` | HTML escape |
| `escapejs` | `{{ val\|escapejs }}` | JavaScript escape |
| `force_escape` | `{{ val\|force_escape }}` | Force HTML escape |
| `json_script` | `{{ val\|json_script:"id" }}` | JSON in script tag |
| `filesizeformat` | `{{ bytes\|filesizeformat }}` | Human-readable file size |
| `floatformat` | `{{ val\|floatformat:2 }}` | Format float |
| `pluralize` | `{{ count\|pluralize:"y,ies" }}` | Plural suffix |
| `yesno` | `{{ val\|yesno:"yes,no,maybe" }}` | Map boolean to text |
| `add` | `{{ val\|add:"2" }}` | Add value |

## Automatic HTML Escaping

Django auto-escapes `<`, `>`, `'`, `"`, and `&` by default. Control escaping per-variable or per-block:

```django
{{ data }}                    {# Auto-escaped #}
{{ data|safe }}               {# Not escaped #}

{% autoescape off %}
    {{ data }}                {# Not escaped #}
    {% autoescape on %}
        {{ data }}            {# Escaped again #}
    {% endautoescape %}
{% endautoescape %}
```

## Template API

### Loading and Rendering

```python
from django.template.loader import get_template, render_to_string

# Load template
template = get_template("myapp/index.html")
html = template.render({"name": "World"}, request)

# Load partial (Django 6.0)
partial = get_template("myapp/index.html#card")

# One-step render
html = render_to_string("myapp/index.html", {"name": "World"}, request)
```

### Engine and Context

```python
from django.template import Template, Context, RequestContext

# Direct template creation
template = Template("Hello {{ name }}!")
context = Context({"name": "Adrian"})
result = template.render(context)

# RequestContext runs context processors automatically
context = RequestContext(request, {"extra": "data"})
```

### Template Loaders

| Loader | Purpose |
|--------|---------|
| `filesystem.Loader` | Loads from `DIRS` directories |
| `app_directories.Loader` | Loads from app `templates/` dirs |
| `cached.Loader` | Wraps other loaders with caching |
| `locmem.Loader` | Loads from Python dictionary (testing) |

### Built-in Context Processors

| Processor | Variables Provided |
|-----------|-------------------|
| `auth` | `user`, `perms` |
| `debug` | `debug`, `sql_queries` |
| `i18n` | `LANGUAGES`, `LANGUAGE_CODE`, `LANGUAGE_BIDI` |
| `media` | `MEDIA_URL` |
| `static` | `STATIC_URL` |
| `csrf` | CSRF token |
| `request` | `request` |
| `messages` | `messages`, `DEFAULT_MESSAGE_LEVELS` |

## Custom Template Tags and Filters

### Code Layout

```
myapp/
    templatetags/
        __init__.py
        myapp_extras.py
```

### Custom Filters

```python
from django import template
from django.template.defaultfilters import stringfilter

register = template.Library()

@register.filter
@stringfilter
def lower(value):
    return value.lower()

@register.filter(is_safe=True)
def add_prefix(value, prefix):
    return f"{prefix}{value}"

@register.filter(needs_autoescape=True)
def bold_first(text, autoescape=True):
    from django.utils.html import conditional_escape
    from django.utils.safestring import mark_safe
    esc = conditional_escape if autoescape else lambda x: x
    first, rest = text[0], text[1:]
    return mark_safe(f"<strong>{esc(first)}</strong>{esc(rest)}")
```

### Simple Tags

```python
@register.simple_tag
def current_time(format_string):
    import datetime
    return datetime.datetime.now().strftime(format_string)

@register.simple_tag(takes_context=True)
def greeting(context):
    return f"Hello, {context['user'].name}"
```

Usage: `{% current_time "%Y-%m-%d" %}` or `{% current_time "%Y" as year %}`.

### Inclusion Tags

```python
@register.inclusion_tag("results.html")
def show_results(poll):
    return {"choices": poll.choice_set.all()}

@register.inclusion_tag("link.html", takes_context=True)
def jump_link(context):
    return {"link": context["home_link"], "title": context["home_title"]}
```

### Block Tags (Django 5.2+)

```python
@register.simple_block_tag
def card(content):
    from django.utils.safestring import mark_safe
    return mark_safe(f'<div class="card">{content}</div>')
```

### Advanced Tags with Node Classes

```python
class CurrentTimeNode(template.Node):
    def __init__(self, format_string):
        self.format_string = format_string

    def render(self, context):
        import datetime
        return datetime.datetime.now().strftime(self.format_string)

@register.tag("current_time")
def do_current_time(parser, token):
    tag_name, format_string = token.split_contents()
    return CurrentTimeNode(format_string[1:-1])
```

Thread-safety: store render-specific state in `context.render_context`, not on the node.

## Common Patterns

### Template Organization

```
templates/
    base.html                   # Site-wide base
    base_section.html           # Section base (extends base.html)
    myapp/
        list.html               # App templates (extend section base)
        detail.html
```

### Looping with Metadata

```django
{% for item in items %}
    {% if forloop.first %}<ul>{% endif %}
    <li class="{% cycle 'odd' 'even' %}">
        {{ forloop.counter }}. {{ item.name }}
    </li>
    {% if forloop.last %}</ul>{% endif %}
{% endfor %}
```

### Conditional Includes

```django
{% include template_name|default:"default.html" %}
{% include "sidebar.html" with user=request.user only %}
```

### Static Files

```django
{% load static %}
<link rel="stylesheet" href="{% static 'css/style.css' %}">
<img src="{% static 'images/logo.png' %}" alt="Logo">
{% static "images/logo.png" as logo_url %}
```

## Best Practices

- Use three-level template inheritance (base -> section -> page)
- Always include `{% csrf_token %}` in POST forms
- Prefer `{{ variable|escape }}` and auto-escaping over `|safe` for security
- Use `{% load %}` in every template that needs custom tags (not inherited)
- Organize templates in app-specific subdirectories to avoid naming collisions
- Use `{% verbatim %}` when embedding client-side template syntax (Vue, Angular)
- Use `select_template()` for graceful template fallbacks
- Keep logic out of templates; move complex operations to views or template tags
