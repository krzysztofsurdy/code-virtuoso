# Symfony Console Component

## Core Application Setup

Create a standalone console application:

```php
#!/usr/bin/env php
<?php
require __DIR__.'/vendor/autoload.php';

use Symfony\Component\Console\Application;

$application = new Application('My App', '1.0.0');
$application->addCommand(new MyCommand());
$application->run();
```

For single-command applications, use `SingleCommandApplication`:

```php
use Symfony\Component\Console\SingleCommandApplication;
use Symfony\Component\Console\Attribute\Argument;
use Symfony\Component\Console\Output\OutputInterface;

(new SingleCommandApplication())
    ->setName('My Super Command')
    ->setCode(function (OutputInterface $output, #[Argument] string $foo = ''): int {
        $output->writeln($foo);
        return 0;
    })
    ->run();
```

Alternatively, set a default command: `$application->setDefaultCommand($command->getName(), true);`

## Creating Commands

Use the `#[AsCommand]` attribute to define commands:

```php
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Attribute\Argument;
use Symfony\Component\Console\Attribute\Option;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:create-user',
    description: 'Creates a new user',
    help: 'Detailed help text',
)]
class CreateUserCommand extends Command
{
    public function __invoke(
        #[Argument('The username')] string $username,
        #[Option('admin', 'a', description: 'Admin user')] bool $isAdmin = false,
        SymfonyStyle $io
    ): int {
        $io->success("User {$username} created!");
        return Command::SUCCESS;
    }
}
```

Define command aliases using pipe separators: `name: 'app:create-user|app:add-user'`

### Command Lifecycle

1. **initialize()** - Optional: initialize variables
2. **interact()** - Optional: ask for missing arguments/options
3. **__invoke() or execute()** - Required: main logic

## Input Handling

### Arguments

Required and optional arguments are inferred from PHP types and default values:

```php
public function __invoke(
    #[Argument] string $name,                    // Required
    #[Argument] string $lastName = '',           // Optional (default value)
    #[Argument] array $names = []                // Array of values
): int { }
```

In classic commands:

```php
$this->addArgument('name', InputArgument::REQUIRED, 'Description')
     ->addArgument('lastName', InputArgument::OPTIONAL, 'Description', 'default');
```

Access: `$input->getArgument('name')`

### Options

Boolean flags, value-required options, and arrays are inferred from type declarations:

```php
public function __invoke(
    #[Option] bool $yell = false,               // Boolean flag (--yell)
    #[Option] int $iterations = 1,              // Value required (--iterations=5)
    #[Option] string|bool $format = false       // Optional value
): int { }
```

In classic commands:

```php
$this->addOption('yell', 'y', InputOption::VALUE_NONE, 'Description')
     ->addOption('iterations', 'i', InputOption::VALUE_REQUIRED, 'Description', 1);
```

Access: `$input->getOption('yell')`

### Input Mapping with DTOs

Group arguments and options using the `#[MapInput]` attribute:

```php
class CreateUserInput {
    #[Argument] public string $email;
    #[Option] public bool $admin = false;
}

public function __invoke(#[MapInput] CreateUserInput $input): int { }
```

### Value Completion

Add autocomplete suggestions:

```php
#[Argument(suggestedValues: ['Alice', 'Bob', 'Charlie'])]
string $name,

#[Option(suggestedValues: [self::class, 'suggestFormats'])]
string $format = 'json',

public static function suggestFormats(CompletionInput $input): array {
    return ['json', 'xml', 'csv'];
}
```

## Output Handling

### Basic Output

```php
$output->write('No newline');              // No newline
$output->writeln('With newline');          // With newline
$output->writeln(['Line 1', 'Line 2']);    // Multiple lines
```

### Output Sections

Create independent console regions for parallel output:

```php
$section = $output->section();
$section->writeln('Content');
$section->overwrite('New content');  // Replace content
$section->clear();                   // Clear section
```

### Styling with SymfonyStyle

Use semantic helper methods instead of manual formatting:

```php
use Symfony\Component\Console\Style\SymfonyStyle;

$io = new SymfonyStyle($input, $output);

$io->title('Command Title');
$io->section('Section Heading');
$io->text('Regular text');
$io->listing(['item 1', 'item 2']);
$io->note('Important note');
$io->caution('Warning');
$io->success('Success message');
$io->warning('Warning message');
$io->error('Error message');
```

### Color & Format Tags

```php
$output->writeln('<info>green text</info>');
$output->writeln('<comment>yellow text</comment>');
$output->writeln('<question>cyan background</question>');
$output->writeln('<error>red background</error>');
$output->writeln('<href=https://symfony.com>Clickable link</>');
```

Custom styles:

```php
use Symfony\Component\Console\Formatter\OutputFormatterStyle;

$style = new OutputFormatterStyle('red', '#ff0', ['bold', 'blink']);
$output->getFormatter()->setStyle('fire', $style);
$output->writeln('<fire>text</>');
```

## Console Helpers

### Table Helper

```php
use Symfony\Component\Console\Helper\Table;
use Symfony\Component\Console\Helper\TableSeparator;
use Symfony\Component\Console\Helper\TableCell;
use Symfony\Component\Console\Helper\TableCellStyle;

$table = new Table($output);
$table->setHeaders(['ISBN', 'Title', 'Author'])
      ->setRows([
          ['99921-58-10-7', 'Divine Comedy', 'Dante Alighieri'],
          new TableSeparator(),
          ['960-425-059-0', 'The Lord of the Rings', 'Tolkien'],
      ]);

// Styling
$table->setStyle('box');  // default, compact, borderless, box, box-double
$table->setColumnWidths([10, 0, 30]);  // 0 = auto
$table->setHeaderTitle('Books');
$table->setFooterTitle('Page 1/2');

// Cell styling
$table->setRows([
    [
        '978-0804169127',
        new TableCell('Divine Comedy', [
            'style' => new TableCellStyle(['align' => 'center', 'fg' => 'red'])
        ])
    ]
]);

// Colspan/Rowspan
new TableCell('Spans 3 columns', ['colspan' => 3])
new TableCell('Spans 2 rows', ['rowspan' => 2])

$table->render();
```

### Progress Bar Helper

```php
use Symfony\Component\Console\Helper\ProgressBar;

$progressBar = new ProgressBar($output, 50);
$progressBar->start();

while ($i++ < 50) {
    // ... work
    $progressBar->advance();           // Advance 1 step
    $progressBar->advance(5);          // Advance multiple
}
$progressBar->finish();

// Using with iterables
$progressBar = new ProgressBar($output);
foreach ($progressBar->iterate($items) as $item) {
    // ... work
}

// Customization
$progressBar->setBarCharacter('=');
$progressBar->setEmptyBarCharacter(' ');
$progressBar->setProgressCharacter('|');
$progressBar->setBarWidth(50);
$progressBar->setFormat(' %current%/%max% [%bar%] %percent:3s%% %elapsed%/%estimated%');
$progressBar->setRedrawFrequency(100);
```

Format placeholders: `current`, `max`, `bar`, `percent`, `elapsed`, `remaining`, `estimated`, `memory`, `message`

### Question Helper

```php
use Symfony\Component\Console\Question\Question;
use Symfony\Component\Console\Question\ConfirmationQuestion;
use Symfony\Component\Console\Question\ChoiceQuestion;

$helper = $this->getHelper('question');

// Simple question with default
$question = new Question('Bundle name', 'AcmeDemoBundle');
$answer = $helper->ask($input, $output, $question);

// Confirmation
$question = new ConfirmationQuestion('Continue?', false);
if (!$helper->ask($input, $output, $question)) return;

// Choice question
$question = new ChoiceQuestion('Favorite color', ['red', 'blue', 'yellow'], 0);
$question->setErrorMessage('Invalid color %s');
$color = $helper->ask($input, $output, $question);

// Multiple selections
$question->setMultiselect(true);
$colors = $helper->ask($input, $output, $question);  // Returns array

// Autocompletion
$question->setAutocompleterValues(['bundle1', 'bundle2']);

// Dynamic autocompletion
$question->setAutocompleterCallback(function ($input) {
    return scandir($input);
});

// Validation & normalization
$question->setValidator(function ($answer) {
    if (!str_ends_with($answer, 'Bundle')) {
        throw new \RuntimeException('Must end with Bundle');
    }
    return $answer;
});
$question->setNormalizer(fn($value) => trim($value));
$question->setMaxAttempts(2);

// Hidden input (passwords)
$question->setHidden(true);
$question->setHiddenFallback(false);

// Multiline input
$question->setMultiline(true);
```

### SymfonyStyle Helpers

```php
$io = new SymfonyStyle($input, $output);

// Tables
$io->table(['Header 1', 'Header 2'], [['Cell 1', 'Cell 2']]);

// Definition lists
$io->definitionList(['Item' => 'Description']);

// Trees
$io->tree($treeNode);

// User input
$io->ask('Question', 'default');
$io->askHidden('Password');
$io->confirm('Confirm?');
$io->choice('Choose', ['option1', 'option2']);

// Progress
$io->progressStart(100);
$io->progressAdvance();
$io->progressFinish();
$io->progressIterate($items);  // Loop with progress
```

## Dependency Injection & Service Definition

Commands support dependency injection automatically in Symfony:

```php
#[AsCommand(name: 'app:create-user')]
class CreateUserCommand
{
    public function __construct(private UserManager $userManager) {}

    public function __invoke(#[Argument] string $username): int
    {
        $this->userManager->create($username);
        return Command::SUCCESS;
    }
}
```

For manual registration, tag with `console.command`:

```yaml
services:
    App\Command\MyCommand:
        tags:
            - { name: 'console.command', command: 'app:my-command' }
```

## Verbosity Levels

Control output based on verbosity flags:

```php
// Constants
OutputInterface::VERBOSITY_QUIET       // -q
OutputInterface::VERBOSITY_NORMAL      // (default)
OutputInterface::VERBOSITY_VERBOSE     // -v
OutputInterface::VERBOSITY_VERY_VERBOSE // -vv
OutputInterface::VERBOSITY_DEBUG       // -vvv

// Check verbosity
if ($output->isVerbose()) { }
if ($output->isVeryVerbose()) { }
if ($output->isDebug()) { }

// Output at specific verbosity
$output->writeln('Debug info', OutputInterface::VERBOSITY_VERBOSE);

// Environment variable control
SHELL_VERBOSITY=2 php bin/console command
```

## Events

Listen to console lifecycle events:

```php
use Symfony\Component\Console\ConsoleEvents;
use Symfony\Component\Console\Event\ConsoleCommandEvent;
use Symfony\Component\Console\Event\ConsoleErrorEvent;
use Symfony\Component\Console\Event\ConsoleTerminateEvent;
use Symfony\Component\Console\Event\ConsoleSignalEvent;
use Symfony\Component\EventDispatcher\EventDispatcher;

$dispatcher = new EventDispatcher();
$application->setDispatcher($dispatcher);

// Before command execution
$dispatcher->addListener(ConsoleEvents::COMMAND, function (ConsoleCommandEvent $event) {
    $event->disableCommand();  // Prevent execution
});

// Handle errors
$dispatcher->addListener(ConsoleEvents::ERROR, function (ConsoleErrorEvent $event) {
    $event->setError(new \LogicException('Custom error', $event->getExitCode()));
});

// After command execution
$dispatcher->addListener(ConsoleEvents::TERMINATE, function (ConsoleTerminateEvent $event) {
    $event->setExitCode(128);  // Change exit code
});

// Handle signals (Ctrl+C)
$dispatcher->addListener(ConsoleEvents::SIGNAL, function (ConsoleSignalEvent $event) {
    if ($event->getHandlingSignal() === \SIGINT) {
        echo "Cleanup...";
    }
    $event->setExitCode(0);
});
```

In-command signal handling:

```php
#[AsCommand(name: 'app:my-command')]
class MyCommand
{
    #[AsEventListener(ConsoleSignalEvent::class)]
    public function handleSignal(ConsoleSignalEvent $event): void
    {
        if (in_array($event->getHandlingSignal(), [\SIGINT, \SIGTERM])) {
            // Cleanup
        }
    }
}
```

## Calling Other Commands

Call commands from within commands:

```php
use Symfony\Component\Console\Application;
use Symfony\Component\Console\Input\ArrayInput;

public function __invoke(OutputInterface $output, Application $app): int
{
    $input = new ArrayInput([
        'command' => 'demo:greet',
        'name'    => 'Fabien',
        '--yell'  => true,
    ]);
    $input->setInteractive(false);

    $returnCode = $app->doRun($input, $output);
    return $returnCode;
}
```

Use `doRun()` instead of `run()` to prevent auto-exit and properly dispatch events.

## Lazy Command Loading

Defer command instantiation until invoked:

```php
use Symfony\Component\Console\CommandLoader\FactoryCommandLoader;

$commandLoader = new FactoryCommandLoader([
    'app:heavy' => fn() => new HeavyCommand(),
    'app:foo'   => [FooCommand::class, 'create'],
]);

$application->setCommandLoader($commandLoader);
```

Or load from container:

```php
use Symfony\Component\Console\CommandLoader\ContainerCommandLoader;

$commandLoader = new ContainerCommandLoader($container, [
    'app:foo' => FooCommand::class,
]);
$application->setCommandLoader($commandLoader);
```

## Testing Commands

```php
use Symfony\Component\Console\Tester\CommandTester;

$command = new MyCommand();
$tester = new CommandTester($command);

// Execute with arguments
$tester->execute(['username' => 'John', '--admin' => true]);

// Assertions
$tester->assertCommandIsSuccessful();
$tester->assertCommandStatusCode(0);

// Check output
$output = $tester->getDisplay();
$this->assertStringContainsString('User created', $output);

// Simulate user input
$tester->setInputs(['yes', 'option1']);
```

## Key Return Codes

- `Command::SUCCESS` (0) - Success
- `Command::FAILURE` (1) - General failure
- `Command::INVALID` (2) - Invalid command usage
- Exit code 113 - Command disabled via event
- Exit code 128 - Signal terminated
