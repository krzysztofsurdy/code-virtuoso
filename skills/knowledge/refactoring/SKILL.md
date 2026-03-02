---
name: refactoring
description: Comprehensive skill for 89 refactoring techniques and code smells with PHP 8.3+ examples. Covers composing methods, moving features, organizing data, simplifying conditionals, simplifying method calls, dealing with generalization, and detecting 22 code smells across bloaters, OO abusers, change preventers, dispensables, and couplers.
user-invocable: false
---

# Refactoring

A thorough reference covering 89 refactoring techniques and code smells — featuring PHP 8.3+ examples, rationale, step-by-step mechanics, and before/after comparisons.

## Refactoring Techniques (67)

### Composing Methods
- **Extract Method** — Pull code fragments into named methods → [reference](references/extract-method.md)
- **Inline Method** — Substitute a method call with its body → [reference](references/inline-method.md)
- **Extract Variable** — Give complex expressions meaningful names through explanatory variables → [reference](references/extract-variable.md)
- **Inline Temp** — Substitute a temporary variable with its expression → [reference](references/inline-temp.md)
- **Replace Temp with Query** — Swap temp variables for method calls → [reference](references/replace-temp-with-query.md)
- **Split Temporary Variable** — Assign separate variables for separate purposes → [reference](references/split-temporary-variable.md)
- **Remove Assignments to Parameters** — Introduce local variables rather than reassigning parameters → [reference](references/remove-assignments-to-parameters.md)
- **Replace Method with Method Object** — Convert a complex method into its own class → [reference](references/replace-method-with-method-object.md)
- **Substitute Algorithm** — Swap an algorithm for a clearer alternative → [reference](references/substitute-algorithm.md)

### Moving Features Between Objects
- **Move Method** — Relocate a method to the class that depends on it most → [reference](references/move-method.md)
- **Move Field** — Relocate a field to the class that depends on it most → [reference](references/move-field.md)
- **Extract Class** — Divide a class that handles too much → [reference](references/extract-class.md)
- **Inline Class** — Consolidate a class that does too little → [reference](references/inline-class.md)
- **Hide Delegate** — Introduce methods that conceal delegation chains → [reference](references/hide-delegate.md)
- **Remove Middle Man** — Allow clients to call the delegate directly → [reference](references/remove-middle-man.md)
- **Introduce Foreign Method** — Attach a missing method to a class you cannot modify → [reference](references/introduce-foreign-method.md)
- **Introduce Local Extension** — Build a wrapper or subclass for a library class → [reference](references/introduce-local-extension.md)

### Organizing Data
- **Self Encapsulate Field** — Route field access through getters even within the class → [reference](references/self-encapsulate-field.md)
- **Replace Data Value with Object** — Promote primitive data to a rich object → [reference](references/replace-data-value-with-object.md)
- **Change Value to Reference** — Convert value objects into reference objects → [reference](references/change-value-to-reference.md)
- **Change Reference to Value** — Convert reference objects into value objects → [reference](references/change-reference-to-value.md)
- **Replace Array with Object** — Swap arrays used as data structures for proper objects → [reference](references/replace-array-with-object.md)
- **Duplicate Observed Data** — Keep domain data in sync with the UI via Observer → [reference](references/duplicate-observed-data.md)
- **Change Unidirectional to Bidirectional** — Introduce back-references when needed → [reference](references/change-unidirectional-association-to-bidirectional.md)
- **Change Bidirectional to Unidirectional** — Eliminate unnecessary back-references → [reference](references/change-bidirectional-association-to-unidirectional.md)
- **Replace Magic Number with Symbolic Constant** — Assign meaningful names to magic numbers → [reference](references/replace-magic-number-with-symbolic-constant.md)
- **Encapsulate Field** — Restrict field visibility, expose accessors → [reference](references/encapsulate-field.md)
- **Encapsulate Collection** — Expose read-only views of collections → [reference](references/encapsulate-collection.md)
- **Replace Type Code with Class** — Swap type codes for enums or classes → [reference](references/replace-type-code-with-class.md)
- **Replace Type Code with Subclasses** — Swap type codes for a class hierarchy → [reference](references/replace-type-code-with-subclasses.md)
- **Replace Type Code with State/Strategy** — Swap behavior-affecting type codes for State/Strategy → [reference](references/replace-type-code-with-state-strategy.md)
- **Replace Subclass with Fields** — Eliminate subclasses that differ only in constants → [reference](references/replace-subclass-with-fields.md)

### Simplifying Conditional Expressions
- **Decompose Conditional** — Break complex conditionals into named methods → [reference](references/decompose-conditional.md)
- **Consolidate Conditional Expression** — Merge conditions that produce the same result → [reference](references/consolidate-conditional-expression.md)
- **Consolidate Duplicate Conditional Fragments** — Hoist identical code outside of conditionals → [reference](references/consolidate-duplicate-conditional-fragments.md)
- **Remove Control Flag** — Swap control flags for break/return/continue → [reference](references/remove-control-flag.md)
- **Replace Nested Conditional with Guard Clauses** — Flatten nested conditionals using early returns → [reference](references/replace-nested-conditional-with-guard-clauses.md)
- **Replace Conditional with Polymorphism** — Swap conditionals for polymorphic method calls → [reference](references/replace-conditional-with-polymorphism.md)
- **Introduce Null Object** — Swap null checks for a null object → [reference](references/introduce-null-object.md)
- **Introduce Assertion** — Insert assertions to document assumptions → [reference](references/introduce-assertion.md)

### Simplifying Method Calls
- **Rename Method** — Choose method names that reveal their purpose → [reference](references/rename-method.md)
- **Add Parameter** — Introduce new parameters to support additional data → [reference](references/add-parameter.md)
- **Remove Parameter** — Drop unused method parameters → [reference](references/remove-parameter.md)
- **Separate Query from Modifier** — Divide methods that both return values and change state → [reference](references/separate-query-from-modifier.md)
- **Parameterize Method** — Unify similar methods by adding a parameter → [reference](references/parameterize-method.md)
- **Replace Parameter with Explicit Methods** — Produce separate methods for each parameter value → [reference](references/replace-parameter-with-explicit-methods.md)
- **Preserve Whole Object** — Pass the entire object rather than individual values → [reference](references/preserve-whole-object.md)
- **Replace Parameter with Method Call** — Derive values internally instead of passing them in → [reference](references/replace-parameter-with-method-call.md)
- **Introduce Parameter Object** — Bundle related parameters into an object → [reference](references/introduce-parameter-object.md)
- **Remove Setting Method** — Eliminate setters for fields assigned only at creation → [reference](references/remove-setting-method.md)
- **Hide Method** — Narrow the visibility of unused public methods → [reference](references/hide-method.md)
- **Replace Constructor with Factory Method** — Use factory methods for complex object creation → [reference](references/replace-constructor-with-factory-method.md)
- **Replace Error Code with Exception** — Throw exceptions rather than returning error codes → [reference](references/replace-error-code-with-exception.md)
- **Replace Exception with Test** — Validate conditions upfront instead of catching exceptions → [reference](references/replace-exception-with-test.md)

### Dealing with Generalization
- **Pull Up Field** — Promote identical fields to the superclass → [reference](references/pull-up-field.md)
- **Pull Up Method** — Promote identical methods to the superclass → [reference](references/pull-up-method.md)
- **Pull Up Constructor Body** — Promote shared constructor logic to the superclass → [reference](references/pull-up-constructor-body.md)
- **Push Down Method** — Relocate a method to the subclass that uses it → [reference](references/push-down-method.md)
- **Push Down Field** — Relocate a field to the subclass that uses it → [reference](references/push-down-field.md)
- **Extract Subclass** — Carve out a subclass for a subset of features → [reference](references/extract-subclass.md)
- **Extract Superclass** — Hoist shared behavior into a parent class → [reference](references/extract-superclass.md)
- **Extract Interface** — Define a shared interface for common operations → [reference](references/extract-interface.md)
- **Collapse Hierarchy** — Merge superclass and subclass when they are too similar → [reference](references/collapse-hierarchy.md)
- **Form Template Method** — Generalize similar methods into a template → [reference](references/form-template-method.md)
- **Replace Inheritance with Delegation** — Swap inheritance for composition → [reference](references/replace-inheritance-with-delegation.md)
- **Replace Delegation with Inheritance** — Swap excessive delegation for inheritance → [reference](references/replace-delegation-with-inheritance.md)

## Code Smells (22)

### Bloaters
- **Long Method** — Methods that have grown excessively long → [reference](references/long-method.md)
- **Large Class** — Classes that try to handle too much → [reference](references/large-class.md)
- **Primitive Obsession** — Excessive use of primitives instead of small objects → [reference](references/primitive-obsession.md)
- **Long Parameter List** — Methods accepting too many parameters → [reference](references/long-parameter-list.md)
- **Data Clumps** — Groups of data that repeatedly appear together → [reference](references/data-clumps.md)

### Object-Orientation Abusers
- **Alternative Classes with Different Interfaces** — Similar classes with mismatched method signatures → [reference](references/alternative-classes-with-different-interfaces.md)
- **Refused Bequest** — Subclasses that disregard inherited behavior → [reference](references/refused-bequest.md)
- **Switch Statements** — Complex switch/match constructs that should be polymorphism → [reference](references/switch-statements.md)
- **Temporary Field** — Fields populated only under certain conditions → [reference](references/temporary-field.md)

### Change Preventers
- **Divergent Change** — A single class modified for many unrelated reasons → [reference](references/divergent-change.md)
- **Parallel Inheritance Hierarchies** — Creating one subclass forces creating another → [reference](references/parallel-inheritance-hierarchies.md)
- **Shotgun Surgery** — A single change demands edits across many classes → [reference](references/shotgun-surgery.md)

### Dispensables
- **Comments** — Excessive comments that mask unclear code → [reference](references/comments.md)
- **Duplicate Code** — Identical or nearly identical code in multiple locations → [reference](references/duplicate-code.md)
- **Data Class** — Classes consisting of nothing but fields and getters/setters → [reference](references/data-class.md)
- **Dead Code** — Unreachable or unused code → [reference](references/dead-code.md)
- **Lazy Class** — Classes that contribute too little to justify their existence → [reference](references/lazy-class.md)
- **Speculative Generality** — Unused abstractions built "just in case" → [reference](references/speculative-generality.md)

### Couplers
- **Feature Envy** — Methods that rely more on another class's data than their own → [reference](references/feature-envy.md)
- **Inappropriate Intimacy** — Classes that reach into each other's internals → [reference](references/inappropriate-intimacy.md)
- **Incomplete Library Class** — Library classes that fall short of providing needed features → [reference](references/incomplete-library-class.md)
- **Message Chains** — Long chains of method calls (a.b().c().d()) → [reference](references/message-chains.md)
- **Middle Man** — Classes that do nothing but delegate to another class → [reference](references/middle-man.md)

## Best Practices

- Refactor in **small, verified steps** — execute tests after every change
- Follow the **Boy Scout Rule**: leave code in better shape than you found it
- Reach for **IDE refactoring tools** when available for safe, automated transformations
- Never refactor and alter behavior simultaneously — keep them separate
- Prioritize refactoring that **lowers coupling** and **raises cohesion**
- Tackle code smells **nearest to your current work** first
