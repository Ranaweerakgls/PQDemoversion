const test = require('node:test');
const assert = require('node:assert');

// Deliberately flaky: fails about 1 run in 3 (like a timing or ordering bug).
test('flaky: finishes within its time budget', async () => {
  const delay = Math.random() * 30;
  await new Promise((resolve) => setTimeout(resolve, delay));
  assert.ok(delay < 20, `took ${delay.toFixed(1)} ms, budget is 20 ms`);
});
