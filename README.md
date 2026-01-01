# Code Virtuoso

AI agent skill sets for **Symfony components**, **Design Patterns**, and **Refactoring** — built on the [Agent Skills](https://agentskills.io) open standard.

Each skill teaches AI agents how to work effectively with specific topics: APIs, code patterns, configuration, common use cases, and PHP 8.3+ examples.

## Plugins

### Symfony Virtuoso (38 skills)

| Component | Description |
|-----------|-------------|
| [Asset](skills/symfony/symfony-asset/) | URL generation and versioning for web assets |
| [BrowserKit](skills/symfony/symfony-browser-kit/) | Simulated browser for programmatic HTTP requests |
| [Cache](skills/symfony/symfony-cache/) | PSR-6/PSR-16 cache adapters with tagging and invalidation |
| [Clock](skills/symfony/symfony-clock/) | Testable time abstraction with MockClock and DatePoint |
| [Config](skills/symfony/symfony-config/) | Configuration loading, validation, and caching |
| [Console](skills/symfony/symfony-console/) | CLI commands, input/output, helpers, and formatters |
| [Contracts](skills/symfony/symfony-contracts/) | Decoupled abstractions for interoperability |
| [CssSelector](skills/symfony/symfony-css-selector/) | CSS-to-XPath conversion for HTML/XML querying |
| [DependencyInjection](skills/symfony/symfony-dependency-injection/) | Service container, autowiring, and compiler passes |
| [DomCrawler](skills/symfony/symfony-dom-crawler/) | HTML/XML traversal and data extraction |
| [EventDispatcher](skills/symfony/symfony-event-dispatcher/) | Event-driven architecture with listeners and subscribers |
| [ExpressionLanguage](skills/symfony/symfony-expression-language/) | Compile and evaluate expressions in a safe sandbox |
| [Filesystem](skills/symfony/symfony-filesystem/) | Platform-independent file and directory operations |
| [Finder](skills/symfony/symfony-finder/) | File search with fluent criteria (name, size, date, depth) |
| [Form](skills/symfony/symfony-form/) | Form creation, field types, validation, and rendering |
| [HttpFoundation](skills/symfony/symfony-http-foundation/) | Object-oriented HTTP requests and responses |
| [HttpKernel](skills/symfony/symfony-http-kernel/) | Request handling, kernel events, and controller resolution |
| [Intl](skills/symfony/symfony-intl/) | Internationalization data (languages, countries, currencies) |
| [JsonPath](skills/symfony/symfony-json-path/) | RFC 9535 JSONPath queries on JSON structures |
| [Ldap](skills/symfony/symfony-ldap/) | LDAP/Active Directory connections, queries, and management |
| [Lock](skills/symfony/symfony-lock/) | Exclusive resource locking across processes and servers |
| [Messenger](skills/symfony/symfony-messenger/) | Sync/async message buses, transports, and middleware |
| [Mime](skills/symfony/symfony-mime/) | MIME message creation for emails and content types |
| [OptionsResolver](skills/symfony/symfony-options-resolver/) | Option systems with defaults, validation, and normalization |
| [PHPUnit Bridge](skills/symfony/symfony-phpunit-bridge/) | Enhanced testing with deprecation reporting and mocking |
| [Process](skills/symfony/symfony-process/) | System command execution with secure argument handling |
| [PropertyAccess](skills/symfony/symfony-property-access/) | Read/write object and array properties via string paths |
| [PropertyInfo](skills/symfony/symfony-property-info/) | Property metadata extraction (types, access, descriptions) |
| [PSR-7 Bridge](skills/symfony/symfony-psr7-bridge/) | Bidirectional HttpFoundation/PSR-7 conversion |
| [Runtime](skills/symfony/symfony-runtime/) | Decoupled bootstrapping for multiple runtime environments |
| [Semaphore](skills/symfony/symfony-semaphore/) | Concurrent resource access with configurable limits |
| [TypeInfo](skills/symfony/symfony-type-info/) | PHP type extraction, resolution, and validation |
| [Uid](skills/symfony/symfony-uid/) | UUID (v1-v8) and ULID generation, conversion, and storage |
| [Validator](skills/symfony/symfony-validator/) | Data validation with constraints, groups, and custom rules |
| [VarDumper](skills/symfony/symfony-var-dumper/) | Enhanced variable debugging and inspection |
| [VarExporter](skills/symfony/symfony-var-exporter/) | Export PHP data to OPcache-optimized code, lazy proxies |
| [Workflow](skills/symfony/symfony-workflow/) | State machines and workflows with guards and events |
| [Yaml](skills/symfony/symfony-yaml/) | YAML parsing, dumping, and linting |

### Design Patterns Virtuoso (26 skills)

| Pattern | Description |
|---------|-------------|
| [Abstract Factory](skills/design-patterns/abstract-factory/) | Create families of related objects without specifying concrete classes |
| [Adapter](skills/design-patterns/adapter/) | Convert an interface into another interface clients expect |
| [Bridge](skills/design-patterns/bridge/) | Decouple abstraction from implementation |
| [Builder](skills/design-patterns/builder/) | Construct complex objects step by step |
| [Chain of Responsibility](skills/design-patterns/chain-of-responsibility/) | Pass requests along a chain of handlers |
| [Command](skills/design-patterns/command/) | Encapsulate requests as objects |
| [Composite](skills/design-patterns/composite/) | Compose objects into tree structures |
| [Decorator](skills/design-patterns/decorator/) | Attach new behaviors dynamically via wrapping |
| [Facade](skills/design-patterns/facade/) | Provide a simplified interface to a subsystem |
| [Factory Method](skills/design-patterns/factory-method/) | Define an interface for creating objects, let subclasses decide |
| [Flyweight](skills/design-patterns/flyweight/) | Share common state between many objects |
| [Interpreter](skills/design-patterns/interpreter/) | Define a grammar representation and interpreter |
| [Iterator](skills/design-patterns/iterator/) | Traverse elements without exposing internals |
| [Mediator](skills/design-patterns/mediator/) | Reduce chaotic dependencies via a central coordinator |
| [Memento](skills/design-patterns/memento/) | Capture and restore object state without violating encapsulation |
| [Null Object](skills/design-patterns/null-object/) | Provide a do-nothing default to avoid null checks |
| [Object Pool](skills/design-patterns/object-pool/) | Reuse expensive-to-create objects |
| [Observer](skills/design-patterns/observer/) | Notify dependents automatically on state changes |
| [Private Class Data](skills/design-patterns/private-class-data/) | Restrict access to class attributes |
| [Prototype](skills/design-patterns/prototype/) | Clone existing objects without coupling to their classes |
| [Proxy](skills/design-patterns/proxy/) | Control access to an object via a surrogate |
| [Singleton](skills/design-patterns/singleton/) | Ensure a class has only one instance |
| [State](skills/design-patterns/state/) | Alter behavior when internal state changes |
| [Strategy](skills/design-patterns/strategy/) | Define interchangeable algorithms |
| [Template Method](skills/design-patterns/template-method/) | Define algorithm skeleton, let subclasses fill in steps |
| [Visitor](skills/design-patterns/visitor/) | Add operations to objects without modifying them |

### Refactoring Virtuoso (89 skills)

**Refactoring Techniques (67)**

| Technique | Description |
|-----------|-------------|
| [Add Parameter](skills/refactoring/add-parameter/) | Add new parameter to support additional data |
| [Change Bidirectional to Unidirectional](skills/refactoring/change-bidirectional-association-to-unidirectional/) | Remove unnecessary back-references |
| [Change Reference to Value](skills/refactoring/change-reference-to-value/) | Replace reference objects with value objects |
| [Change Unidirectional to Bidirectional](skills/refactoring/change-unidirectional-association-to-bidirectional/) | Add back-references when needed |
| [Change Value to Reference](skills/refactoring/change-value-to-reference/) | Replace value objects with reference objects |
| [Collapse Hierarchy](skills/refactoring/collapse-hierarchy/) | Merge superclass and subclass when too similar |
| [Consolidate Conditional Expression](skills/refactoring/consolidate-conditional-expression/) | Combine conditions that lead to the same result |
| [Consolidate Duplicate Conditional Fragments](skills/refactoring/consolidate-duplicate-conditional-fragments/) | Move identical code outside of conditionals |
| [Decompose Conditional](skills/refactoring/decompose-conditional/) | Extract complex conditionals into named methods |
| [Duplicate Observed Data](skills/refactoring/duplicate-observed-data/) | Synchronize domain data with UI via Observer |
| [Encapsulate Collection](skills/refactoring/encapsulate-collection/) | Return read-only views of collections |
| [Encapsulate Field](skills/refactoring/encapsulate-field/) | Make fields private, add accessors |
| [Extract Class](skills/refactoring/extract-class/) | Split a class that does too much |
| [Extract Interface](skills/refactoring/extract-interface/) | Define a shared interface for common operations |
| [Extract Method](skills/refactoring/extract-method/) | Turn code fragments into named methods |
| [Extract Subclass](skills/refactoring/extract-subclass/) | Create a subclass for a subset of features |
| [Extract Superclass](skills/refactoring/extract-superclass/) | Pull shared behavior into a parent class |
| [Extract Variable](skills/refactoring/extract-variable/) | Name complex expressions with explanatory variables |
| [Form Template Method](skills/refactoring/form-template-method/) | Generalize similar methods into a template |
| [Hide Delegate](skills/refactoring/hide-delegate/) | Create methods to hide delegation chains |
| [Hide Method](skills/refactoring/hide-method/) | Reduce visibility of unused public methods |
| [Inline Class](skills/refactoring/inline-class/) | Merge a class that does too little |
| [Inline Method](skills/refactoring/inline-method/) | Replace a method call with its body |
| [Inline Temp](skills/refactoring/inline-temp/) | Replace a temporary variable with its expression |
| [Introduce Assertion](skills/refactoring/introduce-assertion/) | Add assertions to document assumptions |
| [Introduce Foreign Method](skills/refactoring/introduce-foreign-method/) | Add a missing method to a class you can't modify |
| [Introduce Local Extension](skills/refactoring/introduce-local-extension/) | Create a wrapper or subclass for a library class |
| [Introduce Null Object](skills/refactoring/introduce-null-object/) | Replace null checks with a null object |
| [Introduce Parameter Object](skills/refactoring/introduce-parameter-object/) | Group related parameters into an object |
| [Move Field](skills/refactoring/move-field/) | Move a field to the class that uses it most |
| [Move Method](skills/refactoring/move-method/) | Move a method to the class that uses it most |
| [Parameterize Method](skills/refactoring/parameterize-method/) | Merge similar methods using a parameter |
| [Preserve Whole Object](skills/refactoring/preserve-whole-object/) | Pass the whole object instead of individual values |
| [Pull Up Constructor Body](skills/refactoring/pull-up-constructor-body/) | Move shared constructor logic to the superclass |
| [Pull Up Field](skills/refactoring/pull-up-field/) | Move identical fields to the superclass |
| [Pull Up Method](skills/refactoring/pull-up-method/) | Move identical methods to the superclass |
| [Push Down Field](skills/refactoring/push-down-field/) | Move a field to the subclass that uses it |
| [Push Down Method](skills/refactoring/push-down-method/) | Move a method to the subclass that uses it |
| [Remove Assignments to Parameters](skills/refactoring/remove-assignments-to-parameters/) | Use local variables instead of reassigning parameters |
| [Remove Control Flag](skills/refactoring/remove-control-flag/) | Replace control flags with break/return/continue |
| [Remove Middle Man](skills/refactoring/remove-middle-man/) | Let clients call the delegate directly |
| [Remove Parameter](skills/refactoring/remove-parameter/) | Remove unused method parameters |
| [Remove Setting Method](skills/refactoring/remove-setting-method/) | Remove setters for fields set only at creation |
| [Rename Method](skills/refactoring/rename-method/) | Give methods names that reveal their purpose |
| [Replace Array with Object](skills/refactoring/replace-array-with-object/) | Replace arrays used as data structures with objects |
| [Replace Conditional with Polymorphism](skills/refactoring/replace-conditional-with-polymorphism/) | Replace conditionals with polymorphic method calls |
| [Replace Constructor with Factory Method](skills/refactoring/replace-constructor-with-factory-method/) | Use factory methods for complex object creation |
| [Replace Data Value with Object](skills/refactoring/replace-data-value-with-object/) | Replace primitive data with a rich object |
| [Replace Delegation with Inheritance](skills/refactoring/replace-delegation-with-inheritance/) | Replace excessive delegation with inheritance |
| [Replace Error Code with Exception](skills/refactoring/replace-error-code-with-exception/) | Throw exceptions instead of returning error codes |
| [Replace Exception with Test](skills/refactoring/replace-exception-with-test/) | Check conditions before calling instead of catching |
| [Replace Inheritance with Delegation](skills/refactoring/replace-inheritance-with-delegation/) | Replace inheritance with composition |
| [Replace Magic Number with Symbolic Constant](skills/refactoring/replace-magic-number-with-symbolic-constant/) | Name magic numbers with constants |
| [Replace Method with Method Object](skills/refactoring/replace-method-with-method-object/) | Turn a complex method into its own class |
| [Replace Nested Conditional with Guard Clauses](skills/refactoring/replace-nested-conditional-with-guard-clauses/) | Flatten nested conditionals with early returns |
| [Replace Parameter with Explicit Methods](skills/refactoring/replace-parameter-with-explicit-methods/) | Create separate methods for each parameter value |
| [Replace Parameter with Method Call](skills/refactoring/replace-parameter-with-method-call/) | Compute values internally instead of passing them |
| [Replace Subclass with Fields](skills/refactoring/replace-subclass-with-fields/) | Replace subclasses that differ only in constants |
| [Replace Temp with Query](skills/refactoring/replace-temp-with-query/) | Replace temp variables with method calls |
| [Replace Type Code with Class](skills/refactoring/replace-type-code-with-class/) | Replace type codes with enums or classes |
| [Replace Type Code with State/Strategy](skills/refactoring/replace-type-code-with-state-strategy/) | Replace type codes affecting behavior with State/Strategy |
| [Replace Type Code with Subclasses](skills/refactoring/replace-type-code-with-subclasses/) | Replace type codes with a class hierarchy |
| [Self Encapsulate Field](skills/refactoring/self-encapsulate-field/) | Access fields through getters even within the class |
| [Separate Query from Modifier](skills/refactoring/separate-query-from-modifier/) | Split methods that both return values and change state |
| [Split Temporary Variable](skills/refactoring/split-temporary-variable/) | Use separate variables for separate purposes |
| [Substitute Algorithm](skills/refactoring/substitute-algorithm/) | Replace an algorithm with a clearer one |

**Code Smells (22)**

| Smell | Category | Description |
|-------|----------|-------------|
| [Long Method](skills/refactoring/long-method/) | Bloaters | Methods that have grown too long |
| [Large Class](skills/refactoring/large-class/) | Bloaters | Classes that try to do too much |
| [Primitive Obsession](skills/refactoring/primitive-obsession/) | Bloaters | Overuse of primitives instead of small objects |
| [Long Parameter List](skills/refactoring/long-parameter-list/) | Bloaters | Methods with too many parameters |
| [Data Clumps](skills/refactoring/data-clumps/) | Bloaters | Groups of data that appear together repeatedly |
| [Alternative Classes with Different Interfaces](skills/refactoring/alternative-classes-with-different-interfaces/) | OO Abusers | Similar classes with different method signatures |
| [Refused Bequest](skills/refactoring/refused-bequest/) | OO Abusers | Subclasses that don't use inherited behavior |
| [Switch Statements](skills/refactoring/switch-statements/) | OO Abusers | Complex switch/match that should be polymorphism |
| [Temporary Field](skills/refactoring/temporary-field/) | OO Abusers | Fields only set in certain circumstances |
| [Divergent Change](skills/refactoring/divergent-change/) | Change Preventers | One class changed for many different reasons |
| [Parallel Inheritance Hierarchies](skills/refactoring/parallel-inheritance-hierarchies/) | Change Preventers | Creating a subclass forces creating another |
| [Shotgun Surgery](skills/refactoring/shotgun-surgery/) | Change Preventers | One change requires edits in many classes |
| [Comments](skills/refactoring/comments/) | Dispensables | Excessive comments masking unclear code |
| [Duplicate Code](skills/refactoring/duplicate-code/) | Dispensables | Identical or very similar code in multiple places |
| [Data Class](skills/refactoring/data-class/) | Dispensables | Classes with only fields and getters/setters |
| [Dead Code](skills/refactoring/dead-code/) | Dispensables | Unreachable or unused code |
| [Lazy Class](skills/refactoring/lazy-class/) | Dispensables | Classes that do too little to justify their existence |
| [Speculative Generality](skills/refactoring/speculative-generality/) | Dispensables | Unused abstractions created "just in case" |
| [Feature Envy](skills/refactoring/feature-envy/) | Couplers | Methods that use another class's data more than their own |
| [Inappropriate Intimacy](skills/refactoring/inappropriate-intimacy/) | Couplers | Classes that access each other's internals |
| [Incomplete Library Class](skills/refactoring/incomplete-library-class/) | Couplers | Library classes that don't provide needed features |
| [Message Chains](skills/refactoring/message-chains/) | Couplers | Long chains of method calls (a.b().c().d()) |
| [Middle Man](skills/refactoring/middle-man/) | Couplers | Classes that only delegate to another class |

## Installation

Clone (or add as a submodule) and copy the skills you need into the location your tool expects.

```bash
git clone https://github.com/krzysztofsurdy/code-virtuoso.git
```

### Claude Code

**Via plugin marketplace (recommended):**

```bash
# Add the marketplace
/plugin marketplace add krzysztofsurdy/code-virtuoso

# Install a specific plugin
/plugin install symfony-virtuoso@krzysztofsurdy-code-virtuoso
/plugin install design-patterns-virtuoso@krzysztofsurdy-code-virtuoso
/plugin install refactoring-virtuoso@krzysztofsurdy-code-virtuoso
```

Or browse interactively: run `/plugin`, go to **Discover**, and install individual plugins.

**Manual install:**

```bash
# Project-level (committed to your repo)
cp -r code-virtuoso/skills/symfony/symfony-messenger .claude/skills/
cp -r code-virtuoso/skills/design-patterns/strategy .claude/skills/
cp -r code-virtuoso/skills/refactoring/extract-method .claude/skills/

# User-level (available in all projects)
cp -r code-virtuoso/skills/symfony/symfony-messenger ~/.claude/skills/
```

Skills are discovered automatically — just mention a component in conversation.

### OpenAI Codex CLI

```bash
# Project-level
cp -r code-virtuoso/skills/refactoring/extract-method .codex/skills/

# User-level
cp -r code-virtuoso/skills/design-patterns/strategy ~/.codex/skills/
```

### Gemini CLI

Gemini CLI uses `GEMINI.md` files for context. Append skill content to your project or user-level instructions:

```bash
# Project-level
cat code-virtuoso/skills/refactoring/extract-method/SKILL.md >> GEMINI.md

# User-level (all projects)
cat code-virtuoso/skills/design-patterns/strategy/SKILL.md >> ~/.gemini/GEMINI.md
```

### GitHub Copilot

Add skill content as scoped instruction files:

```bash
mkdir -p .github/instructions
cp code-virtuoso/skills/refactoring/extract-method/SKILL.md \
   .github/instructions/extract-method.instructions.md
```

Enable in VS Code: Settings > search "instruction file" > enable **Use Instruction Files**.

### Amp

```bash
# Project-level
cp -r code-virtuoso/skills/refactoring/extract-method .agents/skills/

# User-level
cp -r code-virtuoso/skills/design-patterns/strategy ~/.config/agents/skills/
```

### OpenCode

Copy skills or reference them in your project `AGENTS.md`:

```bash
# Project-level
cp -r code-virtuoso/skills/refactoring/extract-method .agents/skills/

# User-level
cp -r code-virtuoso/skills/refactoring/extract-method ~/.config/opencode/skills/
```

Or reference in `opencode.json`:

```json
{
  "instructions": ["code-virtuoso/skills/refactoring/extract-method/SKILL.md"]
}
```

### Kimi Code CLI

```bash
# Project-level (recommended)
cp -r code-virtuoso/skills/refactoring/extract-method .agents/skills/

# User-level (recommended)
cp -r code-virtuoso/skills/design-patterns/strategy ~/.config/agents/skills/
```

Kimi also discovers skills from `.kimi/skills/`, `.claude/skills/`, and `.codex/skills/`.

### Cursor

Convert a skill to a Cursor rule file:

```bash
mkdir -p .cursor/rules
cp code-virtuoso/skills/refactoring/extract-method/SKILL.md \
   .cursor/rules/extract-method.mdc
```

### Windsurf

```bash
mkdir -p .windsurf/rules
cp code-virtuoso/skills/refactoring/extract-method/SKILL.md \
   .windsurf/rules/extract-method.md
```

### Bulk install (all skills)

```bash
# Example: install all Symfony skills for Claude Code
cp -r code-virtuoso/skills/symfony/* .claude/skills/

# Example: install all design pattern skills
cp -r code-virtuoso/skills/design-patterns/* .claude/skills/

# Example: install all refactoring skills
cp -r code-virtuoso/skills/refactoring/* .claude/skills/

# Example: install everything for Amp / OpenCode / Kimi
cp -r code-virtuoso/skills/symfony/* .agents/skills/
cp -r code-virtuoso/skills/design-patterns/* .agents/skills/
cp -r code-virtuoso/skills/refactoring/* .agents/skills/
```

## Repository Structure

```
code-virtuoso/
├── skills/
│   ├── symfony/                # 38 Symfony component skills
│   │   └── symfony-<name>/
│   │       └── SKILL.md
│   ├── design-patterns/        # 26 design pattern skills
│   │   └── <pattern-name>/
│   │       └── SKILL.md
│   └── refactoring/            # 89 refactoring skills (67 techniques + 22 code smells)
│       └── <technique-name>/
│           └── SKILL.md
├── spec/
│   └── agent-skills-spec.md
├── template/
│   └── SKILL.md                # Template for new skills
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding or improving skills.

```bash
cp -r template skills/refactoring/<technique-name>
# Edit skills/refactoring/<technique-name>/SKILL.md
```

## License

MIT
