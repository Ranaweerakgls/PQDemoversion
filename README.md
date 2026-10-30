# piq-demo

Tiny Node.js repo for trying PipelineIQ. `npm test` runs Node's built-in test runner.

- `test/math.test.js`: always passes.
- `test/flaky.test.js`: fails about 1 run in 3 (flaky failure).
- Branch `genuine-bug`: `add()` has a real bug, so a test fails every time (genuine failure).
