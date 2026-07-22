"""Unit tests for secret resolution (local env fallback)."""

import os

import pytest

from src.utils.secrets import (
    SecretNotFoundError,
    get_credentials,
    get_secret,
    resolve_connection,
)


@pytest.fixture(autouse=True)
def _clear_secret_env(monkeypatch):
    for key in list(os.environ):
        if key.startswith("CLIENT_A_SECRETS__"):
            monkeypatch.delenv(key, raising=False)


def test_get_secret_from_env(monkeypatch):
    monkeypatch.setenv("CLIENT_A_SECRETS__SOURCE_USERNAME", "demo_user")
    assert get_secret("client-a-secrets", "source-username") == "demo_user"


def test_get_secret_missing_raises():
    with pytest.raises(SecretNotFoundError):
        get_secret("client-a-secrets", "source-username", dbutils=None)


def test_get_credentials_from_secret_keys(monkeypatch):
    monkeypatch.setenv("CLIENT_A_SECRETS__SOURCE_USERNAME", "src_user")
    monkeypatch.setenv("CLIENT_A_SECRETS__SOURCE_PASSWORD", "src_pass")

    block = {
        "secret_scope": "client-a-secrets",
        "secret_keys": {
            "username": "source-username",
            "password": "source-password",
        },
    }
    creds = get_credentials(block)
    assert creds == {"username": "src_user", "password": "src_pass"}


def test_resolve_connection(monkeypatch):
    monkeypatch.setenv("CLIENT_A_SECRETS__SOURCE_USERNAME", "src_user")
    monkeypatch.setenv("CLIENT_A_SECRETS__SOURCE_PASSWORD", "src_pass")
    monkeypatch.setenv("CLIENT_A_SECRETS__TARGET_USERNAME", "tgt_user")
    monkeypatch.setenv("CLIENT_A_SECRETS__TARGET_PASSWORD", "tgt_pass")

    from config.clients.client_a.connection import CONNECTION

    resolved = resolve_connection(CONNECTION)
    assert resolved["source"]["username"] == "src_user"
    assert resolved["source"]["password"] == "src_pass"
    assert resolved["target"]["username"] == "tgt_user"
    assert resolved["target"]["password"] == "tgt_pass"
