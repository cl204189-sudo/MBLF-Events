package com.example.demoApiVersao23082026.service;
import com.example.demoApiVersao23082026.model.*;
import com.example.demoApiVersao23082026.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.HashSet;
import java.util.Set;
@Service
public class NotificacaoEventoService {
 @Autowired private NotificacaoRepository notificacoes;
 @Autowired private InscricaoRepository inscricoes;
 public void avisar(Usuario usuario, Evento evento, Notificacao.Tipo tipo, String titulo, String mensagem) {
  if (usuario == null) return;
  Notificacao n = new Notificacao();
  n.setUsuario(usuario); n.setEvento(evento); n.setTipo(tipo);
  n.setTitulo(titulo); n.setMensagem(mensagem); n.setLida(false);
  notificacoes.save(n);
 }
 public void avisarInscritos(Evento evento, Notificacao.Tipo tipo, String titulo, String mensagem) {
  Set<Integer> enviados = new HashSet<>();
  for (Inscricao i : inscricoes.findByEventoId(evento.getId())) {
   if (i.getStatus() != Inscricao.Status.INSCRITO && i.getStatus() != Inscricao.Status.PRESENTE) continue;
   if (enviados.add(i.getUsuario().getId())) avisar(i.getUsuario(), evento, tipo, titulo, mensagem);
  }
 }
}
