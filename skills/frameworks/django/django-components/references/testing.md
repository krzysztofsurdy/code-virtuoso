# Django Testing

## Overview

Django provides a comprehensive testing framework built on Python's `unittest` module, with additional tools for testing web applications including a test client, assertion methods for HTTP responses, and database transaction management for test isolation.

## Test Case Classes

### Class Hierarchy

```
unittest.TestCase
  SimpleTestCase
    TransactionTestCase
      TestCase
    LiveServerTestCase
```

### SimpleTestCase

For tests that do not require database access:

```python
from django.test import SimpleTestCase

class MyTests(SimpleTestCase):
    # No database access allowed by default
    # Enable with: databases = '__all__'

    def test_homepage_status(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
```

### TestCase

The most common test class. Wraps each test in a transaction for database isolation:

```python
from django.test import TestCase
from myapp.models import Animal

class AnimalTestCase(TestCase):
    @classmethod
    def setUpTestData(cls):
        # Set up data once for all tests in the class (faster)
        cls.lion = Animal.objects.create(name="lion", sound="roar")

    def setUp(self):
        # Runs before each test method
        Animal.objects.create(name="cat", sound="meow")

    def test_animals_can_speak(self):
        lion = Animal.objects.get(name="lion")
        self.assertEqual(lion.speak(), 'The lion says "roar"')
```

### TransactionTestCase

For tests that need to test transaction behavior directly:

```python
from django.test import TransactionTestCase

class MyTransactionTests(TransactionTestCase):
    fixtures = ["mammals.json", "birds"]
    reset_sequences = True  # Reset auto-increment sequences
    available_apps = ["myapp"]  # Limit initialized apps

    def test_transaction_commit(self):
        # Can test commit/rollback behavior
        pass
```

### LiveServerTestCase

Runs a live development server for browser-based testing:

```python
from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from selenium import webdriver

class MySeleniumTests(StaticLiveServerTestCase):
    fixtures = ["user-data.json"]

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.selenium = webdriver.Firefox()

    @classmethod
    def tearDownClass(cls):
        cls.selenium.quit()
        super().tearDownClass()

    def test_login(self):
        self.selenium.get(f"{self.live_server_url}/login/")
        username_input = self.selenium.find_element("name", "username")
        username_input.send_keys("myuser")
```

## Test Client

### Basic Usage

```python
from django.test import Client

c = Client()
response = c.get("/customers/details/", query_params={"name": "fred"})
response = c.post("/login/", {"username": "john", "password": "smith"})
```

### Client Constructor

```python
Client(
    enforce_csrf_checks=False,
    raise_request_exception=True,
    json_encoder=DjangoJSONEncoder,
    headers=None,
    query_params=None,
    **defaults
)
```

### HTTP Methods

```python
# GET
c.get("/path/", query_params={"key": "value"})
c.get("/path/", headers={"accept": "application/json"})

# POST (form data)
c.post("/login/", {"name": "fred", "passwd": "secret"})

# POST (JSON)
c.post("/api/", {"key": "value"}, content_type="application/json")

# File upload
with open("document.pdf", "rb") as fp:
    c.post("/upload/", {"name": "fred", "attachment": fp})

# PUT, PATCH, DELETE, HEAD, OPTIONS
c.put("/api/item/1/", data='{"key":"val"}', content_type="application/json")
c.patch("/api/item/1/", data='{"key":"val"}', content_type="application/json")
c.delete("/api/item/1/")

# Follow redirects
response = c.get("/redirect/", follow=True)
response.redirect_chain  # [('http://testserver/next/', 302)]
```

### Authentication

```python
# Simulate login (goes through auth backend)
c.login(username="fred", password="secret")

# Force login (bypasses authentication -- faster)
c.force_login(user, backend=None)

# Logout
c.logout()

# Async variants
await c.alogin(username="fred", password="secret")
await c.aforce_login(user)
await c.alogout()
```

### AsyncClient

```python
from django.test import AsyncClient

c = AsyncClient()
response = await c.get("/path/")
```

### Response Object

```python
response.status_code    # HTTP status code (int)
response.content        # Response body as bytes
response.json()         # Parse body as JSON
response.context        # Template context dict
response.templates      # List of Template instances used
response.resolver_match # ResolverMatch for the URL
response.headers        # Response headers
response.redirect_chain # List of (url, status_code) tuples when follow=True
```

## Assertions

### Content Assertions

```python
self.assertContains(response, "Hello", count=2, status_code=200, html=False)
self.assertNotContains(response, "Goodbye", status_code=200, html=False)
```

### Redirect Assertions

```python
self.assertRedirects(
    response, "/expected-url/",
    status_code=302,
    target_status_code=200,
    fetch_redirect_response=True
)
```

### Template Assertions

```python
self.assertTemplateUsed(response, "myapp/index.html")
self.assertTemplateNotUsed(response, "myapp/other.html")

# As context manager
with self.assertTemplateUsed("index.html"):
    render_to_string("index.html")
```

### Form Assertions

```python
self.assertFormError(form, "email", "Enter a valid email address.")
self.assertFormSetError(formset, 0, "name", "This field is required.")
self.assertFieldOutput(
    EmailField,
    {"a@a.com": "a@a.com"},
    {"aaa": ["Enter a valid email address."]}
)
```

### HTML/JSON/XML Assertions

```python
# Semantic HTML comparison (ignores whitespace, attribute order)
self.assertHTMLEqual('<p class="foo">Hello</p>', '<p class="foo"> Hello </p>')
self.assertHTMLNotEqual("<p>foo</p>", "<p>bar</p>")

# HTML containment
self.assertInHTML("<b>Hello</b>", "<p><b>Hello</b> world</p>")

# JSON comparison
self.assertJSONEqual(response.content, {"key": "value"})
self.assertJSONNotEqual('{"a": 1}', '{"a": 2}')

# XML comparison
self.assertXMLEqual(xml1, xml2)
```

### QuerySet Assertions

```python
self.assertQuerySetEqual(
    Person.objects.all(),
    ["<Person: John>", "<Person: Jane>"],
    transform=repr,
    ordered=False
)
```

### Query Count Assertions

```python
self.assertNumQueries(7, my_function, using="default")

# As context manager
with self.assertNumQueries(2):
    Person.objects.create(name="Aaron")
    Person.objects.create(name="Daniel")
```

### URL Assertions

```python
# Ignores query string parameter order
self.assertURLEqual("/path/?a=1&b=2", "/path/?b=2&a=1")
```

### Exception Assertions

```python
with self.assertRaisesMessage(ValueError, "invalid literal"):
    int("a")

with self.assertWarnsMessage(DeprecationWarning, "old method"):
    old_method()
```

## Overriding Settings

### Decorator

```python
from django.test import TestCase, override_settings

@override_settings(LOGIN_URL="/other/login/")
class LoginTestCase(TestCase):
    def test_login(self):
        response = self.client.get("/sekrit/")
        self.assertRedirects(response, "/other/login/?next=/sekrit/")
```

### Context Manager

```python
def test_login(self):
    with self.settings(LOGIN_URL="/other/login/"):
        response = self.client.get("/sekrit/")
        self.assertRedirects(response, "/other/login/?next=/sekrit/")
```

### Modify Settings (append/prepend/remove list items)

```python
from django.test import modify_settings

@modify_settings(MIDDLEWARE={
    "append": "django.middleware.cache.FetchFromCacheMiddleware",
    "prepend": "django.middleware.cache.UpdateCacheMiddleware",
    "remove": ["django.contrib.sessions.middleware.SessionMiddleware"],
})
def test_cache_middleware(self):
    pass
```

## RequestFactory

Creates request instances for testing views directly without middleware:

```python
from django.test import RequestFactory, TestCase
from django.contrib.auth.models import User, AnonymousUser
from .views import MyView

class ViewTest(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.user = User.objects.create_user("jacob", "jacob@example.com", "secret")

    def test_detail_view(self):
        request = self.factory.get("/customer/details")
        request.user = self.user  # Must set user manually

        # Function-based view
        response = my_view(request)
        self.assertEqual(response.status_code, 200)

        # Class-based view
        response = MyView.as_view()(request)
        self.assertEqual(response.status_code, 200)
```

### AsyncRequestFactory

```python
from django.test import AsyncRequestFactory

factory = AsyncRequestFactory()
request = factory.get("/path/")  # Returns ASGIRequest
```

## Fixtures

```python
class MyTests(TestCase):
    fixtures = ["mammals.json", "birds"]

    def test_with_fixture_data(self):
        # Fixture data is loaded before each test
        pass
```

## Test Tagging

```python
from django.test import tag

class SampleTestCase(TestCase):
    @tag("fast")
    def test_fast(self): ...

    @tag("slow")
    def test_slow(self): ...

    @tag("slow", "core")
    def test_slow_but_core(self): ...
```

```bash
./manage.py test --tag=fast
./manage.py test --tag=core --exclude-tag=slow
```

## Email Testing

```python
from django.core import mail

class EmailTest(TestCase):
    def test_send_email(self):
        mail.send_mail("Subject", "Body", "from@example.com", ["to@example.com"])

        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].subject, "Subject")
```

## on_commit Callbacks

```python
class ContactTests(TestCase):
    def test_contact_email_sent(self):
        with self.captureOnCommitCallbacks(execute=True) as callbacks:
            response = self.client.post("/contact/", {"message": "Test"})
        self.assertEqual(len(callbacks), 1)
```

## Running Tests

```bash
# Run all tests
./manage.py test

# Run specific app/module/class/method
./manage.py test animals.tests.AnimalTestCase.test_animals_can_speak

# Useful options
./manage.py test --failfast           # Stop on first failure
./manage.py test --parallel           # Run in parallel
./manage.py test --keepdb             # Preserve test database
./manage.py test --shuffle            # Randomize order
./manage.py test --verbosity=2        # Verbose output
./manage.py test --pattern="tests_*.py"  # Custom file pattern
```

## Custom Test Runner

```python
from django.test.runner import DiscoverRunner

class CustomTestRunner(DiscoverRunner):
    def setup_test_environment(self, **kwargs):
        super().setup_test_environment(**kwargs)

    def run_tests(self, test_labels, **kwargs):
        return super().run_tests(test_labels, **kwargs)

    @classmethod
    def add_arguments(cls, parser):
        super().add_arguments(parser)
        parser.add_argument("--my-option", action="store_true")
```

```python
# settings.py
TEST_RUNNER = "myapp.runners.CustomTestRunner"
```

## Sequential Test Execution

```python
from django.test import TestCase
from django.test.testcases import SerializeMixin

class FileTestMixin(SerializeMixin):
    lockfile = __file__

class RemoveFileTests(FileTestMixin, TestCase):
    def test_remove(self):
        pass

class ReadFileTests(FileTestMixin, TestCase):
    def test_read(self):
        pass
```

## Best Practices

- Use `TestCase` for database tests (transaction isolation, faster than `TransactionTestCase`)
- Use `setUpTestData` for expensive setup shared across test methods
- Use `SimpleTestCase` for tests without database access
- Use `force_login` instead of `login` for faster authentication in tests
- Use `--keepdb` during development for faster test runs
- Use faster password hashers in test settings (`MD5PasswordHasher`)
- Use `InMemoryStorage` for file fields to avoid disk I/O
- Tag tests for selective execution
- Test with `DEBUG=False` (Django enforces this by default)
