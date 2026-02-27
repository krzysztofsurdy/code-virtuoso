# Symfony Process Component

## Overview

The Process component executes external commands and system processes in sub-processes, providing a secure and flexible alternative to PHP's built-in functions like `exec()`, `passthru()`, `shell_exec()`, and `system()`. It handles cross-platform OS differences automatically and prevents security vulnerabilities through proper argument escaping.

## Installation

```bash
composer require symfony/process
```

## Core Classes and Interfaces

### Process Class

Main class for executing commands.

```php
use Symfony\Component\Process\Process;

$process = new Process(['command', 'arg1', 'arg2']);
$process = new Process(['command', 'arg1', 'arg2'], '/working/dir');
$process = new Process(['command'], null, ['ENV_VAR' => 'value']);
```

### PhpProcess Class

Execute PHP code in an isolated process.

```php
use Symfony\Component\Process\PhpProcess;

$process = new PhpProcess('<?= "Hello World" ?>');
$process->run();
```

### PhpSubprocess Class

Execute PHP scripts as child processes with inherited configuration.

```php
use Symfony\Component\Process\PhpSubprocess;

$process = new PhpSubprocess(['bin/console', 'cache:clear']);
$process->run();
```

### ProcessBuilder Class

Fluent interface for building processes.

```php
use Symfony\Component\Process\ProcessBuilder;

$process = (new ProcessBuilder())
    ->setPrefix('php')
    ->add('script.php')
    ->getProcess();
```

### Finders

**ExecutableFinder** - Locate executables on the system.

```php
use Symfony\Component\Process\ExecutableFinder;

$finder = new ExecutableFinder();
$path = $finder->find('chromedriver');
$path = $finder->find('phantomjs');
```

**PhpExecutableFinder** - Locate PHP executable.

```php
use Symfony\Component\Process\PhpExecutableFinder;

$finder = new PhpExecutableFinder();
$phpPath = $finder->find();
```

### InputStream Class

Handle standard input for interactive processes.

```php
use Symfony\Component\Process\InputStream;

$input = new InputStream();
$input->write('data');
$input->close();

$process = new Process(['cat']);
$process->setInput($input);
$process->start();
```

### ProcessFailedException

Exception thrown when process fails.

```php
use Symfony\Component\Process\Exception\ProcessFailedException;

try {
    $process->mustRun();
} catch (ProcessFailedException $e) {
    echo $e->getMessage();
}
```

## Execution Methods

### run()

Execute process synchronously and wait for completion.

```php
$process = new Process(['ls', '-lsa']);
$process->run();

if (!$process->isSuccessful()) {
    throw new ProcessFailedException($process);
}

echo $process->getOutput();
```

With callback for real-time output:

```php
$process->run(function ($type, $buffer): void {
    if (Process::ERR === $type) {
        echo 'ERR > ' . $buffer;
    } else {
        echo 'OUT > ' . $buffer;
    }
});
```

### mustRun()

Execute process and throw exception on failure.

```php
$process = new Process(['deploy.sh']);
$process->mustRun();

echo $process->getOutput();
```

### start()

Start process asynchronously without waiting.

```php
$process = new Process(['long-running-command']);
$process->start();

// Do other work...

while ($process->isRunning()) {
    sleep(1);
}

echo $process->getOutput();
```

### wait()

Block until process completes.

```php
$process->start();
$exitCode = $process->wait();
```

### waitUntil()

Block until condition is met or process completes.

```php
$process->start();

$process->waitUntil(function ($type, $output): bool {
    return strpos($output, 'Ready') !== false;
});

// Process emitted "Ready", continue execution
```

## Output Management

### getOutput()

Retrieve complete standard output.

```php
echo $process->getOutput();
```

### getErrorOutput()

Retrieve complete error output.

```php
echo $process->getErrorOutput();
```

### getIncrementalOutput()

Get output since last call (clear the buffer).

```php
$process->start();

while ($process->isRunning()) {
    $output = $process->getIncrementalOutput();
    if ($output) {
        echo $output;
    }
    usleep(100000);
}
```

### getIncrementalErrorOutput()

Get error output since last call (clear the buffer).

```php
$output = $process->getIncrementalErrorOutput();
```

### disableOutput()

Disable output capture to save memory for long-running processes.

```php
$process = new Process(['generate-large-file.sh']);
$process->disableOutput();
$process->run();
```

### enableOutput()

Re-enable output capture.

```php
$process->enableOutput();
```

### isOutputDisabled()

Check if output capture is disabled.

```php
if ($process->isOutputDisabled()) {
    // ...
}
```

### Iterator Interface

Iterate through process output as it streams.

```php
$process = new Process(['ls', '-lsa']);
$process->start();

foreach ($process as $type => $data) {
    if ($process::OUT === $type) {
        echo "Out: " . $data;
    } elseif ($process::ERR === $type) {
        echo "Err: " . $data;
    }
}
```

## Input/Environment Management

### setInput()

Set standard input (string or InputStream).

```php
$process = new Process(['cat']);
$process->setInput('Hello World');
$process->run();

echo $process->getOutput(); // "Hello World"
```

With InputStream for interactive input:

```php
$input = new InputStream();
$process = new Process(['cat']);
$process->setInput($input);
$process->start();

$input->write('First line');
$input->write("\n");
$input->write('Second line');
$input->close();
```

### getInput()

Retrieve the current input.

```php
$input = $process->getInput();
```

### setEnv()

Set environment variables for the process.

```php
$process->setEnv(['FOO' => 'bar', 'CUSTOM_VAR' => 'value']);
```

Disable inherited environment variables:

```php
$process->setEnv(['FOO' => 'bar']); // Only FOO is available
```

### getEnv()

Retrieve environment variables.

```php
$env = $process->getEnv();
```

### inheritEnvironmentVariables()

Inherit parent process environment variables.

```php
$process->inheritEnvironmentVariables();
```

Disable specific inherited variables:

```php
$process->setEnv([
    'APP_ENV' => false,
    'SYMFONY_DOTENV_VARS' => false,
]);
```

## Timeout and Duration Control

### setTimeout()

Set total execution timeout in seconds.

```php
$process->setTimeout(3600); // 1 hour
$process->setTimeout(null); // Disable timeout
```

### setIdleTimeout()

Set timeout for no output (idle timeout) in seconds.

```php
$process->setIdleTimeout(60); // Stop if no output for 60 seconds
```

### getTimeout()

Retrieve timeout value.

```php
$timeout = $process->getTimeout();
```

### getIdleTimeout()

Retrieve idle timeout value.

```php
$idleTimeout = $process->getIdleTimeout();
```

### getLastOutputTime()

Get Unix timestamp of last output.

```php
$lastTime = $process->getLastOutputTime();
```

## Process Control and Status

### getPid()

Get process ID.

```php
$process->start();
$pid = $process->getPid();

echo "Process ID: " . $pid;
```

### isRunning()

Check if process is currently running.

```php
if ($process->isRunning()) {
    echo "Process is running";
}
```

### isSuccessful()

Check if process completed with exit code 0.

```php
$process->run();

if ($process->isSuccessful()) {
    echo "Success";
} else {
    echo "Failed with exit code: " . $process->getExitCode();
}
```

### getExitCode()

Get process exit code.

```php
$exitCode = $process->getExitCode();

if ($exitCode === 0) {
    echo "Success";
}
```

### getExitCodeText()

Get human-readable exit code text.

```php
echo $process->getExitCodeText();
```

### stop()

Stop a running process with optional timeout and signal.

```php
$process->start();

// Stop gracefully (SIGTERM), then force kill after 3 seconds
$process->stop(3, SIGTERM);
```

### signal()

Send a signal to the process (POSIX only).

```php
$process->start();
$process->signal(SIGINT);   // Interrupt
$process->signal(SIGKILL);  // Force kill
$process->signal(SIGUSR1);  // User-defined signal
```

### setIgnoredSignals()

Set signals that the process should ignore.

```php
$process->setIgnoredSignals([SIGKILL, SIGUSR1]);
```

## Terminal and TTY Modes

### setTty()

Enable TTY mode for interactive programs (Vim, Nano, etc.).

```php
$process = new Process(['vim', 'file.txt']);
$process->setTty(true);
$process->run();
```

### isTty()

Check if TTY mode is enabled.

```php
if ($process->isTty()) {
    echo "TTY mode enabled";
}
```

### setPty()

Enable pseudo-terminal (PTY) mode.

```php
$process->setPty(true);
```

### isPty()

Check if PTY mode is enabled.

```php
if ($process->isPty()) {
    echo "PTY mode enabled";
}
```

### isTtySupported()

Check if TTY is supported on current system.

```php
if (Process::isTtySupported()) {
    $process->setTty(true);
}
```

## Shell Command Execution

### fromShellCommandline()

Create process from shell command string with variable interpolation.

```php
use Symfony\Component\Process\Process;

$process = Process::fromShellCommandline('echo "$MESSAGE"');
$process->run(null, ['MESSAGE' => 'Hello World']);

echo $process->getOutput(); // "Hello World"
```

Portable syntax (all operating systems):

```php
$process = Process::fromShellCommandline('echo "${:MESSAGE}"');
$process->run(null, ['MESSAGE' => 'Hello']);
```

## Platform-Specific Options

### setOptions()

Set platform-specific options.

```php
$process->setOptions([
    'create_new_console' => true, // Windows: create new console window
]);
```

## Working Directory

Set working directory for process execution.

```php
$process = new Process(['composer', 'install'], '/path/to/project');
$process->run();
```

Change working directory:

```php
$process->setWorkingDirectory('/path/to/project');
```

Get working directory:

```php
$dir = $process->getWorkingDirectory();
```

## Common Use Cases

### Execute Git Command

```php
$process = new Process(['git', 'status']);
$process->setWorkingDirectory('/path/to/repo');
$process->run();

echo $process->getOutput();
```

### Run Composer

```php
$process = new Process(['composer', 'install', '--no-dev']);
$process->run();
```

### Database Migration with Timeout

```php
$process = new Process(['php', 'bin/console', 'doctrine:migrations:migrate']);
$process->setTimeout(300); // 5 minutes
$process->mustRun();
```

### Background Task with Output Streaming

```php
$process = new Process(['php', 'bin/console', 'process:emails']);
$process->start();

while ($process->isRunning()) {
    $output = $process->getIncrementalOutput();
    if ($output) {
        echo $output;
    }
    usleep(100000);
}
```

### Concurrent Process Management

```php
$processes = [
    new Process(['composer', 'install']),
    new Process(['npm', 'install']),
    new Process(['mix']),
];

foreach ($processes as $process) {
    $process->start();
}

foreach ($processes as $process) {
    $process->wait();
    if (!$process->isSuccessful()) {
        throw new ProcessFailedException($process);
    }
}
```

### Secure Command Execution with Arguments

```php
// Arguments are automatically escaped
$process = new Process([
    'mysqldump',
    '-u', $username,
    '-p' . $password,
    '--databases', $database,
]);

// No injection risk - arguments are properly quoted
$process->run();
```

## Error Handling

```php
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Exception\ProcessTimedOutException;
use Symfony\Component\Process\Exception\ProcessSignaledException;

try {
    $process = new Process(['failing-command']);
    $process->mustRun();
} catch (ProcessTimedOutException $e) {
    echo "Process timed out: " . $e->getMessage();
} catch (ProcessSignaledException $e) {
    echo "Process signaled: " . $e->getMessage();
} catch (ProcessFailedException $e) {
    echo "Process failed: " . $e->getProcess()->getExitCode();
    echo $e->getProcess()->getErrorOutput();
}
```

## Key Features Summary

- **Secure argument handling** - Prevents command injection
- **Real-time output** - Stream output as process runs
- **Asynchronous execution** - Non-blocking process start
- **Timeout control** - Total and idle timeout support
- **Signal handling** - POSIX signals (SIGTERM, SIGKILL, etc.)
- **TTY/PTY modes** - Interactive program support
- **Environment variables** - Set and inherit environment
- **Cross-platform** - Windows, Linux, macOS support
- **Memory efficient** - Optional output disabling
- **Standard input** - Support for interactive input streams
