package com.utesa.usuariosapi;

import com.utesa.usuariosapi.application.NotificationService;
import com.utesa.usuariosapi.application.port.out.NotificationPublisherPort;
import com.utesa.usuariosapi.domain.Notification;
import com.utesa.usuariosapi.infrastructure.adapter.out.messaging.SnsNotificationPublisher;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class NotificationTests {

    @Test
    void servicioPublicaElMensajeYDevuelveElId() {
        List<Notification> publicados = new ArrayList<>();
        NotificationPublisherPort publisher = n -> {
            publicados.add(n);
            return "msg-123";
        };
        NotificationService service = new NotificationService(publisher);
        Notification notification = new Notification("a@b.com", "Asunto", "Mensaje");

        String id = service.enviar(notification);

        assertEquals("msg-123", id);
        assertEquals(List.of(notification), publicados);
    }

    @Test
    void jsonEscapaComillasSaltosDeLineaYBarras() {
        Notification n = new Notification("a@b.com", "Prueba \"SNS\"", "L1\nL2\\fin");

        String json = SnsNotificationPublisher.toJson(n);

        assertEquals(
                "{\"email\":\"a@b.com\",\"subject\":\"Prueba \\\"SNS\\\"\",\"message\":\"L1\\nL2\\\\fin\"}",
                json);
    }
}