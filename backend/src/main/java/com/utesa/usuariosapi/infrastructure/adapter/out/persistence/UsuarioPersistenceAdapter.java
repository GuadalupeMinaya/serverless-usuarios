package com.utesa.usuariosapi.infrastructure.adapter.out.persistence;

import com.utesa.usuariosapi.application.port.out.UsuarioRepositoryPort;
import com.utesa.usuariosapi.domain.Usuario;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
public class UsuarioPersistenceAdapter implements UsuarioRepositoryPort {

    private final UsuarioJpaRepository jpaRepository;

    public UsuarioPersistenceAdapter(UsuarioJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Usuario guardar(Usuario usuario) {
        UsuarioEntity entity = new UsuarioEntity(usuario.getId(), usuario.getNombre(), usuario.getEmail(), usuario.getPassword(), usuario.getFotoUrl());
        UsuarioEntity guardado = jpaRepository.save(entity);
        return toDomain(guardado);
    }

    @Override
    public Optional<Usuario> buscarPorId(Long id) {
        return jpaRepository.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<Usuario> buscarPorEmail(String email) {
        return jpaRepository.findByEmail(email).map(this::toDomain);
    }

    @Override
    public List<Usuario> listarTodos() {
        return jpaRepository.findAll().stream().map(this::toDomain).toList();
    }

    @Override
    public void eliminar(Long id) {
        jpaRepository.deleteById(id);
    }

    private Usuario toDomain(UsuarioEntity entity) {
        return new Usuario(entity.getId(), entity.getNombre(), entity.getEmail(), entity.getPassword(), entity.getFotoUrl());
    }
}