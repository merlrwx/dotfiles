from mcp_server.tools.kubernetes_kubectl import KubectlValidator


def validate(operation: str, resource_type: str = "", **options: object):
    return KubectlValidator.validate_operation(operation, resource_type, "default", options)


def test_logs_and_exec_accept_pod_name_without_resource_type():
    assert validate("logs", pod_name="api-0") == (True, None)
    assert validate("exec", pod_name="api-0") == (True, None)


def test_logs_and_exec_require_pod_name():
    for operation in ("logs", "exec"):
        valid, error = validate(operation)
        assert not valid
        assert error is not None and "pod_name" in error


def test_other_resource_and_safety_validation_remain_intact():
    valid, error = validate("get", "bad resource")
    assert not valid
    assert error is not None and "Resource type" in error

    valid, error = KubectlValidator.validate_operation("delete", "pod", "kube-system", {})
    assert not valid
    assert error is not None and "system namespace" in error
