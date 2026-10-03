package com.utesa.usuariosapi.application;

import com.utesa.usuariosapi.application.port.in.UsuarioServicePort;
import com.utesa.usuariosapi.application.port.out.UsuarioRepositoryPort;
import com.utesa.usuariosapi.domain.Usuario;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UsuarioService implements UsuarioServicePort {

    private final UsuarioRepositoryPort usuarioRepositoryPort;

    public UsuarioService(UsuarioRepositoryPort usuarioRepositoryPort) {
        this.usuarioRepositoryPort = usuarioRepositoryPort;
    }

    @Override
    public Usuario crear(Usuario usuario) {
        return usuarioRepositoryPort.guardar(usuario);
    }

    @Override
    public Usuario buscarPorId(Long id) {
        return usuarioRepositoryPort.buscarPorId(id)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado con id: " + id));
    }

    @Override
    public List<Usuario> listarTodos() {
        return usuarioRepositoryPort.listarTodos();
    }

    @Override
    public Usuario actualizar(Long id, Usuario usuario) {
        Usuario existente = buscarPorId(id);
        existente.setNombre(usuario.getNombre());
        existente.setEmail(usuario.getEmail());
        if (usuario.getPassword() != null && !usuario.getPassword().isBlank()) {
            existente.setPassword(usuario.getPassword());
        }
        if (usuario.getFotoUrl() != null) {
            existente.setFotoUrl(usuario.getFotoUrl());
        }
        return usuarioRepositoryPort.guardar(existente);
    }

    @Override
    public void eliminar(Long id) {
        buscarPorId(id);
        usuarioRepositoryPort.eliminar(id);
    }
}