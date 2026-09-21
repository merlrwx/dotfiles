import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { isTrustedAppRequest } from '../../src/auth/requestPolicy.ts'

const expectedOrigin = 'https://leveling.merl.one'

test('origin-less safe navigation is allowed', () => {
  for (const method of ['GET', 'HEAD']) {
    assert.equal(isTrustedAppRequest({ method, fetchSite: 'cross-site', expectedOrigin }), true)
  }
})

test('an explicit foreign origin is always rejected', () => {
  for (const method of ['GET', 'HEAD', 'POST']) {
    assert.equal(isTrustedAppRequest({
      method,
      origin: 'https://attacker.example',
      fetchSite: 'same-origin',
      expectedOrigin,
    }), false)
  }
})

test('origin-less unsafe browser requests remain rejected', () => {
  assert.equal(isTrustedAppRequest({ method: 'POST', fetchSite: 'cross-site', expectedOrigin }), false)
  assert.equal(isTrustedAppRequest({ method: 'POST', fetchSite: 'same-site', expectedOrigin }), false)
})

test('trusted and non-browser behavior remains intact', () => {
  assert.equal(isTrustedAppRequest({ method: 'POST', origin: expectedOrigin, expectedOrigin }), true)
  assert.equal(isTrustedAppRequest({ method: 'POST', expectedOrigin }), true)
})

test('middleware supplies the HTTP method and temporary diagnostics are removed', () => {
  const middleware = readFileSync(new URL('../../src/auth/middleware.ts', import.meta.url), 'utf8')
  assert.match(middleware, /isTrustedAppRequest\(\{[^}]*method/s)
  assert.doesNotMatch(middleware, /DEBUG-origin|rejected authenticated request/)
})
