class AgendaEvento {
  final int id;
  final int eventoId;
  final String titulo;
  final String descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String tipo;

  AgendaEvento({
    required this.id,
    required this.eventoId,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.tipo,
  });

  factory AgendaEvento.fromJson(
    Map<String, dynamic> json,
  ) {
    return AgendaEvento(
      id: json['id'],
      eventoId: json['eventoId'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      dataInicio: DateTime.parse(
        json['dataInicio'],
      ),
      dataFim: json['dataFim'] != null
          ? DateTime.parse(
              json['dataFim'],
            )
          : null,
      tipo: json['tipo'] ?? 'OUTRO',
    );
  }
}