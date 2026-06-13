# Symfony Form Component

## Contents

- [Overview](#overview)
- [Core concepts](#core-concepts)
- [Form field types](#form-field-types)
- [Common form type options](#common-form-type-options)
- [Form events](#form-events)
- [Data Transformers](#data-transformers)
- [Collections and embedded forms](#collections-and-embedded-forms)
- [Validation groups](#validation-groups)
- [Custom form types](#custom-form-types)
- [The inherit_data option](#the-inherit_data-option)
- [Empty data](#empty-data)
- [Form rendering](#form-rendering)
- [Common patterns](#common-patterns)
- [Best practices](#best-practices)

## Overview

The Symfony Form component builds HTML forms in PHP applications. It handles form creation, data binding, validation, rendering, and submission, and includes CSRF protection, internationalization, and support for custom field types.

## Core concepts

### Form creation

Create forms with the FormBuilder or the form factory:

```php
// Using FormFactory (standalone)
$form = $formFactory->createBuilder(MyType::class)
    ->add('name', TextType::class)
    ->add('email', EmailType::class)
    ->getForm();

// In Symfony app with FormBuilderInterface
public function buildForm(FormBuilderInterface $builder, array $options): void
{
    $builder
        ->add('name', TextType::class)
        ->add('email', EmailType::class, ['required' => false])
        ->add('message', TextareaType::class)
        ->add('send', SubmitType::class);
}
```

### Form submission and validation

Handle a submission and validate it:

```php
$form->handleRequest($request);

if ($form->isSubmitted() && $form->isValid()) {
    $data = $form->getData();
    // Process the form data
}

// Access form errors
if ($form->isSubmitted() && !$form->isValid()) {
    foreach ($form->getErrors() as $error) {
        echo $error->getMessage();
    }
}
```

## Form field types

### Text input types
- **TextType**: Basic single-line text input
- **TextareaType**: Multi-line text input
- **EmailType**: Email address validation
- **PasswordType**: Password input (value not shown)
- **UrlType**: URL validation
- **SearchType**: Search field
- **TelType**: Telephone number
- **ColorType**: HTML5 color picker
- **RangeType**: Slider input
- **IntegerType**: Integer-only input
- **MoneyType**: Currency input with symbol
- **NumberType**: Decimal number input
- **PercentType**: Percentage input

### Choice types
- **ChoiceType**: Single or multiple select options
- **EnumType**: PHP enum selection
- **EntityType**: Doctrine entity selection
- **CountryType**: Country selection
- **LanguageType**: Language selection
- **LocaleType**: Locale selection
- **TimezoneType**: Timezone selection
- **CurrencyType**: Currency selection

### Date and time types
- **DateType**: Date picker
- **DateTimeType**: Date and time picker
- **TimeType**: Time input
- **DateIntervalType**: Duration/interval input
- **BirthdayType**: Birthday with age restrictions
- **WeekType**: ISO 8601 week selection

### Boolean and file types
- **CheckboxType**: Single checkbox
- **RadioType**: Radio button option
- **FileType**: File upload
- **RepeatedType**: Confirm field (e.g., password confirmation)

### Collection and container types
- **CollectionType**: Embed multiple forms of the same type
- **FormType**: Container for grouping fields
- **HiddenType**: Hidden form field
- **ButtonType**: Button without submit behavior
- **SubmitType**: Submit button
- **ResetType**: Reset button

### Specialized types
- **UuidType**: UUID field
- **UlidType**: ULID field

## Common form type options

```php
->add('fieldName', FieldType::class, [
    'required' => true,                    // Make field required
    'label' => 'Custom Label',             // Override label
    'help' => 'Helper text shown below',   // Help text
    'attr' => ['class' => 'my-class'],     // HTML attributes
    'disabled' => false,                   // Disable field
    'data' => 'default value',             // Set default value
    'error_bubbling' => true,              // Bubble errors to parent
    'constraints' => [new Assert\NotNull()],
    'mapped' => true,                      // Map to object property
    'property_path' => 'customPath',       // Override property mapping
    'inherit_data' => false,               // Inherit from parent form
    'by_reference' => true,                // Use property reference
    'empty_data' => null,                  // Data when form empty
    'validation_groups' => ['Default'],    // Validation groups to apply
    'block_name' => 'custom',              // Custom block name for rendering
])
```

## Form events

Form events let you modify the form and its data at each stage of the lifecycle:

```php
use Symfony\Component\Form\FormEvents;
use Symfony\Component\Form\Event\PreSetDataEvent;
use Symfony\Component\Form\Event\PreSubmitEvent;
use Symfony\Component\Form\Event\PostSubmitEvent;

// PRE_SET_DATA: Before form is populated with model data
$builder->addEventListener(FormEvents::PRE_SET_DATA, function (PreSetDataEvent $event): void {
    $data = $event->getData();
    $form = $event->getForm();

    if ($data && $data->isAdmin()) {
        $form->add('permissions', ChoiceType::class, ['choices' => [...]]);
    }
});

// POST_SET_DATA: After form is populated
$builder->addEventListener(FormEvents::POST_SET_DATA, function (PreSetDataEvent $event): void {
    // Modify form after data is set
});

// PRE_SUBMIT: Before form processes submitted data
$builder->addEventListener(FormEvents::PRE_SUBMIT, function (PreSubmitEvent $event): void {
    $data = $event->getData();
    // Modify raw submitted data
});

// POST_SUBMIT: After form denormalization
$builder->addEventListener(FormEvents::POST_SUBMIT, function (PostSubmitEvent $event): void {
    // Access final normalized data
});
```

### Event subscribers

```php
namespace App\Form\EventListener;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\Form\FormEvents;
use Symfony\Component\Form\Event\PreSetDataEvent;

class DynamicFieldSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            FormEvents::PRE_SET_DATA => 'onPreSetData',
            FormEvents::POST_SUBMIT => 'onPostSubmit',
        ];
    }

    public function onPreSetData(PreSetDataEvent $event): void { }
    public function onPostSubmit(PostSubmitEvent $event): void { }
}

// Use in form
$builder->addEventSubscriber(new DynamicFieldSubscriber());
```

## Data Transformers

Transformers convert data between the model format, the normalized format, and the view format.

### CallbackTransformer

```php
use Symfony\Component\Form\CallbackTransformer;

$builder->get('tags')
    ->addModelTransformer(new CallbackTransformer(
        function ($tagsAsArray): string {
            // array to string for display
            return implode(', ', $tagsAsArray ?? []);
        },
        function ($tagsAsString): array {
            // string back to array on submit
            return explode(', ', trim($tagsAsString));
        }
    ));
```

### Custom transformer class

```php
use Symfony\Component\Form\DataTransformerInterface;
use Symfony\Component\Form\Exception\TransformationFailedException;

class IssueToNumberTransformer implements DataTransformerInterface
{
    public function __construct(private EntityManagerInterface $em) {}

    public function transform($issue): string
    {
        return $issue?->getId() ?? '';
    }

    public function reverseTransform($issueNumber): ?Issue
    {
        if (!$issueNumber) {
            return null;
        }

        $issue = $this->em->getRepository(Issue::class)->find($issueNumber);

        if (!$issue) {
            throw new TransformationFailedException(
                "Issue '$issueNumber' does not exist"
            );
        }

        return $issue;
    }
}

// Use in form
$builder->get('issue')->addModelTransformer(new IssueToNumberTransformer($em));
```

## Collections and embedded forms

### Basic collection

```php
$builder->add('tags', CollectionType::class, [
    'entry_type' => TagType::class,
    'entry_options' => ['label' => false],
]);
```

### Dynamic collections

```php
$builder->add('tags', CollectionType::class, [
    'entry_type' => TagType::class,
    'allow_add' => true,       // Allow adding items dynamically
    'allow_delete' => true,    // Allow removing items
    'by_reference' => false,   // Use adder/remover methods
]);

// In Entity
public function addTag(Tag $tag): void
{
    $this->tags->add($tag);
}

public function removeTag(Tag $tag): void
{
    $this->tags->removeElement($tag);
}
```

### JavaScript for adding items

```javascript
document.querySelectorAll('.add_item_link').forEach(btn => {
    btn.addEventListener('click', function(e) {
        e.preventDefault();
        const collectionHolder = document.querySelector('.' + this.dataset.collectionHolderClass);
        const item = document.createElement('li');
        item.innerHTML = collectionHolder.dataset.prototype.replace(/__name__/g, collectionHolder.dataset.index);
        collectionHolder.appendChild(item);
        collectionHolder.dataset.index++;
    });
});
```

## Validation groups

Apply different validation rules depending on context:

```php
public function configureOptions(OptionsResolver $resolver): void
{
    $resolver->setDefaults([
        'validation_groups' => ['Default', 'registration'],
    ]);
}

// Dynamic validation groups based on data
'validation_groups' => function (FormInterface $form): array {
    $data = $form->getData();
    return $data->isPremium() ? ['Default', 'premium'] : ['Default'];
}

// Skip validation on specific buttons
->add('previousStep', SubmitType::class, [
    'validation_groups' => false,
])
```

## Custom form types

### Based on an existing type

```php
class ShippingType extends AbstractType
{
    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'choices' => [
                'Standard' => 'standard',
                'Express' => 'express',
            ],
        ]);
    }

    public function getParent(): string
    {
        return ChoiceType::class;
    }
}
```

### Built from scratch

```php
class AddressType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('street', TextType::class)
            ->add('city', TextType::class)
            ->add('zipCode', TextType::class)
            ->add('country', CountryType::class);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => Address::class,
        ]);
    }
}
```

## The inherit_data option

A form with `inherit_data` uses its parent's data, which removes duplication between forms:

```php
class LocationType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('address', TextType::class)
            ->add('city', TextType::class)
            ->add('country', CountryType::class);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'inherit_data' => true,  // Access parent's properties
        ]);
    }
}

// Use in multiple parent forms
$builder->add('location', LocationType::class);
```

## Empty data

Set the data to use when the form is submitted empty:

```php
public function configureOptions(OptionsResolver $resolver): void
{
    $resolver->setDefaults([
        // Option 1: Use closure (preferred)
        'empty_data' => function (FormInterface $form): Blog {
            return new Blog($form->get('title')->getData());
        },

        // Option 2: Direct instantiation
        'empty_data' => new Blog(),
    ]);
}
```

## Form rendering

### Twig functions

```twig
{{ form(form) }}                        {# Render entire form #}
{{ form_start(form) }}                  {# Open form tag #}
{{ form_errors(form) }}                 {# Form-level errors #}
{{ form_row(form.field) }}              {# Complete field with label & errors #}
{{ form_label(form.field) }}            {# Field label only #}
{{ form_widget(form.field) }}           {# Field widget only #}
{{ form_help(form.field) }}             {# Help text #}
{{ form_errors(form.field) }}           {# Field errors #}
{{ form_end(form) }}                    {# Close form tag #}
```

### Custom attributes

```twig
{{ form_widget(form.field, {'attr': {'class': 'form-control', 'data-toggle': 'tooltip'}}) }}

{{ form_label(form.field, 'Custom Label') }}
```

### Accessing field variables

```twig
{{ form.field.vars.id }}
{{ form.field.vars.label }}
{{ form.field.vars.required }}
{{ form.field.vars.errors }}
{{ form.field.vars.value }}
{{ form.field.vars.attr }}
```

## Common patterns

### Optional field based on a checkbox

```php
$builder->addEventListener(FormEvents::PRE_SUBMIT, function (PreSubmitEvent $event): void {
    $data = $event->getData();
    $form = $event->getForm();

    if (isset($data['hasEmail']) && $data['hasEmail']) {
        $form->add('email', EmailType::class);
    } else {
        unset($data['email']);
        $event->setData($data);
    }
});
```

### Dependent field selection

```php
$formModifier = function (FormInterface $form, ?Category $category = null): void {
    $form->add('product', EntityType::class, [
        'class' => Product::class,
        'choices' => $category ? $category->getProducts() : [],
    ]);
};

$builder->addEventListener(FormEvents::PRE_SET_DATA, function (PreSetDataEvent $event) use ($formModifier): void {
    $formModifier($event->getForm(), $event->getData()?->getCategory());
});

$builder->get('category')->addEventListener(FormEvents::POST_SUBMIT, function (PostSubmitEvent $event) use ($formModifier): void {
    $formModifier($event->getForm()->getParent(), $event->getForm()->getData());
});
```

## Best practices

- Put reusable form configuration in form types, and create a custom type instead of duplicating field definitions.
- Use event subscribers for complex dynamic behavior.
- Use validation groups when a form is used in several contexts.
- Use data transformers for non-trivial format conversions.
- Set `inherit_data: true` in shared form types that work across entities.
- Use `CollectionType` for one-to-many relationships, with `allow_add` and `allow_delete` and `by_reference: false`.
- Validate all user input.
- Keep CSRF protection on every form that changes state.
