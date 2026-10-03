package com.utesa.usuariosapi.domain;

public class Usuario {

    private Long id;
    private String nombre;
    private String email;
    private String password;
    private String fotoUrl;

    public Usuario() {
    }

    public Usuario(Long id, String nombre, String email, String password) {
        this(id, nombre, email, password, null);
    }

    public Usuario(Long id, String nombre, String email, String password, String fotoUrl) {
        this.id = id;
        this.nombre = nombre;
        this.email = email;
        this.password = password;
        this.fotoUrl = fotoUrl;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getFotoUrl() {
        return fotoUrl;
    }

    public void setFotoUrl(String fotoUrl) {
        this.fotoUrl = fotoUrl;
    }
}