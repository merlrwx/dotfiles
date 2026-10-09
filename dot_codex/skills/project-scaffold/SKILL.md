---
name: project-scaffold
description: Create new application repositories with the DevOps Copier template, or assess and selectively adopt its components in an existing repository.
---

# Project scaffold

Use `gh:merlrwx/devops-template` for a new repository when its supported project types and modules are a good fit. Pin generation to a released template version. If the template does not meaningfully fit the request, explain why and build with the project's existing conventions.

For the feature matrix and dependency rules, consult [selection rules](references/selection-rules.md).

## Choose features from evidence

Before choosing options, inspect the request and any available repository files. Identify the application type, language/runtime, development workflow, CI provider, packaging and deployment targets. Select the smallest valid feature combination that satisfies those requirements.

- Always include Mise and appropriate test, lint, and pre-commit tooling.
- Select `python-api` for a Python API, `python-api-with-ui` for a Python API with a separate UI, or `generic` when no Python application is required.
- Include containers when the application needs a container image or a reproducible container-based development path.
- Include Compose only for local multi-service development.
- Include GitHub Actions only when the project uses GitHub.
- Include Kubernetes only for a Kubernetes deployment. Include Flux only when that Kubernetes deployment is GitOps-managed; Flux requires Kubernetes.
- Include automated releases and security checks when they fit the project's release and risk needs.
- Do not infer a need for Kubernetes, Flux, cloud services, or infrastructure provisioning from their presence in the template.

If an option depends on another option, satisfy that dependency or leave the dependent feature out. Do not select unsupported combinations just to avoid asking a necessary product question.

## Create a new repository

1. Inspect the destination and project request. Preserve any existing files; never overwrite a non-empty destination without reviewing it.
2. Choose the project type and features from the rules above. Resolve required names, ports, namespaces, image names, and CI settings from explicit requirements or the source repository. Avoid inventing production values or credentials.
3. Write the selected answers to a temporary YAML file outside the destination. Do not edit `.copier-answers.yml` in the generated project.
4. Generate from a pinned release:

   ```sh
   copier copy \
     --vcs-ref v1.0.0 \
     --data-file /tmp/project-scaffold-answers.yml \
     --defaults \
     gh:merlrwx/devops-template \
     ./new-project
   ```

5. Review the generated file list and configuration. Run the generated Mise, lint, test, and build tasks that apply to the selected features. Fix project-specific gaps and report any external credentials or manual configuration required.
6. Explain the chosen and omitted components, any manual changes, and the checks run.

## Assess an existing repository

For existing applications, first inspect the current architecture, conventions, working development setup, tests, CI, deployment, and any `.copier-answers.yml`. Skip Copier if the project is already suitably configured or the template would add little value.

When Copier can help, generate into a temporary directory using the template's update or copy workflow. Compare the result with the repository, then selectively apply reviewed changes. Keep the work on a clean Git branch, preserve working application configuration, and resolve conflicts deliberately. Never overwrite the repository wholesale, run infrastructure provisioning, configure production secrets, or deploy as part of scaffolding. Do not edit `.copier-answers.yml` manually.

## Report

Summarize which features were selected and why, what was left out, the files changed, the checks run, and any unresolved configuration. Explain meaningful deviations from the template's standard structure.
