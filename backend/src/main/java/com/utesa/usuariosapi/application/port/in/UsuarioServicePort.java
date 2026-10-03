package com.utesa.usuariosapi.application.port.in;

import com.utesa.usuariosapi.domain.Usuario;

import java.util.List;

public interface UsuarioServicePort {

    Usuario crear(Usuario usuario);

    Usuario buscarPorId(Long id);

    List<Usuario> listarTodos();

    Usuario actualizar(Long id, Usuario usuario);

    void eliminar(Long id);
}