package com.utesa.usuariosapi.infrastructure.adapter.out.messaging;

import com.utesa.usuariosapi.application.port.out.NotificationPublisherPort;
import com.utesa.usuariosapi.domain.Notification;
import com.utesa.usuariosapi.domain.NotificationPublishException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.exception.SdkException;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;
import software.amazon.awssdk.services.sns.model.PublishResponse;

@Component
public class SnsNotificationPublisher implements NotificationPublisherPort {

    private static final Logger log = LoggerFactory.getLogger(SnsNotificationPublisher.class);

    private final SnsClient sns;
    private final String topicArn;

    public SnsNotificationPublisher(@Value("${app.sns.topic-arn:}") String topicArn) {
        this.topicArn = topicArn;
        this.sns = SnsClient.create();
    }

    @Override
    public String publicar(Notification notification) {
        if (topicArn == null || topicArn.isBlank()) {
            throw new NotificationPublishException("SNS_TOPIC_ARN no está configurado");
        }
        try {
            PublishResponse response = sns.publish(PublishRequest.builder()
                    .topicArn(topicArn)
                    .message(toJson(notification))
                    .build());
            log.info("Mensaje publicado en SNS: messageId={} destino={}",
                    response.messageId(), notification.email());
            return response.messageId();
        } catch (SdkException e) {
            log.error("Error al publicar en SNS", e);
            throw new NotificationPublishException("No se pudo publicar en SNS", e);
        }
    }

    /** Cuerpo del mensaje que consumirá notification-lambda: {"email","subject","message"}. */
    public static String toJson(Notification n) {
        return "{\"email\":" + quote(n.email())
                + ",\"subject\":" + quote(n.subject())
                + ",\"message\":" + quote(n.message()) + "}";
    }

    private static String quote(String value) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : value.toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        return sb.append('"').toString();
    }
}