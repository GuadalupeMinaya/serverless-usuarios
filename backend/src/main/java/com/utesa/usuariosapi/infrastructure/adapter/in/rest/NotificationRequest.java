package com.utesa.usuariosapi.infrastructure.adapter.in.rest;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class NotificationRequest {

    @NotBlank(message = "El correo es obligatorio")
    @Email(message = "El correo no es válido")
    private String email;

    @NotBlank(message = "El asunto es obligatorio")
    @Size(max = 200, message = "El asunto no puede superar 200 caracteres")
    private String subject;

    @NotBlank(message = "El mensaje es obligatorio")
    @Size(max = 5000, message = "El mensaje no puede superar 5000 caracteres")
    private String message;

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}