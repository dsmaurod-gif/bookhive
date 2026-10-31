import json
import os

import boto3
from botocore.config import Config

# Timeouts cortos: si falta un VPC endpoint, falla rápido en vez de colgarse
config = Config(connect_timeout=3, read_timeout=5, retries={"max_attempts": 1})
sns = boto3.client("sns", config=config)
secretos = boto3.client("secretsmanager", config=config)


def _respuesta(codigo, cuerpo):
    return {
        "statusCode": codigo,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(cuerpo, ensure_ascii=False),
    }


def handler(event, context):
    metodo = event.get("httpMethod")

    if metodo == "GET":
        try:
            secretos.get_secret_value(SecretId=os.environ["SECRET_ARN"])
            secretos_ok = True
        except Exception as error:  # noqa: BLE001
            print(f"No se pudo leer el secreto: {error}")
            secretos_ok = False
        return _respuesta(
            200,
            {
                "clubes": [{"id": 1, "nombre": "Club de lectura demo"}],
                "secretsManagerAccesible": secretos_ok,
            },
        )

    if metodo == "POST":
        cuerpo = json.loads(event.get("body") or "{}")
        evento = {
            "tipo": "club.creado",
            "club": cuerpo.get("nombre", "sin nombre"),
            "correo": cuerpo.get("correo"),
        }
        sns.publish(TopicArn=os.environ["TOPIC_ARN"], Message=json.dumps(evento))
        return _respuesta(202, {"mensaje": "evento publicado", "evento": evento})

    return _respuesta(405, {"mensaje": "método no permitido"})