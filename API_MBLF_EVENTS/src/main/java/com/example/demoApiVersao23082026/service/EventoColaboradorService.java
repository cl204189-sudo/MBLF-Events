package com.example.demoApiVersao23082026.service;

import com.example.demoApiVersao23082026.dto.ConviteColaboradorDTO;
import com.example.demoApiVersao23082026.dto.EventoColaboradorDTO;
import com.example.demoApiVersao23082026.exception.BadRequestException;
import com.example.demoApiVersao23082026.exception.NotFoundException;
import com.example.demoApiVersao23082026.model.Evento;
import com.example.demoApiVersao23082026.model.EventoColaborador;
import com.example.demoApiVersao23082026.model.Notificacao;
import com.example.demoApiVersao23082026.model.Usuario;
import com.example.demoApiVersao23082026.repository.EventoColaboradorRepository;
import com.example.demoApiVersao23082026.repository.EventoRepository;
import com.example.demoApiVersao23082026.repository.NotificacaoRepository;
import com.example.demoApiVersao23082026.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.demoApiVersao23082026.dto.PermissaoColaboradorDTO;
import com.example.demoApiVersao23082026.dto.ConviteColaboradorEmailDTO;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class EventoColaboradorService {

    @Autowired
    private EventoColaboradorRepository repository;

    @Autowired
    private EventoRepository eventoRepository;

    @Autowired
    private UsuarioAutenticadoService usuarioAutenticadoService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private NotificacaoRepository notificacaoRepository;

    public List<EventoColaboradorDTO> listarMeus() {

        Usuario usuario =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        return repository
                .findByUsuarioId(
                        usuario.getId()
                )
                .stream()
                .map(this::converterParaDTO)
                .toList();
    }

    public EventoColaboradorDTO convidar(
            Integer eventoId,
            ConviteColaboradorDTO dto) {

        Evento evento = eventoRepository
                .findById(eventoId)
                .orElseThrow(() ->
                        new NotFoundException(
                                "Evento não encontrado"
                        ));

        Usuario usuarioAutenticado =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        if (!evento.getOrganizador()
                .getId()
                .equals(usuarioAutenticado.getId())) {

            throw new BadRequestException(
                    "Somente o organizador pode convidar colaboradores"
            );
        }

        if (evento.getHubAte() == null ||
                evento.getHubAte()
                        .isBefore(LocalDateTime.now())) {

            throw new BadRequestException(
                    "O Hub deste evento não está ativo"
            );
        }

        if (evento.getOrganizador()
                .getId()
                .equals(dto.getUsuarioConvidadoId())) {

            throw new BadRequestException(
                    "O organizador não pode convidar a si mesmo"
            );
        }

        Usuario convidado = usuarioRepository
                .findById(dto.getUsuarioConvidadoId())
                .orElseThrow(() ->
                        new NotFoundException(
                                "Usuário convidado não encontrado"
                        ));

        EventoColaborador colaborador = prepararNovoConvite(
                evento, convidado, dto.getFuncao());

        EventoColaborador salvo =
                repository.save(colaborador);

        Notificacao notificacao =
                new Notificacao();

        notificacao.setUsuario(convidado);
        notificacao.setEvento(evento);

        notificacao.setTipo(
                Notificacao.Tipo.CONVITE_COLABORADOR
        );

        notificacao.setTitulo(
                "Novo convite para colaborar"
        );

        notificacao.setMensagem(
                usuarioAutenticado.getNome()
                        + " convidou você para colaborar no evento "
                        + evento.getTitulo()
        );

        notificacao.setLida(false);

        notificacaoRepository.save(notificacao);

        return converterParaDTO(salvo);
    }

    public EventoColaboradorDTO aceitar(
            Integer eventoId) {

        Usuario usuarioAutenticado =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        EventoColaborador colaborador =
                repository
                        .findByEventoIdAndUsuarioId(
                                eventoId,
                                usuarioAutenticado.getId()
                        )
                        .orElseThrow(() ->
                                new NotFoundException(
                                        "Convite não encontrado"
                                ));

        if (colaborador.getStatus()
                != EventoColaborador.Status.PENDENTE) {

            throw new BadRequestException(
                    "Este convite já foi respondido"
            );
        }

        colaborador.setStatus(
                EventoColaborador.Status.ACEITO
        );

        colaborador.setDataResposta(
                LocalDateTime.now()
        );

        EventoColaborador atualizado =
                repository.save(colaborador);

        criarNotificacaoParaOrganizador(
                colaborador,
                true
        );

        return converterParaDTO(atualizado);
    }

    public EventoColaboradorDTO recusar(
            Integer eventoId) {

        Usuario usuarioAutenticado =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        EventoColaborador colaborador =
                repository
                        .findByEventoIdAndUsuarioId(
                                eventoId,
                                usuarioAutenticado.getId()
                        )
                        .orElseThrow(() ->
                                new NotFoundException(
                                        "Convite não encontrado"
                                ));

        if (colaborador.getStatus()
                != EventoColaborador.Status.PENDENTE) {

            throw new BadRequestException(
                    "Este convite já foi respondido"
            );
        }

        colaborador.setStatus(
                EventoColaborador.Status.RECUSADO
        );

        colaborador.setDataResposta(
                LocalDateTime.now()
        );

        EventoColaborador atualizado =
                repository.save(colaborador);

        criarNotificacaoParaOrganizador(
                colaborador,
                false
        );

        return converterParaDTO(atualizado);
    }

    public EventoColaboradorDTO convidarPorEmail(
            Integer eventoId,
            ConviteColaboradorEmailDTO dto) {

        Evento evento = eventoRepository
                .findById(eventoId)
                .orElseThrow(() ->
                        new NotFoundException(
                                "Evento não encontrado"
                        ));

        Usuario usuarioAutenticado =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        if (!evento.getOrganizador()
                .getId()
                .equals(usuarioAutenticado.getId())) {

            throw new BadRequestException(
                    "Somente o organizador pode convidar colaboradores"
            );
        }

        if (evento.getHubAte() == null ||
                evento.getHubAte()
                        .isBefore(LocalDateTime.now())) {

            throw new BadRequestException(
                    "O Hub deste evento não está ativo"
            );
        }

        if (dto.getEmail() == null ||
                dto.getEmail().isBlank()) {

            throw new BadRequestException(
                    "Email é obrigatório"
            );
        }

        if (dto.getFuncao() == null ||
                dto.getFuncao().isBlank()) {

            throw new BadRequestException(
                    "Função é obrigatória"
            );
        }

        Usuario convidado =
                usuarioRepository
                        .findByEmail(dto.getEmail())
                        .orElseThrow(() ->
                                new NotFoundException(
                                        "Nenhum usuário encontrado com este email"
                                ));

        if (evento.getOrganizador()
                .getId()
                .equals(convidado.getId())) {

            throw new BadRequestException(
                    "O organizador não pode convidar a si mesmo"
            );
        }

        EventoColaborador colaborador = prepararNovoConvite(
                evento, convidado, dto.getFuncao());

        EventoColaborador salvo =
                repository.save(colaborador);

        Notificacao notificacao =
                new Notificacao();

        notificacao.setUsuario(convidado);
        notificacao.setEvento(evento);

        notificacao.setTipo(
                Notificacao.Tipo.CONVITE_COLABORADOR
        );

        notificacao.setTitulo(
                "Novo convite para colaborar"
        );

        notificacao.setMensagem(
                usuarioAutenticado.getNome()
                        + " convidou você para colaborar no evento "
                        + evento.getTitulo()
        );

        notificacao.setLida(false);

        notificacaoRepository.save(notificacao);

        return converterParaDTO(salvo);
    }

    /** Reutiliza o vínculo recusado/removido sem duplicar a inscrição na equipe. */
    private EventoColaborador prepararNovoConvite(Evento evento, Usuario convidado, String funcao) {
        EventoColaborador colaborador = repository
                .findByEventoIdAndUsuarioId(evento.getId(), convidado.getId())
                .orElseGet(EventoColaborador::new);

        if (colaborador.getId() != null
                && colaborador.getStatus() != EventoColaborador.Status.RECUSADO
                && colaborador.getStatus() != EventoColaborador.Status.EXPULSO) {
            throw new BadRequestException("Este usuário já possui convite ou vínculo ativo com este evento");
        }

        colaborador.setEvento(evento);
        colaborador.setUsuario(convidado);
        colaborador.setFuncao(funcao);
        colaborador.setStatus(EventoColaborador.Status.PENDENTE);
        colaborador.setDataResposta(null);
        colaborador.setPodeChat(false);
        colaborador.setPodeCalendario(false);
        colaborador.setPodeTarefas(false);
        colaborador.setPodeVerInscritos(false);
        colaborador.setPodeRegistrarPresencas(false);
        colaborador.setPodeVerRelatorios(false);
        colaborador.setPodeSilenciar(false);
        colaborador.setPodeExpulsar(false);
        colaborador.setPodeLiberarCertificados(false);
        colaborador.setSilenciado(false);
        colaborador.setSilenciadoAte(null);
        return colaborador;
    }

    @org.springframework.transaction.annotation.Transactional
    public EventoColaboradorDTO remover(Integer eventoId, Integer usuarioId) {
        Evento evento = eventoRepository.findById(eventoId)
                .orElseThrow(() -> new NotFoundException("Evento não encontrado"));
        Usuario operador = usuarioAutenticadoService.getUsuarioAutenticado();
        if (!evento.getOrganizador().getId().equals(operador.getId())) {
            throw new BadRequestException("Somente o organizador pode remover colaboradores");
        }
        EventoColaborador colaborador = repository.findByEventoIdAndUsuarioId(eventoId, usuarioId)
                .orElseThrow(() -> new NotFoundException("Colaborador não encontrado"));
        if (colaborador.getStatus() != EventoColaborador.Status.ACEITO &&
                colaborador.getStatus() != EventoColaborador.Status.PENDENTE) {
            throw new BadRequestException("Colaborador já não está ativo");
        }
        // Revogação lógica: mantém histórico, retira permissões imediatamente.
        colaborador.setStatus(EventoColaborador.Status.EXPULSO);
        colaborador.setDataResposta(LocalDateTime.now());
        colaborador.setPodeChat(false);
        colaborador.setPodeCalendario(false);
        colaborador.setPodeTarefas(false);
        colaborador.setPodeVerInscritos(false);
        colaborador.setPodeRegistrarPresencas(false);
        colaborador.setPodeVerRelatorios(false);
        colaborador.setPodeSilenciar(false);
        colaborador.setPodeExpulsar(false);
        colaborador.setPodeLiberarCertificados(false);
        return converterParaDTO(repository.save(colaborador));
    }

    public List<EventoColaboradorDTO> listarPorEvento(
            Integer eventoId) {

        return repository.findByEventoId(eventoId)
                .stream()
                .map(this::converterParaDTO)
                .toList();
    }

    private void criarNotificacaoParaOrganizador(
            EventoColaborador colaborador,
            boolean aceitou) {

        Notificacao notificacao =
                new Notificacao();

        notificacao.setUsuario(
                colaborador.getEvento()
                        .getOrganizador()
        );

        notificacao.setEvento(
                colaborador.getEvento()
        );

        if (aceitou) {

            notificacao.setTipo(
                    Notificacao.Tipo.CONVITE_ACEITO
            );

            notificacao.setTitulo(
                    "Convite aceito"
            );

            notificacao.setMensagem(
                    colaborador.getUsuario().getNome()
                            + " aceitou o convite para colaborar no evento "
                            + colaborador.getEvento().getTitulo()
            );

        } else {

            notificacao.setTipo(
                    Notificacao.Tipo.CONVITE_RECUSADO
            );

            notificacao.setTitulo(
                    "Convite recusado"
            );

            notificacao.setMensagem(
                    colaborador.getUsuario().getNome()
                            + " recusou o convite para colaborar no evento "
                            + colaborador.getEvento().getTitulo()
            );
        }

        notificacao.setLida(false);

        notificacaoRepository.save(notificacao);
    }

    public EventoColaboradorDTO alterarPermissoes(
            Integer eventoId,
            Integer colaboradorUsuarioId,
            PermissaoColaboradorDTO dto) {

        Evento evento = eventoRepository
                .findById(eventoId)
                .orElseThrow(() ->
                        new NotFoundException(
                                "Evento não encontrado"
                        ));

        Usuario usuarioAutenticado =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        if (!evento.getOrganizador()
                .getId()
                .equals(usuarioAutenticado.getId())) {

            throw new BadRequestException(
                    "Somente o organizador pode alterar permissões"
            );
        }

        EventoColaborador colaborador = repository
                .findByEventoIdAndUsuarioId(
                        eventoId,
                        colaboradorUsuarioId
                )
                .orElseThrow(() ->
                        new NotFoundException(
                                "Colaborador não encontrado"
                        ));

        if (colaborador.getStatus()
                != EventoColaborador.Status.ACEITO) {

            throw new BadRequestException(
                    "Somente colaboradores aceitos podem receber permissões"
            );
        }

        if (Boolean.TRUE.equals(
                dto.getPodeLiberarCertificados())) {

            boolean jaTinhaPermissao =
                    Boolean.TRUE.equals(
                            colaborador.getPodeLiberarCertificados()
                    );

            if (!jaTinhaPermissao) {

                long quantidade =
                        repository
                                .countByEventoIdAndPodeLiberarCertificadosTrue(
                                        eventoId
                                );

                if (quantidade >= 2) {
                    throw new BadRequestException(
                            "No máximo 2 colaboradores podem liberar certificados"
                    );
                }
            }
        }

        if (dto.getPodeChat() != null) {
            colaborador.setPodeChat(dto.getPodeChat());
        }

        if (dto.getPodeCalendario() != null) {
            colaborador.setPodeCalendario(dto.getPodeCalendario());
        }

        if (dto.getPodeTarefas() != null) {
            colaborador.setPodeTarefas(dto.getPodeTarefas());
        }

        if (dto.getPodeVerInscritos() != null) {
            colaborador.setPodeVerInscritos(dto.getPodeVerInscritos());
        }

        if (dto.getPodeRegistrarPresencas() != null) {
            colaborador.setPodeRegistrarPresencas(
                    dto.getPodeRegistrarPresencas()
            );
        }

        if (dto.getPodeVerRelatorios() != null) {
            colaborador.setPodeVerRelatorios(
                    dto.getPodeVerRelatorios()
            );
        }

        if (dto.getPodeSilenciar() != null) {
            colaborador.setPodeSilenciar(
                    dto.getPodeSilenciar()
            );
        }

        if (dto.getPodeExpulsar() != null) {
            colaborador.setPodeExpulsar(
                    dto.getPodeExpulsar()
            );
        }

        if (dto.getPodeLiberarCertificados() != null) {
            colaborador.setPodeLiberarCertificados(
                    dto.getPodeLiberarCertificados()
            );
        }

        return converterParaDTO(
                repository.save(colaborador)
        );
    }



    private EventoColaboradorDTO converterParaDTO(
            EventoColaborador colaborador) {

        return new EventoColaboradorDTO(
                colaborador.getId(),

                colaborador.getEvento().getId(),
                colaborador.getEvento().getTitulo(),

                colaborador.getUsuario().getId(),
                colaborador.getUsuario().getNome(),

                colaborador.getFuncao(),
                colaborador.getStatus().name(),

                colaborador.getPodeChat(),
                colaborador.getPodeCalendario(),
                colaborador.getPodeTarefas(),

                colaborador.getPodeVerInscritos(),
                colaborador.getPodeRegistrarPresencas(),
                colaborador.getPodeVerRelatorios(),

                colaborador.getPodeSilenciar(),
                colaborador.getPodeExpulsar(),
                colaborador.getPodeLiberarCertificados(),

                colaborador.getSilenciado()
        );
    }
    }
