package com.utesa.usuariosapi.infrastructure.adapter.out.persistence;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "archivos")
public class ArchivoEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombreOriginal;

    @Column(nullable = false, unique = true)
    private String nombreArchivo;

    @Column(nullable = false)
    private String url;

    private String contentType;

    private long tamano;

    @Column(nullable = false)
    private LocalDateTime fechaSubida = LocalDateTime.now();

    public ArchivoEntity() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNombreOriginal() { return nombreOriginal; }
    public void setNombreOriginal(String nombreOriginal) { this.nombreOriginal = nombreOriginal; }

    public String getNombreArchivo() { return nombreArchivo; }
    public void setNombreArchivo(String nombreArchivo) { this.nombreArchivo = nombreArchivo; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public long getTamano() { return tamano; }
    public void setTamano(long tamano) { this.tamano = tamano; }

    public LocalDateTime getFechaSubida() { return fechaSubida; }
    public void setFechaSubida(LocalDateTime fechaSubida) { this.fechaSubida = fechaSubida; }
}