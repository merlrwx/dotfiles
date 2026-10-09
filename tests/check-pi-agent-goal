#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
extension="$repo_root/dot_pi/agent/extensions/autonomous-goal.ts"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

cat >"$test_root/check.mjs" <<'NODE'
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { chmodSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { execFileSync } from "node:child_process";

const moduleUrl = pathToFileURL(process.argv[2]);
const { default: register, shouldContinue } = await import(moduleUrl.href);

function repository() {
  const root = mkdtempSync(join(tmpdir(), "pi-agent-goal-"));
  execFileSync("git", ["init", "-q", root]);
  const state = join(root, ".agent");
  mkdirSync(state);
  const verifier = join(state, "VERIFY");
  writeFileSync(verifier, "#!/bin/sh\nexit 0\n");
  chmodSync(verifier, 0o755);
  const digest = createHash("sha256").update("#!/bin/sh\nexit 0\n").digest("hex");
  writeFileSync(join(state, "ACTIVE"), JSON.stringify({
    version: 1,
    verifier: ".agent/VERIFY",
    verifier_sha256: digest,
  }));
  return { root, state, verifier };
}

const valid = repository();
assert.equal(shouldContinue(valid.root), true, "valid active goal should continue");

let handler;
register({ on(name, callback) { assert.equal(name, "agent_before_settle"); handler = callback; } });
const resumed = await handler({ entries: [] }, { cwd: valid.root });
assert.equal(resumed.continue, true);
assert.equal(resumed.entries[0].type, "custom_message");
assert.equal(resumed.entries[0].display, false);

for (const marker of ["COMPLETE", "PAUSE", "BLOCKED.md"]) {
  const marked = repository();
  writeFileSync(join(marked.state, marker), "");
  assert.equal(shouldContinue(marked.root), false, `${marker} should stop continuation`);
  assert.equal(await handler({ entries: [] }, { cwd: marked.root }), undefined);
  rmSync(marked.root, { recursive: true, force: true });
}

const tampered = repository();
writeFileSync(tampered.verifier, "#!/bin/sh\nexit 1\n");
assert.equal(shouldContinue(tampered.root), false, "changed verifier should stop continuation");

const invalid = repository();
writeFileSync(join(invalid.state, "ACTIVE"), "{bad json");
assert.equal(shouldContinue(invalid.root), false, "invalid ACTIVE should stop continuation");

const escaped = repository();
writeFileSync(join(escaped.state, "ACTIVE"), JSON.stringify({
  version: 1,
  verifier: "../outside",
  verifier_sha256: "0".repeat(64),
}));
assert.equal(shouldContinue(escaped.root), false, "verifier outside repo should stop continuation");

for (const item of [valid, tampered, invalid, escaped]) rmSync(item.root, { recursive: true, force: true });
NODE

node --experimental-strip-types "$test_root/check.mjs" "$extension"
printf 'Pi autonomous-goal checks passed.\n'
