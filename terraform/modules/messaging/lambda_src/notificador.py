"""Lambda notificador: lee mensajes de SQS y envía un correo con SES.

Si SES falla (por ejemplo, el correo aún no está verificado en sandbox), la función
lanza una excepción: el mensaje vuelve a la cola y, tras 3 intentos, pasa a la DLQ.
"""
import json
import os

import boto3

ses = boto3.client("sesv2")


def handler(event, context):
    for registro in event["Records"]:
        evento = json.loads(registro["body"])
        destinatario = evento.get("correo") or os.environ["DESTINATARIO"]

        ses.send_email(
            FromEmailAddress=os.environ["REMITENTE"],
            Destination={"ToAddresses": [destinatario]},
            Content={
                "Simple": {
                    "Subject": {"Data": "BookHive: nuevo club de lectura"},
                    "Body": {"Text": {"Data": f"Se creó el club {evento.get('club', 'sin nombre')}."}},
                }
            },
        )
        print(f"Correo enviado a {destinatario}")