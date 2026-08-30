# Verification Checklist by Task Type

Step-by-step checklists for verifying work by type of change. Every item requires captured output, not a mental check.

---

## Contents

- [Code change](#code-change)
- [Configuration change](#configuration-change)
- [Database / schema change](#database--schema-change)
- [Infrastructure change](#infrastructure-change)
- [Documentation change](#documentation-change)
- [Dependency update](#dependency-update)

## Code change

Any modification to source code: new features, refactors, bug fixes, performance improvements.

### Required checks

1. **Run the full test suite**
   ```
   npm test
   pytest
   go test ./...
   cargo test
   dotnet test
   bundle exec rspec
   php vendor/bin/phpunit
   ./gradlew test
   ```
   - Expected: all tests pass, zero failures, zero errors
   - Capture: test count, pass count, fail count, exit code

2. **Run the linter**
   ```
   eslint .
   ruff check .
   golangci-lint run
   cargo clippy
   dotnet format --verify-no-changes
   rubocop
   php vendor/bin/phpcs
   ```
   - Expected: zero errors (zero warnings for strict projects)
   - Capture: error count, warning count, exit code

3. **Run the type checker** (statically typed or gradually typed languages)
   ```
   tsc --noEmit
   mypy .
   pyright
   phpstan analyse
   ```
   - Expected: zero type errors
   - Capture: error count, exit code

4. **Run the build**
   ```
   npm run build
   go build ./...
   cargo build
   dotnet build
   ./gradlew build
   ```
   - Expected: build succeeds, exit code 0, expected artifacts produced
   - Capture: exit code, artifact paths or summary

5. **Verify no unintended changes**
   ```
   git diff --stat
   git status
   ```
   - Expected: only intended files are modified
   - Capture: list of changed files, any untracked files

### Bug fix extras

When the code change is a bug fix, add these checks:

6. **Red-green verification**: confirm the test fails WITHOUT the fix
   - Revert only the fix (keep the test)
   - Run the specific test (it must FAIL)
   - Restore the fix
   - Run the specific test (it must PASS)
   - This proves the test actually catches the bug

7. **Regression suite**: run the full suite to confirm nothing else broke

---

## Configuration change

Any modification to config files: environment variables, feature flags, service configuration, build config.

### Required checks

1. **Validate config syntax**
   ```
   python -m json.tool config.json
   yamllint config.yaml
   dotenv-linter .env
   nginx -t
   apachectl configtest
   ```
   - Expected: valid syntax, exit code 0
   - Capture: validation output, exit code

2. **Application startup**: restart the application with the new config
   ```
   npm run dev
   python manage.py runserver
   go run .
   rails server
   ```
   - Expected: application starts without errors
   - Capture: startup logs showing successful initialization

3. **Smoke test affected feature**: exercise the specific feature the config change targets
   ```
   curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health
   curl -s http://localhost:8080/api/affected-endpoint | head -20
   ```
   - Expected: feature responds correctly with new config
   - Capture: HTTP status, response body or relevant excerpt

4. **Verify config is loaded**: confirm the application is using the new values
   - Check application logs for config loading messages
   - Hit a debug or diagnostic endpoint if available
   - Confirm the behavioral change is visible

---

## Database / schema change

Any modification to database schema: migrations, seed data, index changes, constraint modifications.

### Required checks

1. **Migration runs forward**
   ```
   rails db:migrate
   python manage.py migrate
   php bin/console doctrine:migrations:migrate
   npx prisma migrate deploy
   flyway migrate
   ```
   - Expected: migration applies without error, exit code 0
   - Capture: migration output, applied version, exit code

2. **Migration rolls back**
   ```
   rails db:rollback STEP=1
   python manage.py migrate app_name previous_migration
   php bin/console doctrine:migrations:migrate prev
   npx prisma migrate reset
   flyway undo
   ```
   - Expected: rollback completes without error, schema returns to previous state
   - Capture: rollback output, exit code

3. **Re-apply migration**: run forward again after rollback
   - Expected: migration applies cleanly a second time (idempotency check)
   - Capture: migration output, exit code

4. **Application starts** with the new schema
   - Expected: no ORM errors, no missing column errors, no constraint violations
   - Capture: startup logs

5. **Affected queries work**
   - Run the application's test suite (especially integration tests)
   - If manual, execute key queries against the modified tables
   ```
   psql -c "SELECT count(*) FROM affected_table;"
   mysql -e "DESCRIBE affected_table;"
   ```
   - Expected: queries return expected results
   - Capture: query output

6. **Data integrity**: if the migration transforms data, verify correctness
   - Check row counts before and after
   - Spot-check transformed records
   - Verify constraints are enforced

---

## Infrastructure change

Any modification to deployment configuration, cloud resources, networking, or operational tooling.

### Required checks

1. **Dry run / plan**: preview what will change before applying
   ```
   terraform plan
   pulumi preview
   kubectl diff -f manifest.yaml
   docker compose config
   ```
   - Expected: only intended resources are affected
   - Capture: plan output showing added/changed/destroyed resources

2. **Apply the change**
   ```
   terraform apply
   pulumi up
   kubectl apply -f manifest.yaml
   docker compose up -d
   ```
   - Expected: apply succeeds, exit code 0
   - Capture: apply output, resource status

3. **Health check**: verify the deployed service is healthy
   ```
   curl -s http://service:port/health
   kubectl get pods -l app=myapp
   docker compose ps
   aws ecs describe-services --services myservice
   ```
   - Expected: all instances healthy, expected replica count, no crash loops
   - Capture: health check response, pod/container status

4. **Smoke test**: exercise critical paths through the deployed service
   ```
   curl -s -w "\n%{http_code}" http://service:port/api/critical-endpoint
   ```
   - Expected: expected HTTP status and response shape
   - Capture: status code, response body or excerpt

5. **Rollback test**: verify that rollback works before considering done
   - Roll back to the previous version
   - Verify health check passes on the previous version
   - Re-deploy the new version
   - This proves you have a safe exit path

6. **Monitoring check**: verify that observability is intact
   - Confirm logs are flowing to the logging system
   - Confirm metrics are being reported
   - Confirm alerts are not firing

---

## Documentation change

Any modification to docs: README files, API docs, architecture docs, runbooks, inline code comments.

### Required checks

1. **Links resolve**: check for broken links
   ```
   markdown-link-check README.md
   find docs/ -name "*.md" -exec markdown-link-check {} \;
   ```
   - Expected: zero broken links
   - Capture: link check output

2. **Code examples execute**: any code block in documentation must work
   - Copy each code example
   - Run it in the appropriate environment
   - Verify it produces the documented output
   - Expected: all examples produce expected output
   - Capture: execution output for each example

3. **Formatting renders correctly**: preview the rendered output
   - View in a markdown renderer or the target documentation platform
   - Check: headings, tables, code blocks, images, diagrams
   - Expected: all elements render as intended

4. **Content accuracy**: verify claims match the current codebase
   - File paths mentioned in docs exist
   - API endpoints documented match actual routes
   - Configuration options documented match actual config schema
   - Version numbers are current

5. **Spelling and grammar** (if tooling is available)
   ```
   cspell "docs/**/*.md"
   vale docs/
   ```
   - Expected: zero errors (or only known exceptions)
   - Capture: tool output

---

## Dependency update

Any modification to project dependencies: version bumps, new packages, removed packages.

### Required checks

1. **Lock file is updated**
   ```
   npm install
   pip install -r requirements.txt
   go mod tidy
   composer install
   bundle install
   cargo build
   ```
   - Expected: lock file changes match the intended update, no unexpected changes
   - Capture: install output, lock file diff summary

2. **Install succeeds**: clean install from lock file
   ```
   rm -rf node_modules && npm ci
   pip install -r requirements.txt
   composer install --no-cache
   ```
   - Expected: all dependencies resolve, exit code 0
   - Capture: install output, exit code

3. **Full test suite passes**: dependency changes can break anything
   - Run the complete test suite (same commands as Code change step 1)
   - Expected: zero failures
   - Capture: full test output

4. **Build succeeds**: dependency changes can break compilation
   - Run the full build (same commands as Code change step 4)
   - Expected: exit code 0
   - Capture: build output

5. **Security audit**
   ```
   npm audit
   pip-audit
   go vuln check ./...
   composer audit
   bundle audit check --update
   cargo audit
   ```
   - Expected: no new vulnerabilities introduced (or explicitly acknowledged)
   - Capture: audit output

6. **License check** (for new dependencies)
   - Verify the license is compatible with your project
   - Capture: license name and compatibility determination
