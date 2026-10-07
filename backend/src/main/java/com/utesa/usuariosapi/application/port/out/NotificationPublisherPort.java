package com.utesa.usuariosapi.application.port.out;

import com.utesa.usuariosapi.domain.Notification;

public interface NotificationPublisherPort {

    /** Publica la notificación en el sistema de mensajería y devuelve el id del mensaje. */
    String publicar(Notification notification);
}