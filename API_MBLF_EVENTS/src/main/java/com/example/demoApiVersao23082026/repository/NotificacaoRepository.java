package com.example.demoApiVersao23082026.repository;

import com.example.demoApiVersao23082026.model.Notificacao;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificacaoRepository
        extends JpaRepository<Notificacao, Integer> {

    List<Notificacao>
    findByUsuarioIdOrderByDataCriacaoDesc(
            Integer usuarioId
    );
}