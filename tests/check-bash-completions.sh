#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT
mkdir -p "$temporary_dir/bin"

cat >"$temporary_dir/bin/kubectl" <<'KUBECTL'
#!/usr/bin/env bash
if [[ ${1-} == completion && ${2-} == bash ]]; then
    cat <<'COMPLETION'
__start_kubectl() {
    local cur=${COMP_WORDS[COMP_CWORD]-}
    COMPREPLY=()
    if [[ $cur == -* ]]; then
        COMPREPLY=(--namespace --all-namespaces --output)
    elif [[ ${COMP_WORDS[1]-} == get && ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=(pods deployments services)
    elif [[ ${COMP_WORDS[1]-} == get && ${COMP_WORDS[2]-} == pods && ${COMP_CWORD} -eq 3 ]]; then
        COMPREPLY=(api-one api-two)
    elif [[ ${COMP_WORDS[COMP_CWORD-1]-} == -n || ${COMP_WORDS[COMP_CWORD-1]-} == --namespace ]]; then
        COMPREPLY=(default kube-system)
    fi
}
complete -o default -F __start_kubectl kubectl
COMPLETION
else
    exit 2
fi
KUBECTL
chmod +x "$temporary_dir/bin/kubectl"

cat >"$temporary_dir/bin/devpod" <<'DEVPOD'
#!/usr/bin/env bash
if [[ ${1-} == completion && ${2-} == bash ]]; then
    printf 'generated\n' >>"$HOME/devpod-completion-calls"
    cat <<'COMPLETION'
__start_devpod() {
    local cur=${COMP_WORDS[COMP_CWORD]-}
    COMPREPLY=()
    if [[ $cur == -* ]]; then
        COMPREPLY=(--workdir --command)
    elif [[ ${COMP_WORDS[1]-} == devpod || ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=(ssh up list)
    fi
}
complete -o default -F __start_devpod devpod
COMPLETION
elif [[ ${1-} == list ]]; then
    if [[ ${DEVPOD_FAIL_LIST:-0} == 1 ]]; then
        printf 'workspace service unavailable\n' >&2
        exit 1
    fi
    printf '%s\n' '[{"id":"task-blue"},{"id":"task-green"}]'
else
    exit 2
fi
DEVPOD
chmod +x "$temporary_dir/bin/devpod"

cat >"$temporary_dir/bin/herdr" <<'HERDR'
#!/usr/bin/env bash
if [[ ${1-} == completion && ${2-} == bash ]]; then
    cat <<'COMPLETION'
_herdr() {
    local cur=${2-}
    COMPREPLY=()
    if [[ $cur == -* || ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=(--session --help agent session)
    elif [[ ${COMP_WORDS[COMP_CWORD-1]-} == --session ]]; then
        COMPREPLY=(filesystem-candidate)
    fi
}
complete -o default -F _herdr herdr
COMPLETION
elif [[ ${1-} == session && ${2-} == list && ${3-} == --json ]]; then
    if [[ ${HERDR_FAIL_LIST:-0} == 1 ]]; then
        printf 'Herdr service unavailable\n' >&2
        exit 1
    fi
    printf '%s\n' '{"sessions":[{"name":"codex-blue"},{"name":"shell-green"}]}'
else
    exit 2
fi
HERDR
chmod +x "$temporary_dir/bin/herdr"

PATH="$temporary_dir/bin:$PATH" \
HOME="$temporary_dir/home" \
COMPLETION_SOURCE="$repo_root/dot_config/bash/completions/init.sh" \
bash --noprofile --norc -euo pipefail <<'BASH'
fail() {
    printf 'Bash completion check failed: %s\n' "$1" >&2
    exit 1
}

herdr() {
    HERDR_WRAPPER_CALLED=1
    return 99
}

source "$COMPLETION_SOURCE"

[[ $(<"$HOME/devpod-completion-calls") == generated ]] || fail 'DevPod native completion was not generated'
source "$COMPLETION_SOURCE"
[[ $(<"$HOME/devpod-completion-calls") == generated ]] || fail 'DevPod native completion cache was not reused'

complete -p kubectl >/dev/null 2>&1 || fail 'kubectl completion was not registered'
complete -p k >/dev/null 2>&1 || fail 'k alias completion was not registered'

completion_function() {
    local registration
    registration="$(complete -p "$1")"
    [[ $registration =~ -F[[:space:]]+([^[:space:]]+) ]] || return 1
    printf '%s\n' "${BASH_REMATCH[1]}"
}

complete_line() {
    local command_name=$1 completion_function
    shift
    COMP_WORDS=("$@")
    COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
    COMPREPLY=()
    completion_function="$(completion_function "$command_name")" || return 1
    "$completion_function" "${COMP_WORDS[0]}" "${COMP_WORDS[COMP_CWORD]-}" "${COMP_WORDS[COMP_CWORD-1]-}"
    printf '%s\n' "${COMPREPLY[@]}"
}

kubectl_resources="$(complete_line kubectl kubectl get '')"
k_resources="$(complete_line k k get '')"
[[ $kubectl_resources == "$k_resources" ]] || fail 'k resource candidates differ from kubectl'
[[ $k_resources == *pods* && $k_resources == *deployments* ]] || fail 'resource types are missing'

k_pods="$(complete_line k k get pods '')"
[[ $k_pods == *api-one* && $k_pods == *api-two* ]] || fail 'pod names are missing'

k_namespaces="$(complete_line k k get pods -n '')"
[[ $k_namespaces == *default* && $k_namespaces == *kube-system* ]] || fail 'namespace candidates are missing'

k_flags="$(complete_line k k get pods --n)"
[[ $k_flags == *--namespace* && $k_flags == *--all-namespaces* ]] || fail 'kubectl flags are missing'

complete -p devpod >/dev/null 2>&1 || fail 'DevPod completion was not registered'
devpod_native="$(complete_line devpod devpod s)"
[[ $devpod_native == *ssh* ]] || fail 'DevPod native subcommand completion is missing'
devpod_flags="$(complete_line devpod devpod ssh --w)"
[[ $devpod_flags == *--workdir* ]] || fail 'DevPod native flag completion is missing'
devpod_workspaces="$(complete_line devpod devpod ssh '')"
[[ $devpod_workspaces == *task-blue* && $devpod_workspaces == *task-green* ]] || fail 'DevPod workspace candidates are missing'
devpod_filtered="$(complete_line devpod devpod ssh task-g)"
[[ $devpod_filtered == task-green ]] || fail 'DevPod workspace candidates are not prefix-filtered'

complete -p herdr >/dev/null 2>&1 || fail 'Herdr completion was not registered'
herdr_native="$(complete_line herdr herdr --se)"
[[ $herdr_native == *--session* ]] || fail 'Herdr native option completion is missing'
herdr_sessions="$(complete_line herdr herdr --session '')"
[[ $herdr_sessions == *codex-blue* && $herdr_sessions == *shell-green* ]] || fail 'Herdr session candidates are missing'
[[ $herdr_sessions != *filesystem-candidate* ]] || fail 'Herdr session completion still falls back to filesystem candidates'
[[ -z ${HERDR_WRAPPER_CALLED:-} ]] || fail 'Herdr completion generation called the shell wrapper'

export DEVPOD_FAIL_LIST=1
devpod_failed="$(complete_line devpod devpod ssh '')" || fail 'DevPod listing failure broke completion'
[[ -z $devpod_failed ]] || fail 'DevPod listing failure returned invalid candidates'
export HERDR_FAIL_LIST=1
herdr_failed="$(complete_line herdr herdr --session '')" || fail 'Herdr listing failure broke completion'
[[ -z $herdr_failed ]] || fail 'Herdr listing failure returned invalid candidates'
BASH

startup_output="$(PATH="$temporary_dir/bin:$PATH" HOME="$temporary_dir/startup-home" XDG_CACHE_HOME="$temporary_dir/startup-cache" COMPLETION_SOURCE="$repo_root/dot_config/bash/completions/init.sh" bash --noprofile --norc -c 'source "$COMPLETION_SOURCE"' 2>&1)"
[[ -z $startup_output ]] || { printf 'Bash completion check failed: completion setup printed during startup\n' >&2; exit 1; }

mkdir -p "$temporary_dir/fallback-home"
touch "$temporary_dir/cache-is-a-file"
fallback_output="$(PATH="$temporary_dir/bin:$PATH" HOME="$temporary_dir/fallback-home" XDG_CACHE_HOME="$temporary_dir/cache-is-a-file" COMPLETION_SOURCE="$repo_root/dot_config/bash/completions/init.sh" bash --noprofile --norc -c 'source "$COMPLETION_SOURCE"; complete -p devpod >/dev/null' 2>&1)"
[[ -z $fallback_output ]] || { printf 'Bash completion check failed: an unavailable cache path printed output\n' >&2; exit 1; }

mkdir -p "$temporary_dir/empty/bin"
ln -s "$(command -v bash)" "$temporary_dir/empty/bin/bash"
PATH="$temporary_dir/empty/bin" COMPLETION_SOURCE="$repo_root/dot_config/bash/completions/init.sh" \
    bash --noprofile --norc -euo pipefail -c 'source "$COMPLETION_SOURCE"'

printf 'Bash completion smoke check passed.\n'
