class TarefaEvento {
  final int id;
  final int eventoId;

  final int criadoPorId;
  final String criadoPorNome;

  final int? responsavelId;
  final String? responsavelNome;

  final String titulo;
  final String descricao;

  final String prioridade;
  final String status;

  final DateTime? prazo;
  final DateTime? dataConclusao;

  TarefaEvento({
    required this.id,
    required this.eventoId,
    required this.criadoPorId,
    required this.criadoPorNome,
    required this.responsavelId,
    required this.responsavelNome,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.status,
    required this.prazo,
    required this.dataConclusao,
  });

  factory TarefaEvento.fromJson(
    Map<String, dynamic> json,
  ) {
    return TarefaEvento(
      id: json['id'],
      eventoId: json['eventoId'],
      criadoPorId: json['criadoPorId'],
      criadoPorNome: json['criadoPorNome'] ?? '',
      responsavelId: json['responsavelId'],
      responsavelNome: json['responsavelNome'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      prioridade: json['prioridade'] ?? 'MEDIA',
      status: json['status'] ?? 'PENDENTE',
      prazo: json['prazo'] != null
          ? DateTime.parse(json['prazo'])
          : null,
      dataConclusao:
          json['dataConclusao'] != null
              ? DateTime.parse(
                  json['dataConclusao'],
                )
              : null,
    );
  }
}