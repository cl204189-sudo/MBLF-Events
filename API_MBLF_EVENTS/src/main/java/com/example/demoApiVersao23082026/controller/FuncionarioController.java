package com.example.demoApiVersao23082026.controller;

import com.example.demoApiVersao23082026.model.*;
import com.example.demoApiVersao23082026.repository.FuncionarioPermissaoRepository;
import com.example.demoApiVersao23082026.repository.UsuarioRepository;
import com.example.demoApiVersao23082026.repository.EventoRepository;
import com.example.demoApiVersao23082026.repository.HistoricoAdministrativoRepository;
import com.example.demoApiVersao23082026.exception.NotFoundException;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.access.AccessDeniedException;
import com.example.demoApiVersao23082026.service.UsuarioAutenticadoService;
import com.example.demoApiVersao23082026.exception.BadRequestException;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import com.example.demoApiVersao23082026.dto.UsuarioDTO;
import com.example.demoApiVersao23082026.dto.EventoDTO;
import com.example.demoApiVersao23082026.service.UsuarioService;
import com.example.demoApiVersao23082026.service.EventoService;

@RestController
@RequestMapping("/funcionario")
public class FuncionarioController {
    private final UsuarioAutenticadoService autenticado;
    private final FuncionarioPermissaoRepository permissoes;
    public FuncionarioController(UsuarioAutenticadoService autenticado, FuncionarioPermissaoRepository permissoes) {
        this.autenticado = autenticado;
        this.permissoes = permissoes;
    }
    @org.springframework.beans.factory.annotation.Autowired private UsuarioService usuarios;
    @org.springframework.beans.factory.annotation.Autowired private EventoService eventos;
    @org.springframework.beans.factory.annotation.Autowired private UsuarioRepository usuarioRepository;
    @org.springframework.beans.factory.annotation.Autowired private EventoRepository eventoRepository;
    @org.springframework.beans.factory.annotation.Autowired private HistoricoAdministrativoRepository historicoRepository;

    private void historico(String acao, String entidade, Integer id, String descricao) {
        HistoricoAdministrativo h = new HistoricoAdministrativo();
        h.setUsuario(autenticado.getUsuarioAutenticado());
        h.setAcao(acao);
        h.setEntidade(entidade);
        h.setEntidadeId(id);
        h.setDescricao(descricao);
        historicoRepository.save(h);
    }

    @PutMapping("/usuarios/{id}/bloquear")
    @Transactional
    public void bloquear(@PathVariable Integer id) { alterarBloqueio(id, false); }

    @PutMapping("/usuarios/{id}/desbloquear")
    @Transactional
    public void desbloquear(@PathVariable Integer id) { alterarBloqueio(id, true); }

    private void alterarBloqueio(Integer id, boolean ativar) {
        exigir("bloquearUsuarios");
        Usuario alvo = usuarioRepository.findById(id).orElseThrow(() -> new NotFoundException("Usuário não encontrado"));
        if (alvo.getId().equals(autenticado.getUsuarioAutenticado().getId()) ||
            "ADMIN".equals(alvo.getPerfil().getNome()) || "FUNCIONARIO".equals(alvo.getPerfil().getNome())) {
            throw new AccessDeniedException("Funcionários não podem alterar contas administrativas ou a própria conta");
        }
        alvo.setAtivo(ativar);
        usuarioRepository.save(alvo);
        historico(ativar ? "FUNCIONARIO_DESBLOQUEAR_USUARIO" : "FUNCIONARIO_BLOQUEAR_USUARIO", "USUARIO", id, "Alteração de acesso por funcionário");
    }

    @PutMapping("/eventos/{id}/remover")
    @Transactional
    public void removerEvento(@PathVariable Integer id, @RequestParam String motivo) {
        exigir("moderarEventos");
        if (motivo == null || motivo.isBlank()) throw new BadRequestException("Motivo obrigatório");
        Evento evento = eventoRepository.findById(id).orElseThrow(() -> new NotFoundException("Evento não encontrado"));
        if (Evento.Status.REMOVIDO_ADMIN.equals(evento.getStatus())) throw new BadRequestException("Evento já removido");
        evento.setStatus(Evento.Status.REMOVIDO_ADMIN);
        evento.setInscricoesAbertas(false);
        evento.setMotivoRemocao(motivo.trim());
        eventoRepository.save(evento);
        historico("FUNCIONARIO_REMOVER_EVENTO", "EVENTO", id, motivo.trim());
    }


    private void exigir(String permissao) {
        if (!Boolean.TRUE.equals(minhasPermissoes().get(permissao))) {
            throw new org.springframework.security.access.AccessDeniedException("Permissão insuficiente: " + permissao);
        }
    }

    @GetMapping("/usuarios")
    public List<UsuarioDTO> listarUsuarios() {
        exigir("visualizarUsuarios");
        return usuarios.listarTodos();
    }

    @GetMapping("/eventos")
    public List<EventoDTO> listarEventos() {
        exigir("visualizarEventos");
        return eventos.listarTodos();
    }

    @GetMapping("/minhas-permissoes")
    public Map<String, Boolean> minhasPermissoes() {
        Usuario usuario = autenticado.getUsuarioAutenticado();
        if (!"FUNCIONARIO".equals(usuario.getPerfil().getNome()) || !Boolean.TRUE.equals(usuario.getAtivo())) {
            throw new BadRequestException("Acesso exclusivo para funcionário ativo");
        }
        FuncionarioPermissao p = permissoes.findById(usuario.getId()).orElse(null);
        Map<String, Boolean> r = new LinkedHashMap<>();
        r.put("visualizarUsuarios", p != null && Boolean.TRUE.equals(p.getVisualizarUsuarios()));
        r.put("bloquearUsuarios", p != null && Boolean.TRUE.equals(p.getBloquearUsuarios()));
        r.put("visualizarEventos", p != null && Boolean.TRUE.equals(p.getVisualizarEventos()));
        r.put("moderarEventos", p != null && Boolean.TRUE.equals(p.getModerarEventos()));
        r.put("visualizarPagamentos", p != null && Boolean.TRUE.equals(p.getVisualizarPagamentos()));
        r.put("gerenciarPlanos", p != null && Boolean.TRUE.equals(p.getGerenciarPlanos()));
        return r;
    }
}
