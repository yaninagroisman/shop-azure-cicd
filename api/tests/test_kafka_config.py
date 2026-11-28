"""Unit tests for the Kafka connection settings built from the environment."""
import pytest
from kafka_config import kafka_config


def test_plaintext_by_default():
    assert kafka_config("kafka:9092", env={}) == {
        "bootstrap.servers": "kafka:9092",
        "security.protocol": "PLAINTEXT",
    }


def test_sasl_ssl_with_scram_and_cluster_ca():
    env = {
        "KAFKA_SECURITY_PROTOCOL": "sasl_ssl",
        "KAFKA_SASL_USERNAME": "shop-api",
        "KAFKA_SASL_PASSWORD": "secret",
        "KAFKA_SSL_CA_LOCATION": "/etc/kafka-ca/ca.crt",
    }
    assert kafka_config("shop-kafka-bootstrap.kafka:9093", env=env) == {
        "bootstrap.servers": "shop-kafka-bootstrap.kafka:9093",
        "security.protocol": "SASL_SSL",
        "sasl.mechanism": "SCRAM-SHA-512",
        "sasl.username": "shop-api",
        "sasl.password": "secret",
        "ssl.ca.location": "/etc/kafka-ca/ca.crt",
    }


def test_mechanism_can_be_overridden():
    env = {
        "KAFKA_SECURITY_PROTOCOL": "SASL_PLAINTEXT",
        "KAFKA_SASL_MECHANISM": "SCRAM-SHA-256",
        "KAFKA_SASL_USERNAME": "u",
        "KAFKA_SASL_PASSWORD": "p",
    }
    config = kafka_config("k:9092", env=env)
    assert config["sasl.mechanism"] == "SCRAM-SHA-256"
    assert "ssl.ca.location" not in config


def test_ssl_without_ca_uses_system_cas():
    config = kafka_config("k:9093", env={"KAFKA_SECURITY_PROTOCOL": "SSL"})
    assert config == {"bootstrap.servers": "k:9093", "security.protocol": "SSL"}


@pytest.mark.parametrize("missing", ["KAFKA_SASL_USERNAME", "KAFKA_SASL_PASSWORD"])
def test_sasl_without_credentials_fails_fast(missing):
    env = {"KAFKA_SECURITY_PROTOCOL": "SASL_SSL", "KAFKA_SASL_USERNAME": "u", "KAFKA_SASL_PASSWORD": "p"}
    del env[missing]
    with pytest.raises(ValueError, match="KAFKA_SASL_USERNAME and KAFKA_SASL_PASSWORD"):
        kafka_config("k:9093", env=env)


def test_unknown_protocol_is_rejected():
    with pytest.raises(ValueError, match="KAFKA_SECURITY_PROTOCOL"):
        kafka_config("k:9092", env={"KAFKA_SECURITY_PROTOCOL": "TLS"})
