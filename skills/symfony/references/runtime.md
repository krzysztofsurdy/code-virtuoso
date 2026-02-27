# Symfony Runtime Component

## Installation

```bash
composer require symfony/runtime
```

## Core Concepts

The Runtime Component uses a 6-step execution model:

1. Main entry point returns a callable (the "app")
2. App callable passed to `RuntimeInterface::getResolver()` → returns `ResolverInterface`
3. App callable invoked with resolved arguments → returns application object
4. Application object passed to `RuntimeInterface::getRunner()` → returns `RunnerInterface`
5. `RunnerInterface::run()` called → returns exit status code
6. PHP terminates with status code

This decoupling enables applications to run on FPM, PHP-PM, ReactPHP, Swoole, FrankenPHP, and other runtimes without code changes.

## Basic HTTP Application

```php
// public/index.php
use App\Kernel;

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context): Kernel {
    return new Kernel($context['APP_ENV'], (bool) $context['APP_DEBUG']);
};
```

## Basic Console Application

```php
#!/usr/bin/env php
// bin/console
use App\Kernel;
use Symfony\Bundle\FrameworkBundle\Console\Application;

require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context): Application {
    $kernel = new Kernel($context['APP_ENV'], (bool) $context['APP_DEBUG']);
    return new Application($kernel);
};
```

## Runtime Selection

### Default Runtime: SymfonyRuntime
Optimized for FPM-based servers. Use for standard Symfony applications.

### Alternative: GenericRuntime
Uses PHP superglobals directly. Use for non-Symfony applications or custom runtimes.

### Configure in composer.json

```json
{
    "extra": {
        "runtime": {
            "class": "Symfony\\Component\\Runtime\\GenericRuntime"
        }
    }
}
```

### Custom Autoload Template

```json
{
    "extra": {
        "runtime": {
            "autoload_template": "resources/runtime/autoload_runtime.template"
        }
    }
}
```

## Resolvable Arguments

The closure can receive these arguments (type and name matter):

### Arguments Specific to SymfonyRuntime

| Argument | Type | Description |
|----------|------|-------------|
| Request | `Symfony\Component\HttpFoundation\Request` | Request created from globals |
| InputInterface | `Symfony\Component\Console\Input\InputInterface` | CLI input to read options/arguments |
| OutputInterface | `Symfony\Component\Console\Output\OutputInterface` | Console output with styling |
| Application | `Symfony\Component\Console\Application` | Console application builder |
| Command | `Symfony\Component\Console\Command\Command` | Single command CLI application |

### Arguments Supported by Both Runtimes

| Argument | Type | Description |
|----------|------|-------------|
| context | `array` | $_SERVER + $_ENV combined |
| argv | `array` | Command arguments ($_SERVER['argv']) |
| request | `array` | Keys: query, body, files, session |

### Example Usage

```php
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Console\Output\OutputInterface;

return function (Request $request, OutputInterface $output): Kernel {
    // Access $request and $output
};
```

## Resolvable Applications

### Symfony HttpKernelInterface
Standard Symfony application:

```php
return static function (): Kernel {
    return new Kernel('prod', false);
};
```

### Symfony Response
Direct HTTP response:

```php
use Symfony\Component\HttpFoundation\Response;

return static function (): Response {
    return new Response('Hello world');
};
```

### Single Command CLI
Command-based CLI application:

```php
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

return static function (Command $command): Command {
    $command->setCode(static function (InputInterface $input, OutputInterface $output): void {
        $output->write('Hello World');
    });
    return $command;
};
```

### Multi-Command Console Application
Complete console application:

```php
use Symfony\Component\Console\Application;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

return static function (array $context): Application {
    $command = new Command('hello');
    $command->setCode(static function (InputInterface $input, OutputInterface $output): void {
        $output->write('Hello World');
    });

    $app = new Application();
    $app->add($command);
    $app->setDefaultCommand('hello', true);

    return $app;
};
```

### Custom RunnerInterface
Implement custom application runner:

```php
use Symfony\Component\Runtime\RunnerInterface;

return static function (): RunnerInterface {
    return new class implements RunnerInterface {
        public function run(): int {
            echo 'Hello World';
            return 0;
        }
    };
};
```

### Callable
Function-based application:

```php
return static function (): callable {
    return static function(): int {
        echo 'Hello World';
        return 0;
    };
};
```

### Void
No return value:

```php
return function (): void {
    echo 'Hello world';
};
```

## Runtime Options Configuration

Set options via environment variable or composer.json.

### Via Environment Variable

```php
$_SERVER['APP_RUNTIME_OPTIONS'] = [
    'project_dir' => '/var/task',
];
// or JSON format:
$_SERVER['APP_RUNTIME_OPTIONS'] = '{"project_dir":"\/var\/task"}';
```

### Via composer.json

```json
{
    "extra": {
        "runtime": {
            "project_dir": "/var/task"
        }
    }
}
```

## SymfonyRuntime Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `env` | APP_ENV or "dev" | Runtime environment name |
| `disable_dotenv` | false | Disable .env file loading |
| `dotenv_path` | .env | Path to .env files |
| `dotenv_overload` | false | Override with .env.local |
| `use_putenv` | - | Use putenv() for env variables |
| `prod_envs` | ["prod"] | Production environment names |
| `test_envs` | ["test"] | Test environment names |

## Generic & SymfonyRuntime Shared Options

| Option | Default | Description |
|--------|---------|-------------|
| `debug` | APP_DEBUG or true | Debug mode toggle |
| `runtimes` | - | Map application types to Runtime classes |
| `error_handler` | BasicErrorHandler or SymfonyErrorHandler | PHP error handler class |
| `env_var_name` | "APP_ENV" | Environment variable name |
| `debug_var_name` | "APP_DEBUG" | Debug flag variable name |

## Creating Custom Runtimes

### Step 1: Create a Custom Runner

Implement `RunnerInterface` for your specific runtime:

```php
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\RequestHandlerInterface;
use React\EventLoop\Factory as ReactFactory;
use React\Http\Server as ReactHttpServer;
use React\Socket\Server as ReactSocketServer;
use Symfony\Component\Runtime\RunnerInterface;

class ReactPHPRunner implements RunnerInterface
{
    public function __construct(
        private RequestHandlerInterface $application,
        private int $port,
    ) {
    }

    public function run(): int
    {
        $application = $this->application;
        $loop = ReactFactory::create();

        $server = new ReactHttpServer(
            $loop,
            function (ServerRequestInterface $request) use ($application): ResponseInterface {
                return $application->handle($request);
            }
        );

        $socket = new ReactSocketServer($this->port, $loop);
        $server->listen($socket);

        $loop->run();

        return 0;
    }
}
```

### Step 2: Extend GenericRuntime

Create a custom Runtime class that uses your runner:

```php
use Symfony\Component\Runtime\GenericRuntime;
use Symfony\Component\Runtime\RunnerInterface;
use Psr\Http\Server\RequestHandlerInterface;

class ReactPHPRuntime extends GenericRuntime
{
    private int $port;

    public function __construct(array $options)
    {
        $this->port = $options['port'] ?? 8080;
        parent::__construct($options);
    }

    public function getRunner(?object $application): RunnerInterface
    {
        if ($application instanceof RequestHandlerInterface) {
            return new ReactPHPRunner($application, $this->port);
        }

        return parent::getRunner($application);
    }
}
```

### Step 3: Use in Application

```php
require_once dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context): SomeCustomPsr15Application {
    return new SomeCustomPsr15Application();
};
```

### Step 4: Configure in composer.json

```json
{
    "extra": {
        "runtime": {
            "class": "Your\\Custom\\ReactPHPRuntime",
            "port": 8080
        }
    }
}
```

## Key Interfaces

### RuntimeInterface
Defines the contract for runtime implementations:
- `getResolver()` - Returns `ResolverInterface` for argument resolution
- `getRunner()` - Returns `RunnerInterface` to execute the application

### ResolverInterface
Resolves callable arguments based on type hints and parameter names:
- Examines function/method signatures
- Provides appropriate values for dependencies
- Handles type coercion and validation

### RunnerInterface
Executes the application:
- `run(): int` - Execute application and return exit code

### HttpKernelInterface
Symfony HTTP kernel contract:
- Handles HTTP requests
- Returns Response objects

### RequestHandlerInterface
PSR-15 HTTP request handler contract:
- `handle(ServerRequestInterface $request): ResponseInterface`

## Common Use Cases

### Deploy to FrankenPHP
Use SymfonyRuntime with FrankenPHP for automatic request handling:
```bash
frankenphp run -a 127.0.0.1:8080 public/index.php
```

### Deploy to Swoole
Extend GenericRuntime to integrate with Swoole's async capabilities.

### Deploy to ReactPHP
Use the ReactPHP custom runtime example above to run with ReactPHP.

### Deploy to PHP-PM
SymfonyRuntime is compatible with PHP-PM's process manager.

## Best Practices

- Return a callable from your entry point script
- Use type hints for argument resolution
- Handle APP_ENV and APP_DEBUG consistently
- Load .env files in development via SymfonyRuntime
- Implement proper error handlers for production
- Test with different runtimes to ensure compatibility
- Use `composer install --no-dev` in production
- Configure appropriate `prod_envs` and `test_envs`
