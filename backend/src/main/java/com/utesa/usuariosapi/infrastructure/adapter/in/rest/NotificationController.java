package com.utesa.usuariosapi.infrastructure.adapter.in.rest;

import com.utesa.usuariosapi.application.port.in.NotificationServicePort;
import com.utesa.usuariosapi.domain.Notification;
import com.utesa.usuariosapi.domain.NotificationPublishException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final NotificationServicePort notificationService;

    public NotificationController(NotificationServicePort notificationService) {
        this.notificationService = notificationService;
    }

    @PostMapping("/send")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public Map<String, String> enviar(@Valid @RequestBody NotificationRequest request) {
        try {
            String messageId = notificationService.enviar(new Notification(
                    request.getEmail().trim(),
                    request.getSubject().trim(),
                    request.getMessage().trim()));
            return Map.of(
                    "mensaje", "Mensaje enviado correctamente.",
                    "messageId", messageId);
        } catch (NotificationPublishException e) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "No se pudo publicar el mensaje");
        }
    }
}