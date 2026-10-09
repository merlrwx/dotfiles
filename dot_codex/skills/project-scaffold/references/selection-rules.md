# Project scaffold selection rules

| Requirement | Select | Dependency or boundary |
| --- | --- | --- |
| Python API | `python-api` | Python and uv configuration; no UI unless requested |
| Python API plus separate UI | `python-api-with-ui` | API and UI services have independent configuration and checks |
| No supported Python application shape | `generic` | Does not generate a Python application |
| Container build or image delivery | Containers | Compose is a separate choice for local multi-service workflows |
| GitHub-hosted repository | GitHub Actions | Tailor triggers and jobs to the project |
| Kubernetes deployment | Kubernetes | Container packaging is required |
| GitOps-managed Kubernetes | Flux | Requires Kubernetes; do not bootstrap a cluster or GitOps repo |
| Automated version and release workflow | Release tooling | Include only when the project benefits from automated releases |
| Dependency/image/security checks | Security tooling | Select checks that match the project and its dependency types |

Mise and appropriate tests, linting, and pre-commit checks form the shared development foundation. Optional modules must not leave broken references when omitted.

For existing repositories, inspect before selecting. Generate into a temporary location, compare against the working tree, and apply changes selectively after review.
