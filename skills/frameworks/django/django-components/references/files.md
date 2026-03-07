# Django Files

## Overview

Django provides a comprehensive file handling API for managing uploaded files, storing files on disk or remote backends, and associating files with model instances through `FileField` and `ImageField`. The system abstracts storage backends behind a unified API, making it easy to switch between local filesystem, cloud storage, or custom backends.

## Core Concepts

### File Objects

Django wraps Python file objects with `django.core.files.File`, adding Django-specific functionality.

```python
from django.core.files import File

# Wrap a Python file object
with open("/path/to/hello.world", "w") as f:
    myfile = File(f)
    myfile.write("Hello World")
# Both myfile and f are closed after the with block
```

### File Class API

| Attribute/Method | Description |
|---|---|
| `name` | File name including relative path from MEDIA_ROOT |
| `size` | File size in bytes |
| `file` | Underlying Python file object |
| `mode` | Read/write mode |
| `open(mode=None)` | Opens or reopens file (seeks to 0), usable as context manager |
| `read()` | Read entire file content |
| `write(content)` | Write content to file |
| `close()` | Close the file |
| `chunks(chunk_size=None)` | Iterate in chunks (default 64 KB) |
| `multiple_chunks(chunk_size=None)` | Returns True if file requires multiple chunks |

### ContentFile

Creates a file from string or bytes content without an actual file on disk:

```python
from django.core.files.base import ContentFile

f1 = ContentFile("esta frase esta en espanol")
f2 = ContentFile(b"these are bytes")
```

### ImageFile

Extends `File` with image-specific attributes:

```python
from django.core.files.images import ImageFile

# Available on ImageField instances
car.photo.width   # Width in pixels
car.photo.height  # Height in pixels
```

## Using Files in Models

### FileField and ImageField

```python
from django.db import models

class Car(models.Model):
    name = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=5, decimal_places=2)
    photo = models.ImageField(upload_to="cars")
    specs = models.FileField(upload_to="specs")
```

### Accessing File Attributes

```python
car = Car.objects.get(name="57 Chevy")
car.photo.name    # 'cars/chevy.jpg'
car.photo.path    # '/media/cars/chevy.jpg'
car.photo.url     # 'https://media.example.com/cars/chevy.jpg'
```

### Saving Files to Model Fields

```python
from pathlib import Path
from django.core.files import File

path = Path("/some/external/specs.pdf")
car = Car.objects.get(name="57 Chevy")
with path.open(mode="rb") as f:
    car.specs = File(f, name=path.name)
    car.save()
```

### File.save() and File.delete() on Model Fields

```python
# Save a new file to the field
car.photo.save("myphoto.jpg", content, save=True)

# Delete the file from storage and clear the field
car.photo.delete(save=True)
```

When `save=True`, the model's `save()` method is called automatically after the file operation.

## File Storage API

### Storage Backend Architecture

Django delegates file storage to pluggable backends configured via the `STORAGES` setting:

```python
# settings.py
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },
}
```

### default_storage

```python
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage

path = default_storage.save("path/to/file", ContentFile(b"new content"))
default_storage.size(path)        # 11
default_storage.open(path).read() # b'new content'
default_storage.exists(path)      # True
default_storage.delete(path)
```

### Storage Base Class Methods

| Method | Description |
|---|---|
| `open(name, mode='rb')` | Open file, return File object |
| `save(name, content, max_length=None)` | Save file, return actual name used |
| `delete(name)` | Delete a file |
| `exists(name)` | Check if file exists |
| `size(name)` | Return file size in bytes |
| `url(name)` | Return URL for file access |
| `path(name)` | Return local filesystem path |
| `listdir(path)` | Return (directories, files) tuple |
| `get_created_time(name)` | Return creation datetime |
| `get_modified_time(name)` | Return last modified datetime |
| `get_accessed_time(name)` | Return last accessed datetime |
| `get_valid_name(name)` | Return storage-safe filename |
| `get_available_name(name, max_length=None)` | Return unique available filename |

### FileSystemStorage

```python
from django.core.files.storage import FileSystemStorage

fs = FileSystemStorage(location="/media/photos")

class Car(models.Model):
    photo = models.ImageField(storage=fs)
```

Parameters: `location`, `base_url`, `file_permissions_mode`, `directory_permissions_mode`, `allow_overwrite`.

### InMemoryStorage

Non-persistent memory-based storage, useful for tests:

```python
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.InMemoryStorage",
    },
}
```

### Callable Storage Parameter

```python
from django.core.files.storage import storages

def select_storage():
    return storages["mystorage"]

class MyModel(models.Model):
    upload = models.FileField(storage=select_storage)
```

## File Uploads

### Basic Upload Handling

```python
# forms.py
from django import forms

class UploadFileForm(forms.Form):
    title = forms.CharField(max_length=50)
    file = forms.FileField()
```

```python
# views.py
from django.http import HttpResponseRedirect
from django.shortcuts import render

def upload_file(request):
    if request.method == "POST":
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            handle_uploaded_file(request.FILES["file"])
            return HttpResponseRedirect("/success/url/")
    else:
        form = UploadFileForm()
    return render(request, "upload.html", {"form": form})

def handle_uploaded_file(f):
    with open("some/file/name.txt", "wb+") as destination:
        for chunk in f.chunks():
            destination.write(chunk)
```

Use `.chunks()` instead of `.read()` to avoid memory overflow on large files.

### Upload with ModelForm

```python
def upload_file(request):
    if request.method == "POST":
        form = ModelFormWithFileField(request.POST, request.FILES)
        if form.is_valid():
            form.save()  # File saved automatically
            return HttpResponseRedirect("/success/url/")
    else:
        form = ModelFormWithFileField()
    return render(request, "upload.html", {"form": form})
```

### Multiple File Uploads

```python
from django import forms

class MultipleFileInput(forms.ClearableFileInput):
    allow_multiple_selected = True

class MultipleFileField(forms.FileField):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("widget", MultipleFileInput())
        super().__init__(*args, **kwargs)

    def clean(self, data, initial=None):
        single_file_clean = super().clean
        if isinstance(data, (list, tuple)):
            result = [single_file_clean(d, initial) for d in data]
        else:
            result = [single_file_clean(data, initial)]
        return result
```

### Upload Handlers

Default handlers in `FILE_UPLOAD_HANDLERS`:

| Handler | Behavior |
|---|---|
| `MemoryFileUploadHandler` | Files < 2.5 MB kept in memory |
| `TemporaryFileUploadHandler` | Larger files written to temp directory |

## Writing Custom Storage Backends

```python
from django.core.files.storage import Storage
from django.utils.deconstruct import deconstructible

@deconstructible
class MyStorage(Storage):
    def __init__(self, option=None):
        if not option:
            option = settings.CUSTOM_STORAGE_OPTIONS

    def _open(self, name, mode="rb"):
        # Must return a File object
        # Raise FileNotFoundError if file doesn't exist
        pass

    def _save(self, name, content):
        # Save the file and return the actual name used
        return name

    def exists(self, name):
        pass

    def url(self, name):
        pass

    def delete(self, name):
        pass

    def size(self, name):
        pass
```

The `@deconstructible` decorator is required for migration serialization.

## Configuration

| Setting | Description |
|---|---|
| `MEDIA_ROOT` | Absolute filesystem path for user-uploaded files |
| `MEDIA_URL` | URL prefix for serving uploaded files |
| `STORAGES` | Dictionary of storage backend configurations |
| `FILE_UPLOAD_HANDLERS` | List of upload handler classes |
| `FILE_UPLOAD_PERMISSIONS` | Numeric mode for uploaded files (e.g., 0o644) |
| `FILE_UPLOAD_DIRECTORY_PERMISSIONS` | Numeric mode for upload directories |

## Best Practices

- Always use `.chunks()` when processing large uploaded files to avoid memory overflow
- Close files manually when iterating over large querysets to prevent "Too many open files" errors
- Use `ContentFile` for creating files from in-memory data without touching disk
- Use `InMemoryStorage` in tests to avoid filesystem side effects
- Use callable storage parameters to allow runtime storage selection
- Validate uploaded file types at the application level; do not rely solely on file extensions
- Use `upload_to` on FileField/ImageField to organize uploads into subdirectories
- Configure `MEDIA_ROOT` and `MEDIA_URL` separately from static files
