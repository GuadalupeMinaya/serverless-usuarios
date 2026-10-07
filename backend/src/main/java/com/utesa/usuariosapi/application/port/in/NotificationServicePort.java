package com.utesa.usuariosapi.application.port.in;

import com.utesa.usuariosapi.domain.Notification;

public interface NotificationServicePort {

    /** Envía la notificación al flujo asíncrono y devuelve el id del mensaje publicado. */
    String enviar(Notification notification);
}