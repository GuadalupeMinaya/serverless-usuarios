package com.utesa.usuariosapi.infrastructure.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.util.UUID;

@Service
public class FileStorageService {

    private final S3Client s3;
    private final String bucket;

    public FileStorageService(@Value("${app.s3.bucket}") String bucket) {
        this.bucket = bucket;
        this.s3 = S3Client.create();
    }

    public String guardar(MultipartFile archivo) throws IOException {
        String original = archivo.getOriginalFilename();
        String ext = (original != null && original.contains("."))
                ? original.substring(original.lastIndexOf('.')) : "";
        String nombre = UUID.randomUUID() + ext;

        PutObjectRequest req = PutObjectRequest.builder()
                .bucket(bucket)
                .key(nombre)
                .contentType(archivo.getContentType())
                .build();
        s3.putObject(req, RequestBody.fromBytes(archivo.getBytes()));
        return nombre;
    }

    public ResponseBytes<GetObjectResponse> obtener(String nombre) {
        try {
            return s3.getObjectAsBytes(GetObjectRequest.builder()
                    .bucket(bucket)
                    .key(nombre)
                    .build());
        } catch (NoSuchKeyException e) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Archivo no encontrado");
        }
    }
}