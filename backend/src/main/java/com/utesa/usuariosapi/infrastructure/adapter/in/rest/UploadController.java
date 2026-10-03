package com.utesa.usuariosapi.infrastructure.adapter.in.rest;

import com.utesa.usuariosapi.infrastructure.adapter.out.persistence.ArchivoEntity;
import com.utesa.usuariosapi.infrastructure.adapter.out.persistence.ArchivoJpaRepository;
import com.utesa.usuariosapi.infrastructure.storage.FileStorageService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;
import java.util.Map;

@RestController
public class UploadController {

    private final FileStorageService storage;
    private final ArchivoJpaRepository archivoRepository;

    public UploadController(FileStorageService storage, ArchivoJpaRepository archivoRepository) {
        this.storage = storage;
        this.archivoRepository = archivoRepository;
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> subir(@RequestParam("file") MultipartFile file) {
        String nombreGuardado = storage.guardar(file);

        String url = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/files/").path(nombreGuardado).toUriString();

        ArchivoEntity entity = new ArchivoEntity();
        entity.setNombreOriginal(file.getOriginalFilename() == null ? nombreGuardado : file.getOriginalFilename());
        entity.setNombreArchivo(nombreGuardado);
        entity.setUrl(url);
        entity.setContentType(file.getContentType());
        entity.setTamano(file.getSize());
        ArchivoEntity guardado = archivoRepository.save(entity);

        return Map.of(
                "id", guardado.getId(),
                "nombreOriginal", guardado.getNombreOriginal(),
                "nombreArchivo", guardado.getNombreArchivo(),
                "url", guardado.getUrl(),
                "contentType", guardado.getContentType() == null ? "" : guardado.getContentType(),
                "tamano", guardado.getTamano()
        );
    }

    @GetMapping("/upload")
    public List<ArchivoEntity> listar() {
        return archivoRepository.findAll();
    }
}