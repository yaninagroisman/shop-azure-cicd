"""Kafka connection settings from environment variables.

Without any of the variables below the client connects in PLAINTEXT, as in
Docker Compose. On AKS the Kafka cluster (Strimzi) requires SASL/SCRAM over
TLS, so the deployment sets:

* KAFKA_SECURITY_PROTOCOL  PLAINTEXT (default), SSL, SASL_PLAINTEXT or SASL_SSL
* KAFKA_SASL_MECHANISM     SCRAM-SHA-512 by default (what Strimzi uses)
* KAFKA_SASL_USERNAME, KAFKA_SASL_PASSWORD  required for the SASL_* protocols
* KAFKA_SSL_CA_LOCATION    CA certificate file for the SSL protocols
                           (Strimzi's cluster CA); system CAs when unset

The same file exists in api/ and client/: each image is built from its own
folder.
"""
import os

PROTOCOLS = {"PLAINTEXT", "SSL", "SASL_PLAINTEXT", "SASL_SSL"}


def kafka_config(server, env=None):
    """Return librdkafka settings for bootstrap `server`; raise ValueError on bad env."""
    env = os.environ if env is None else env
    protocol = env.get("KAFKA_SECURITY_PROTOCOL", "PLAINTEXT").strip().upper() or "PLAINTEXT"
    if protocol not in PROTOCOLS:
        raise ValueError(
            f"KAFKA_SECURITY_PROTOCOL must be one of {', '.join(sorted(PROTOCOLS))}, got {protocol!r}"
        )

    config = {"bootstrap.servers": server, "security.protocol": protocol}

    if protocol.startswith("SASL_"):
        username = env.get("KAFKA_SASL_USERNAME", "")
        password = env.get("KAFKA_SASL_PASSWORD", "")
        if not username or not password:
            raise ValueError(f"{protocol} needs KAFKA_SASL_USERNAME and KAFKA_SASL_PASSWORD")
        config.update({
            "sasl.mechanism": env.get("KAFKA_SASL_MECHANISM", "SCRAM-SHA-512"),
            "sasl.username": username,
            "sasl.password": password,
        })

    if protocol.endswith("SSL") and env.get("KAFKA_SSL_CA_LOCATION"):
        config["ssl.ca.location"] = env["KAFKA_SSL_CA_LOCATION"]

    return config
