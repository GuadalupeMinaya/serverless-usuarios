package com.utesa.usuariosapi.application;

import com.utesa.usuariosapi.application.port.in.NotificationServicePort;
import com.utesa.usuariosapi.application.port.out.NotificationPublisherPort;
import com.utesa.usuariosapi.domain.Notification;
import org.springframework.stereotype.Service;

@Service
public class NotificationService implements NotificationServicePort {

    private final NotificationPublisherPort publisher;

    public NotificationService(NotificationPublisherPort publisher) {
        this.publisher = publisher;
    }

    @Override
    public String enviar(Notification notification) {
        return publisher.publicar(notification);
    }
}