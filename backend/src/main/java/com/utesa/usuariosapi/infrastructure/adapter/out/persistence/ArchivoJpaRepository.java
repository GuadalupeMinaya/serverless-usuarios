package com.utesa.usuariosapi.infrastructure.adapter.out.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ArchivoJpaRepository extends JpaRepository<ArchivoEntity, Long> {
}