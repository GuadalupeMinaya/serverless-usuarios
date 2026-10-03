package com.utesa.usuariosapi.application.port.out;

import com.utesa.usuariosapi.domain.Usuario;

import java.util.List;
import java.util.Optional;

public interface UsuarioRepositoryPort {

    Usuario guardar(Usuario usuario);

    Optional<Usuario> buscarPorId(Long id);

    Optional<Usuario> buscarPorEmail(String email);

    List<Usuario> listarTodos();

    void eliminar(Long id);
}