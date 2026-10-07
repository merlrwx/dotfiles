# Goal

Add a health endpoint to the web service that reports whether the process can
serve requests.

## Current State

The service has a root route but no health check. Deployment probes currently
use a TCP socket check.

## Desired End State

- `GET /health` returns HTTP 200 when the service is ready.
- The endpoint does not expose configuration or secrets.
- The deployment probe uses the new endpoint.

## Decisions

- Keep this endpoint unauthenticated and limited to readiness.
- Reuse the existing router and response format.

## Constraints

- Do not add a monitoring dependency.
- Keep the existing TCP probe available for startup if readiness is not yet
  possible.

## Phases

### Phase 1: Implement and verify

Outcome: add the route, update deployment configuration, and cover both ready
and unavailable service states.

Acceptance criteria:

- The route returns the documented status and body.
- Existing tests pass and the new route tests cover both states.
- The deployment probe targets `/health`.

Verification: run the repository's `mise run verify` task.
