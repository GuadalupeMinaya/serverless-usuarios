import json
import logging
import os

import boto3  # type: ignore[reportMissingImports]
from botocore.exceptions import ClientError  # type: ignore[reportMissingImports]

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ses = boto3.client("ses")
SENDER = os.environ["SENDER_EMAIL"]


def handler(event, context):
    """Recibe mensajes de SQS (publicados por el backend via SNS) y envia el correo con SES."""
    records = event.get("Records", [])
    logger.info("Mensajes recibidos desde SQS: %d", len(records))
    failures = []

    for record in records:
        message_id = record["messageId"]
        try:
            data = json.loads(record["body"])
            to_email = data["email"]
            subject = data["subject"]
            body = data["message"]
            logger.info("Procesando mensaje %s: destino=%s asunto=%s", message_id, to_email, subject)

            response = ses.send_email(
                Source=SENDER,
                Destination={"ToAddresses": [to_email]},
                Message={
                    "Subject": {"Data": subject, "Charset": "UTF-8"},
                    "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
                },
            )
            logger.info("Correo enviado a %s (SES MessageId=%s)", to_email, response["MessageId"])

        except (KeyError, json.JSONDecodeError) as exc:
            logger.error("Mensaje %s con formato invalido: %s", message_id, exc)
            failures.append({"itemIdentifier": message_id})
        except ClientError as exc:
            logger.error("SES rechazo el mensaje %s: %s", message_id, exc)
            failures.append({"itemIdentifier": message_id})

    # Los mensajes que fallan vuelven a la cola y, tras 3 intentos, pasan a la cola de errores (DLQ)
    return {"batchItemFailures": failures}