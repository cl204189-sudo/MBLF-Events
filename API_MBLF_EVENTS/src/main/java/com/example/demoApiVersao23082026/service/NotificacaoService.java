package com.example.demoApiVersao23082026.service;

import com.example.demoApiVersao23082026.dto.NotificacaoDTO;
import com.example.demoApiVersao23082026.exception.BadRequestException;
import com.example.demoApiVersao23082026.exception.NotFoundException;
import com.example.demoApiVersao23082026.model.Notificacao;
import com.example.demoApiVersao23082026.model.Usuario;
import com.example.demoApiVersao23082026.repository.NotificacaoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificacaoService {

    @Autowired
    private NotificacaoRepository repository;

    @Autowired
    private UsuarioAutenticadoService usuarioAutenticadoService;

    public List<NotificacaoDTO> minhasNotificacoes() {

        Usuario usuario =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        return repository
                .findByUsuarioIdOrderByDataCriacaoDesc(
                        usuario.getId()
                )
                .stream()
                .map(this::converterParaDTO)
                .toList();
    }

    public NotificacaoDTO marcarComoLida(
            Integer id) {

        Usuario usuario =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        Notificacao notificacao =
                repository.findById(id)
                        .orElseThrow(() ->
                                new NotFoundException(
                                        "Notificação não encontrada"
                                ));

        if (!notificacao.getUsuario()
                .getId()
                .equals(usuario.getId())) {

            throw new BadRequestException(
                    "Esta notificação não pertence ao usuário autenticado"
            );
        }

        notificacao.setLida(true);

        return converterParaDTO(
                repository.save(notificacao)
        );
    }

    private NotificacaoDTO converterParaDTO(
            Notificacao notificacao) {

        return new NotificacaoDTO(
                notificacao.getId(),

                notificacao.getEvento() != null
                        ? notificacao.getEvento().getId()
                        : null,

                notificacao.getTipo().name(),

                notificacao.getTitulo(),
                notificacao.getMensagem(),

                notificacao.getLida(),

                notificacao.getDataCriacao()
        );
    }
}