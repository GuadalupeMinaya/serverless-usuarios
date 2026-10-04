package com.utesa.usuariosapi.infrastructure.adapter.in.rest;

import com.utesa.usuariosapi.infrastructure.storage.FileStorageService;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

@RestController
public class FilesController {

    private final FileStorageService storage;

    public FilesController(FileStorageService storage) {
        this.storage = storage;
    }

    @GetMapping("/files/{nombre}")
    public ResponseEntity<Resource> obtener(@PathVariable String nombre) {
        ResponseBytes<GetObjectResponse> obj = storage.obtener(nombre);
        String tipo = obj.response().contentType();
        return ResponseEntity.ok()
                .contentType(tipo != null ? MediaType.parseMediaType(tipo)
                                          : MediaType.APPLICATION_OCTET_STREAM)
                .body(new ByteArrayResource(obj.asByteArray()));
    }
}