package com.utesa.usuariosapi.infrastructure.adapter.in.rest;

import com.utesa.usuariosapi.application.port.in.UsuarioServicePort;
import com.utesa.usuariosapi.domain.Usuario;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioServicePort usuarioServicePort;
    private final PasswordEncoder passwordEncoder;

    public UsuarioController(UsuarioServicePort usuarioServicePort, PasswordEncoder passwordEncoder) {
        this.usuarioServicePort = usuarioServicePort;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Usuario crear(@RequestBody Usuario usuario) {
        usuario.setPassword(passwordEncoder.encode(usuario.getPassword()));
        return usuarioServicePort.crear(usuario);
    }

    @GetMapping
    public List<Usuario> listarTodos() {
        return usuarioServicePort.listarTodos();
    }

    @GetMapping("/{id}")
    public Usuario buscarPorId(@PathVariable Long id) {
        return usuarioServicePort.buscarPorId(id);
    }

    @PutMapping("/{id}")
    public Usuario actualizar(@PathVariable Long id, @RequestBody Usuario usuario) {
        if (usuario.getPassword() != null && !usuario.getPassword().isBlank()) {
            usuario.setPassword(passwordEncoder.encode(usuario.getPassword()));
        } else {
            usuario.setPassword(null); // no cambiar la contraseña si no mandan una nueva
        }
        return usuarioServicePort.actualizar(id, usuario);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(@PathVariable Long id) {
        usuarioServicePort.eliminar(id);
    }
}