---
name: refactoring
description: Comprehensive skill for 89 refactoring techniques and code smells with PHP 8.3+ examples. Covers composing methods, moving features, organizing data, simplifying conditionals, simplifying method calls, dealing with generalization, and detecting 22 code smells across bloaters, OO abusers, change preventers, dispensables, and couplers.
---

# Refactoring

Complete reference for 89 refactoring techniques and code smells — with PHP 8.3+ examples, motivation, mechanics, and before/after comparisons.

## Refactoring Techniques (67)

### Composing Methods
- **Extract Method** — Turn code fragments into named methods → [reference](references/extract-method.md)
- **Inline Method** — Replace a method call with its body → [reference](references/inline-method.md)
- **Extract Variable** — Name complex expressions with explanatory variables → [reference](references/extract-variable.md)
- **Inline Temp** — Replace a temporary variable with its expression → [reference](references/inline-temp.md)
- **Replace Temp with Query** — Replace temp variables with method calls → [reference](references/replace-temp-with-query.md)
- **Split Temporary Variable** — Use separate variables for separate purposes → [reference](references/split-temporary-variable.md)
- **Remove Assignments to Parameters** — Use local variables instead of reassigning parameters → [reference](references/remove-assignments-to-parameters.md)
- **Replace Method with Method Object** — Turn a complex method into its own class → [reference](references/replace-method-with-method-object.md)
- **Substitute Algorithm** — Replace an algorithm with a clearer one → [reference](references/substitute-algorithm.md)

### Moving Features Between Objects
- **Move Method** — Move a method to the class that uses it most → [reference](references/move-method.md)
- **Move Field** — Move a field to the class that uses it most → [reference](references/move-field.md)
- **Extract Class** — Split a class that does too much → [reference](references/extract-class.md)
- **Inline Class** — Merge a class that does too little → [reference](references/inline-class.md)
- **Hide Delegate** — Create methods to hide delegation chains → [reference](references/hide-delegate.md)
- **Remove Middle Man** — Let clients call the delegate directly → [reference](references/remove-middle-man.md)
- **Introduce Foreign Method** — Add a missing method to a class you can't modify → [reference](references/introduce-foreign-method.md)
- **Introduce Local Extension** — Create a wrapper or subclass for a library class → [reference](references/introduce-local-extension.md)

### Organizing Data
- **Self Encapsulate Field** — Access fields through getters even within the class → [reference](references/self-encapsulate-field.md)
- **Replace Data Value with Object** — Replace primitive data with a rich object → [reference](references/replace-data-value-with-object.md)
- **Change Value to Reference** — Replace value objects with reference objects → [reference](references/change-value-to-reference.md)
- **Change Reference to Value** — Replace reference objects with value objects → [reference](references/change-reference-to-value.md)
- **Replace Array with Object** — Replace arrays used as data structures with objects → [reference](references/replace-array-with-object.md)
- **Duplicate Observed Data** — Synchronize domain data with UI via Observer → [reference](references/duplicate-observed-data.md)
- **Change Unidirectional to Bidirectional** — Add back-references when needed → [reference](references/change-unidirectional-association-to-bidirectional.md)
- **Change Bidirectional to Unidirectional** — Remove unnecessary back-references → [reference](references/change-bidirectional-association-to-unidirectional.md)
- **Replace Magic Number with Symbolic Constant** — Name magic numbers with constants → [reference](references/replace-magic-number-with-symbolic-constant.md)
- **Encapsulate Field** — Make fields private, add accessors → [reference](references/encapsulate-field.md)
- **Encapsulate Collection** — Return read-only views of collections → [reference](references/encapsulate-collection.md)
- **Replace Type Code with Class** — Replace type codes with enums or classes → [reference](references/replace-type-code-with-class.md)
- **Replace Type Code with Subclasses** — Replace type codes with a class hierarchy → [reference](references/replace-type-code-with-subclasses.md)
- **Replace Type Code with State/Strategy** — Replace type codes affecting behavior with State/Strategy → [reference](references/replace-type-code-with-state-strategy.md)
- **Replace Subclass with Fields** — Replace subclasses that differ only in constants → [reference](references/replace-subclass-with-fields.md)

### Simplifying Conditional Expressions
- **Decompose Conditional** — Extract complex conditionals into named methods → [reference](references/decompose-conditional.md)
- **Consolidate Conditional Expression** — Combine conditions that lead to the same result → [reference](references/consolidate-conditional-expression.md)
- **Consolidate Duplicate Conditional Fragments** — Move identical code outside of conditionals → [reference](references/consolidate-duplicate-conditional-fragments.md)
- **Remove Control Flag** — Replace control flags with break/return/continue → [reference](references/remove-control-flag.md)
- **Replace Nested Conditional with Guard Clauses** — Flatten nested conditionals with early returns → [reference](references/replace-nested-conditional-with-guard-clauses.md)
- **Replace Conditional with Polymorphism** — Replace conditionals with polymorphic method calls → [reference](references/replace-conditional-with-polymorphism.md)
- **Introduce Null Object** — Replace null checks with a null object → [reference](references/introduce-null-object.md)
- **Introduce Assertion** — Add assertions to document assumptions → [reference](references/introduce-assertion.md)

### Simplifying Method Calls
- **Rename Method** — Give methods names that reveal their purpose → [reference](references/rename-method.md)
- **Add Parameter** — Add new parameter to support additional data → [reference](references/add-parameter.md)
- **Remove Parameter** — Remove unused method parameters → [reference](references/remove-parameter.md)
- **Separate Query from Modifier** — Split methods that both return values and change state → [reference](references/separate-query-from-modifier.md)
- **Parameterize Method** — Merge similar methods using a parameter → [reference](references/parameterize-method.md)
- **Replace Parameter with Explicit Methods** — Create separate methods for each parameter value → [reference](references/replace-parameter-with-explicit-methods.md)
- **Preserve Whole Object** — Pass the whole object instead of individual values → [reference](references/preserve-whole-object.md)
- **Replace Parameter with Method Call** — Compute values internally instead of passing them → [reference](references/replace-parameter-with-method-call.md)
- **Introduce Parameter Object** — Group related parameters into an object → [reference](references/introduce-parameter-object.md)
- **Remove Setting Method** — Remove setters for fields set only at creation → [reference](references/remove-setting-method.md)
- **Hide Method** — Reduce visibility of unused public methods → [reference](references/hide-method.md)
- **Replace Constructor with Factory Method** — Use factory methods for complex object creation → [reference](references/replace-constructor-with-factory-method.md)
- **Replace Error Code with Exception** — Throw exceptions instead of returning error codes → [reference](references/replace-error-code-with-exception.md)
- **Replace Exception with Test** — Check conditions before calling instead of catching → [reference](references/replace-exception-with-test.md)

### Dealing with Generalization
- **Pull Up Field** — Move identical fields to the superclass → [reference](references/pull-up-field.md)
- **Pull Up Method** — Move identical methods to the superclass → [reference](references/pull-up-method.md)
- **Pull Up Constructor Body** — Move shared constructor logic to the superclass → [reference](references/pull-up-constructor-body.md)
- **Push Down Method** — Move a method to the subclass that uses it → [reference](references/push-down-method.md)
- **Push Down Field** — Move a field to the subclass that uses it → [reference](references/push-down-field.md)
- **Extract Subclass** — Create a subclass for a subset of features → [reference](references/extract-subclass.md)
- **Extract Superclass** — Pull shared behavior into a parent class → [reference](references/extract-superclass.md)
- **Extract Interface** — Define a shared interface for common operations → [reference](references/extract-interface.md)
- **Collapse Hierarchy** — Merge superclass and subclass when too similar → [reference](references/collapse-hierarchy.md)
- **Form Template Method** — Generalize similar methods into a template → [reference](references/form-template-method.md)
- **Replace Inheritance with Delegation** — Replace inheritance with composition → [reference](references/replace-inheritance-with-delegation.md)
- **Replace Delegation with Inheritance** — Replace excessive delegation with inheritance → [reference](references/replace-delegation-with-inheritance.md)

## Code Smells (22)

### Bloaters
- **Long Method** — Methods that have grown too long → [reference](references/long-method.md)
- **Large Class** — Classes that try to do too much → [reference](references/large-class.md)
- **Primitive Obsession** — Overuse of primitives instead of small objects → [reference](references/primitive-obsession.md)
- **Long Parameter List** — Methods with too many parameters → [reference](references/long-parameter-list.md)
- **Data Clumps** — Groups of data that appear together repeatedly → [reference](references/data-clumps.md)

### Object-Orientation Abusers
- **Alternative Classes with Different Interfaces** — Similar classes with different method signatures → [reference](references/alternative-classes-with-different-interfaces.md)
- **Refused Bequest** — Subclasses that don't use inherited behavior → [reference](references/refused-bequest.md)
- **Switch Statements** — Complex switch/match that should be polymorphism → [reference](references/switch-statements.md)
- **Temporary Field** — Fields only set in certain circumstances → [reference](references/temporary-field.md)

### Change Preventers
- **Divergent Change** — One class changed for many different reasons → [reference](references/divergent-change.md)
- **Parallel Inheritance Hierarchies** — Creating a subclass forces creating another → [reference](references/parallel-inheritance-hierarchies.md)
- **Shotgun Surgery** — One change requires edits in many classes → [reference](references/shotgun-surgery.md)

### Dispensables
- **Comments** — Excessive comments masking unclear code → [reference](references/comments.md)
- **Duplicate Code** — Identical or very similar code in multiple places → [reference](references/duplicate-code.md)
- **Data Class** — Classes with only fields and getters/setters → [reference](references/data-class.md)
- **Dead Code** — Unreachable or unused code → [reference](references/dead-code.md)
- **Lazy Class** — Classes that do too little to justify their existence → [reference](references/lazy-class.md)
- **Speculative Generality** — Unused abstractions created "just in case" → [reference](references/speculative-generality.md)

### Couplers
- **Feature Envy** — Methods that use another class's data more than their own → [reference](references/feature-envy.md)
- **Inappropriate Intimacy** — Classes that access each other's internals → [reference](references/inappropriate-intimacy.md)
- **Incomplete Library Class** — Library classes that don't provide needed features → [reference](references/incomplete-library-class.md)
- **Message Chains** — Long chains of method calls (a.b().c().d()) → [reference](references/message-chains.md)
- **Middle Man** — Classes that only delegate to another class → [reference](references/middle-man.md)

## Best Practices

- Refactor in **small, verified steps** — run tests after each change
- Apply the **Boy Scout Rule**: leave code cleaner than you found it
- Use **IDE refactoring tools** when available for safe, automated transformations
- Don't refactor and change behavior at the same time — separate the two
- Prioritize refactoring that **reduces coupling** and **increases cohesion**
- Address code smells **closest to where you're working** first
