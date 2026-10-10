# Project scaffold selection rules

Use the released `v1.1.0` template. All modules below are optional; choose from inspected requirements.

| Requirement | Select | Dependency or boundary |
| --- | --- | --- |
| Python API | `python-api` | Python, uv, pytest and Ruff |
| API plus Streamlit UI | `python-api-with-ui` | Single package by default; `separate_packages` creates API/UI uv workspace members |
| Other application shape | `generic` | No Python application or Python-only modules |
| Coverage enforcement | `include_coverage` | Python only; configurable threshold, XML report and GitHub PR comment when Actions is selected |
| Local quality hooks | `include_pre_commit` | Python only; pinned Ruff and Commitizen hooks |
| SQLite persistence | `include_persistence` | Python only; Compose volume and Kubernetes PVC when those modules are selected |
| Container builds | `include_containers` | Python only; API/UI images as appropriate |
| Local service orchestration | `include_compose` | Requires containers |
| Isolated editor environment | `include_devcontainer` | Python only; container tooling and selected ports |
| GitHub CI | `include_github_actions` | Generated lint/tests and optional image builds |
| Security gates | `include_security_scanning` | Requires Actions; pip-audit, Bandit, Gitleaks and Trivy when containers are selected |
| Release PRs | `include_release_automation` | Requires Actions and `RELEASE_TOKEN`; workspace packages can release independently |
| GHCR delivery | `include_image_publishing` | Requires containers, Actions and explicit `image_registry_namespace`; version tags |
| Kubernetes deployment | `include_kubernetes` | Requires containers; probes/resources and base/dev/prod overlays |
| GitOps reconciliation | `include_flux` | Requires Kubernetes, explicit source URL and existing Flux controller/reconciliation root |
| Cross-repository promotion | `include_gitops_promotion` | Requires publishing, Flux, matching explicit `gitops_repository` and `GITOPS_TOKEN`; dev commit then prod PR |
| Local Kubernetes and E2E | `include_k3d` | Requires Kubernetes; scoped cluster commands, acknowledged teardown and disposable E2E |

Mise provides the shared development tasks. Modules stay disabled by default. Do not infer deployment targets or create infrastructure from template availability. Generation never publishes images, configures secrets, creates clusters or applies resources. Review generated configuration and run applicable checks before authorized external operations.

Coverage measures application code, excluding the thin Streamlit entrypoint; it does not imply browser coverage. SQLite volumes require an appropriate storage class and backup plan for production. Scanner findings fail CI and require investigation.

For existing repositories, inspect first, generate into a temporary directory, compare with the working tree and apply reviewed changes selectively. Preserve `.copier-answers.yml` through Copier rather than hand editing it. Existing single package projects retain their layout unless deliberately migrated. A v1.0.0 project missing recorded option metadata needs its original selections supplied during the documented update/recovery procedure.

See [template feature documentation](https://github.com/merlrwx/devops-template/blob/v1.1.0/docs/features.md) for answer profiles, tokens, module dependencies and migration details.
