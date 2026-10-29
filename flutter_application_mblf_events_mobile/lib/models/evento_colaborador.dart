class EventoColaborador {
  final int id;
  final int eventoId;
  final String eventoTitulo;

  final int usuarioId;
  final String usuarioNome;

  final String funcao;
  final String status;

  final bool podeChat;
  final bool podeCalendario;
  final bool podeTarefas;
  final bool podeVerInscritos;
  final bool podeRegistrarPresencas;
  final bool podeVerRelatorios;
  final bool podeSilenciar;
  final bool podeExpulsar;
  final bool podeLiberarCertificados;
  final bool silenciado;

  EventoColaborador({
    required this.id,
    required this.eventoId,
    required this.eventoTitulo,
    required this.usuarioId,
    required this.usuarioNome,
    required this.funcao,
    required this.status,
    required this.podeChat,
    required this.podeCalendario,
    required this.podeTarefas,
    required this.podeVerInscritos,
    required this.podeRegistrarPresencas,
    required this.podeVerRelatorios,
    required this.podeSilenciar,
    required this.podeExpulsar,
    required this.podeLiberarCertificados,
    required this.silenciado,
  });

  factory EventoColaborador.fromJson(
    Map<String, dynamic> json,
  ) {
    return EventoColaborador(
      id: json['id'],
      eventoId: json['eventoId'],
      eventoTitulo: json['eventoTitulo'] ?? '',
      usuarioId: json['usuarioId'],
      usuarioNome: json['usuarioNome'] ?? '',
      funcao: json['funcao'] ?? '',
      status: json['status'] ?? '',
      podeChat: json['podeChat'] ?? false,
      podeCalendario: json['podeCalendario'] ?? false,
      podeTarefas: json['podeTarefas'] ?? false,
      podeVerInscritos: json['podeVerInscritos'] ?? false,
      podeRegistrarPresencas:
          json['podeRegistrarPresencas'] ?? false,
      podeVerRelatorios:
          json['podeVerRelatorios'] ?? false,
      podeSilenciar: json['podeSilenciar'] ?? false,
      podeExpulsar: json['podeExpulsar'] ?? false,
      podeLiberarCertificados:
          json['podeLiberarCertificados'] ?? false,
      silenciado: json['silenciado'] ?? false,
    );
  }
}