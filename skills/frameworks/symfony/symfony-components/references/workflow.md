# Symfony Workflow component

The Workflow component models a business process as places (states) and transitions (actions). Use it for approval flows, publishing pipelines, order processing, and other state-driven domain logic.

## Contents

- [Installation](#installation)
- [Core concepts](#core-concepts)
- [Configuration](#configuration)
- [Core classes and methods](#core-classes-and-methods)
- [Usage in services and controllers](#usage-in-services-and-controllers)
- [Workflow events](#workflow-events)
- [Guard events and blocking transitions](#guard-events-and-blocking-transitions)
- [Metadata](#metadata)
- [Custom marking stores](#custom-marking-stores)
- [Programmatic workflow definition](#programmatic-workflow-definition)
- [Weighted transitions (multiple tokens)](#weighted-transitions-multiple-tokens)
- [Best practices](#best-practices)

## Installation

```bash
composer require symfony/workflow
```

## Core concepts

### Places and transitions
- **Places**: named steps or states an object can occupy (for example `draft`, `reviewed`, `published`)
- **Transitions**: named actions that move objects between places
- **Marking**: the current place or places of an object
- **Definition**: the places, transitions, and initial marking of a workflow

### Workflow vs state machine
- **Workflow**: an object can be in several places at once (multiple tokens)
- **State machine**: an object occupies exactly one place at a time (single token)

Use a workflow for parallel processes, such as document review plus layout approval. Use a state machine for sequential ones, such as an article going draft, review, published.

## Configuration

### YAML configuration

```yaml
# config/packages/workflow.yaml
framework:
    workflows:
        blog_publishing:
            type: 'workflow'  # or 'state_machine'
            audit_trail:
                enabled: true
            marking_store:
                type: 'method'
                property: 'currentPlace'
            supports:
                - App\Entity\BlogPost
            initial_marking: draft
            places:
                - draft
                - reviewed
                - rejected
                - published
            transitions:
                to_review:
                    from: draft
                    to: reviewed
                    guard: "is_granted('ROLE_REVIEWER')"
                publish:
                    from: reviewed
                    to: published
                    guard: "is_authenticated()"
                reject:
                    from: reviewed
                    to: rejected
```

### Entity setup

```php
namespace App\Entity;

class BlogPost
{
    private string $currentPlace;
    private array $currentPlaces = [];  // For workflows (multiple states)

    public function getCurrentPlace(): string
    {
        return $this->currentPlace;
    }

    public function setCurrentPlace(string $place, array $context = []): void
    {
        $this->currentPlace = $place;
    }

    public function getCurrentPlaces(): array
    {
        return $this->currentPlaces;
    }

    public function setCurrentPlaces(array $places, array $context = []): void
    {
        $this->currentPlaces = $places;
    }
}
```

## Core classes and methods

### WorkflowInterface and StateMachineInterface

- `can(object $subject, string $transitionName): bool` - Check if transition allowed
- `apply(object $subject, string $transitionName, array $context = []): Marking` - Execute transition
- `getMarking(object $subject): Marking` - Get current marking
- `getEnabledTransitions(object $subject): array` - List all allowed transitions
- `getEnabledTransition(object $subject, string $transitionName): ?Transition` - Get specific transition
- `getName(): string` - Get workflow name
- `getDefinition(): Definition` - Get workflow definition
- `getMetadataStore(): MetadataStoreInterface` - Access workflow metadata

### Definition

- `getPlaces(): array` - List all places
- `getTransitions(): array` - List all transitions
- `getInitialPlaces(): array` - Get initial marking
- `getMetadataStore(): MetadataStoreInterface` - Access definition metadata

### Transition

- `getName(): string` - Get transition name
- `getFroms(): array` - Get source places
- `getTos(): array` - Get destination places
- `getMetadata(string $key, mixed $default = null): mixed` - Get transition metadata

### Marking

- `getPlaces(): array` - Get places as keys with marking counts as values
- `has(string $place): bool` - Check if place is marked

### MarkingStore interface

- `getMarking(object $subject): Marking` - Retrieve current marking
- `setMarking(object $subject, Marking $marking, array $context = []): void` - Persist marking

## Usage in services and controllers

### Dependency injection

```php
use Symfony\Component\Workflow\WorkflowInterface;
use Symfony\Component\DependencyInjection\Attribute\Target;

class ArticlePublisher
{
    // Method 1: Named argument (camelCase workflow name)
    public function __construct(
        private WorkflowInterface $blogPublishingWorkflow,
    ) {}

    // Method 2: Target attribute
    public function __construct(
        #[Target('blog_publishing')] private WorkflowInterface $workflow,
    ) {}

    // Method 3: Multiple workflows
    #[AutowireLocator('workflow', 'name')]
    private ServiceLocator $workflows;
}
```

### Common operations

```php
$post = new BlogPost();

// Check if transition allowed
if ($this->workflow->can($post, 'publish')) {
    $this->workflow->apply($post, 'publish');
}

// Get available transitions
$transitions = $this->workflow->getEnabledTransitions($post);
foreach ($transitions as $transition) {
    echo $transition->getName();
}

// Apply with context
try {
    $this->workflow->apply($post, 'publish', [
        'author' => $currentUser,
        'timestamp' => new \DateTime(),
    ]);
} catch (LogicException $e) {
    // Transition not allowed
}

// Check current state
$marking = $this->workflow->getMarking($post);
if ($marking->has('reviewed')) {
    // Object is in reviewed state
}

// Disable specific events during transition
$this->workflow->apply($post, 'publish', [
    Workflow::DISABLE_ANNOUNCE_EVENT => true,
    Workflow::DISABLE_LEAVE_EVENT => true,
]);
```

## Workflow events

### Event dispatch order

1. `workflow.guard` - Checks whether the transition is allowed (can block it)
2. `workflow.leave` - Leaving the source place(s)
3. `workflow.transition` - Transition in progress
4. `workflow.enter` - Entering the destination place(s), before the marking is updated
5. `workflow.entered` - Entering the destination place(s), after the marking is updated
6. `workflow.completed` - Transition finished
7. `workflow.announce` - Newly available transitions announced

### Event naming patterns

- `workflow.{event_type}` - All workflows
- `workflow.{workflow_name}.{event_type}` - Specific workflow
- `workflow.{workflow_name}.{event_type}.{place_or_transition}` - Specific place/transition

### Event subscriber

```php
namespace App\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\Workflow\Event\LeaveEvent;
use Symfony\Component\Workflow\Event\EnteredEvent;
use Symfony\Component\Workflow\Event\GuardEvent;
use Psr\Log\LoggerInterface;

class WorkflowAuditSubscriber implements EventSubscriberInterface
{
    public function __construct(private LoggerInterface $logger) {}

    public function onLeave(LeaveEvent $event): void
    {
        $this->logger->info('Leaving place', [
            'subject_id' => $event->getSubject()->getId(),
            'place' => $event->getMarking()->getPlaces(),
            'transition' => $event->getTransition()->getName(),
        ]);
    }

    public function onEntered(EnteredEvent $event): void
    {
        $this->logger->info('Entered place', [
            'place' => key($event->getMarking()->getPlaces()),
            'transition' => $event->getTransition()->getName(),
        ]);
    }

    public static function getSubscribedEvents(): array
    {
        return [
            'workflow.blog_publishing.leave' => 'onLeave',
            'workflow.blog_publishing.entered' => 'onEntered',
        ];
    }
}
```

### Attribute-based listeners

```php
use Symfony\Component\Workflow\Attribute\AsGuardListener;
use Symfony\Component\Workflow\Attribute\AsTransitionListener;
use Symfony\Component\Workflow\Event\GuardEvent;
use Symfony\Component\Workflow\Event\TransitionEvent;

class ArticleEventListener
{
    #[AsGuardListener(workflow: 'blog_publishing', transition: 'publish')]
    public function guardPublish(GuardEvent $event): void
    {
        if (!$event->getSubject()->hasContent()) {
            $event->setBlocked(true, 'Content required');
        }
    }

    #[AsTransitionListener(workflow: 'blog_publishing', transition: 'publish')]
    public function onPublish(TransitionEvent $event): void
    {
        $event->getSubject()->setPublishedAt(new \DateTime());
    }
}
```

## Guard events and blocking transitions

Guard events decide whether a transition is blocked. Attach a reason to the block so the user sees why.

### Configuration-based guards

```yaml
framework:
    workflows:
        blog_publishing:
            transitions:
                publish:
                    guard: "is_granted('ROLE_PUBLISHER')"
                reject:
                    guard: "is_granted('ROLE_ADMIN') and subject.isDraft()"
```

### Programmatic guards

```php
use Symfony\Component\Workflow\Event\GuardEvent;
use Symfony\Component\Workflow\TransitionBlocker;

class ReviewGuardSubscriber implements EventSubscriberInterface
{
    public function guardReview(GuardEvent $event): void
    {
        $post = $event->getSubject();

        if (empty($post->getTitle())) {
            $event->addTransitionBlocker(
                new TransitionBlocker('Title is required', 'title_empty')
            );
        }

        if ($post->getWordCount() < 100) {
            $event->addTransitionBlocker(
                new TransitionBlocker('Minimum 100 words required', 'insufficient_content')
            );
        }
    }

    public static function getSubscribedEvents(): array
    {
        return [
            'workflow.blog_publishing.guard.to_review' => 'guardReview',
        ];
    }
}
```

## Metadata

### Configuration

```yaml
framework:
    workflows:
        blog_publishing:
            metadata:
                title: 'Blog Publishing Workflow'
                description: 'Manages article publication'
            places:
                draft:
                    metadata:
                        max_words: 5000
                published:
                    metadata:
                        archive_after: 365
            transitions:
                publish:
                    metadata:
                        label: 'Publish Article'
                        icon: 'publish'
                        hour_limit: 22
```

### Access metadata

```php
// Workflow metadata
$title = $workflow->getMetadataStore()
    ->getWorkflowMetadata()['title'] ?? 'Default';

// Place metadata
$maxWords = $workflow->getMetadataStore()
    ->getPlaceMetadata('draft')['max_words'] ?? 10000;

// Transition metadata
$transition = $workflow->getEnabledTransition($post, 'publish');
$label = $workflow->getMetadataStore()
    ->getTransitionMetadata($transition)['label'] ?? 'Publish';

// Generic method
$title = $workflow->getMetadataStore()->getMetadata('title');
$maxWords = $workflow->getMetadataStore()->getMetadata('max_words', 'draft');
```

### Twig functions

```twig
{# Check if transition allowed #}
{% if workflow_can(post, 'publish') %}
    <button>{{ workflow_metadata(post, 'label', transition) }}</button>
{% endif %}

{# List enabled transitions #}
{% for transition in workflow_transitions(post) %}
    <a href="{{ path('article_apply', {'transition': transition.name}) }}">
        {{ workflow_metadata(post, 'label', transition) }}
    </a>
{% endfor %}

{# Check current place #}
{% if 'reviewed' in workflow_marked_places(post) %}
    <span class="badge">Reviewed</span>
{% endif %}

{# Show blockers #}
{% for blocker in workflow_transition_blockers(post, 'publish') %}
    <span class="error">{{ blocker.message }}</span>
{% endfor %}

{# Place metadata #}
{% for place in workflow_marked_places(post) %}
    Max words: {{ workflow_metadata(post, 'max_words', place) }}
{% endfor %}
```

## Custom marking stores

Implement `MarkingStoreInterface` to store markings your own way.

```php
namespace App\Workflow\MarkingStore;

use Symfony\Component\Workflow\Marking;
use Symfony\Component\Workflow\MarkingStore\MarkingStoreInterface;

final class DatabaseMarkingStore implements MarkingStoreInterface
{
    public function __construct(private Connection $connection) {}

    public function getMarking(object $subject): Marking
    {
        $places = $this->connection->fetchAllAssociative(
            'SELECT place FROM workflow_marking WHERE entity_id = ?',
            [$subject->getId()]
        );

        return new Marking(array_combine(
            array_column($places, 'place'),
            array_fill(0, count($places), 1)
        ));
    }

    public function setMarking(object $subject, Marking $marking, array $context = []): void
    {
        $this->connection->delete('workflow_marking', ['entity_id' => $subject->getId()]);

        foreach ($marking->getPlaces() as $place => $count) {
            $this->connection->insert('workflow_marking', [
                'entity_id' => $subject->getId(),
                'place' => $place,
            ]);
        }
    }
}
```

Register it in configuration:

```yaml
framework:
    workflows:
        blog_publishing:
            marking_store:
                service: 'App\Workflow\MarkingStore\DatabaseMarkingStore'
```

## Programmatic workflow definition

A workflow can be defined entirely in PHP, without configuration.

```php
use Symfony\Component\Workflow\Definition;
use Symfony\Component\Workflow\Transition;
use Symfony\Component\Workflow\Workflow;
use Symfony\Component\Workflow\MarkingStore\MethodMarkingStore;

$definition = new Definition(
    places: ['draft', 'review', 'published'],
    transitions: [
        new Transition('to_review', 'draft', 'review'),
        new Transition('publish', 'review', 'published'),
        new Transition('reject', 'review', 'draft'),
    ],
    initialMarking: 'draft',
);

$marking = new MethodMarkingStore(true, 'state');
$workflow = new Workflow($definition, $marking);
```

## Weighted transitions (multiple tokens)

When a place can hold several tokens, use weighted transitions.

```yaml
framework:
    workflows:
        make_table:
            type: 'workflow'
            places:
                - init
                - prepare_leg
                - prepare_top
                - leg_created
                - top_created
                - finished
            transitions:
                start:
                    from: init
                    to:
                        - place: prepare_leg
                          weight: 4
                        - place: prepare_top
                          weight: 1
                join:
                    from:
                        - place: leg_created
                          weight: 4
                        - place: top_created
                    to: finished
```

## Best practices

- Block invalid transitions in guard events and give each blocker a clear message
- Keep workflow labels, icons, and descriptions in metadata, not in code
- Subscribe to workflow events for audit logging and notifications
- Keep workflow logic separate from the entity's business logic
- Add metadata describing why each transition exists and its side effects
- Default to a state machine; use a workflow only when parallel states are needed
- Use PHP enums for type-safe place references
- With several workflows, inject a ServiceLocator instead of individual services
