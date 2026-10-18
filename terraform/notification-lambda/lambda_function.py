import json
import logging
import os
import time

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ses = boto3.client("ses")
SENDER = os.environ["SENDER_EMAIL"]

# Modo de pruebas de carga: no llama a SES (que en sandbox solo permite 1 correo/s
# y destinatarios verificados) y simula su latencia con una pausa de 100 ms.
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"
DRY_RUN_LATENCY_SECONDS = 0.1


def enviar_correo(to_email, subject, body):
    if DRY_RUN:
        time.sleep(DRY_RUN_LATENCY_SECONDS)
        return "dry-run"

    response = ses.send_email(
        Source=SENDER,
        Destination={"ToAddresses": [to_email]},
        Message={
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
        },
    )
    return response["MessageId"]


def handler(event, context):
    """Recibe mensajes de SQS (publicados por el backend via SNS) y envia el correo con SES."""
    records = event.get("Records", [])
    logger.info("Mensajes recibidos desde SQS: %d (dry_run=%s)", len(records), DRY_RUN)
    failures = []

    for record in records:
        message_id = record["messageId"]
        try:
            data = json.loads(record["body"])
            to_email = data["email"]
            subject = data["subject"]
            body = data["message"]
            logger.info("Procesando mensaje %s: destino=%s asunto=%s", message_id, to_email, subject)

            ses_id = enviar_correo(to_email, subject, body)
            logger.info("Correo enviado a %s (SES MessageId=%s)", to_email, ses_id)

        except (KeyError, json.JSONDecodeError) as exc:
            logger.error("Mensaje %s con formato invalido: %s", message_id, exc)
            failures.append({"itemIdentifier": message_id})
        except ClientError as exc:
            logger.error("SES rechazo el mensaje %s: %s", message_id, exc)
            failures.append({"itemIdentifier": message_id})

    # Los mensajes que fallan vuelven a la cola y, tras 3 intentos, pasan a la cola de errores (DLQ)
    return {"batchItemFailures": failures}