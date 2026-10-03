package com.utesa.usuariosapi.infrastructure.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Service
public class FileStorageService {

    private static final Set<String> EXTENSIONES_PERMITIDAS =
            Set.of("jpg", "jpeg", "png", "gif", "webp", "pdf", "doc", "docx", "txt");

    private final Path directorio;

    public FileStorageService(@Value("${app.upload.dir}") String dir) throws IOException {
        this.directorio = Paths.get(dir).toAbsolutePath().normalize();
        Files.createDirectories(this.directorio);
    }

    public Path getDirectorio() {
        return directorio;
    }

    public String guardar(MultipartFile archivo) {
        if (archivo == null || archivo.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El archivo está vacío");
        }

        String original = archivo.getOriginalFilename() == null ? "" : archivo.getOriginalFilename();
        int punto = original.lastIndexOf('.');
        String extension = punto >= 0 ? original.substring(punto + 1).toLowerCase(Locale.ROOT) : "";

        if (!EXTENSIONES_PERMITIDAS.contains(extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Tipo de archivo no permitido. Permitidos: " + EXTENSIONES_PERMITIDAS);
        }

        String nombreFinal = UUID.randomUUID() + "." + extension;
        Path destino = directorio.resolve(nombreFinal).normalize();

        try (InputStream in = archivo.getInputStream()) {
            Files.copy(in, destino, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "No se pudo guardar el archivo");
        }
        return nombreFinal;
    }
}