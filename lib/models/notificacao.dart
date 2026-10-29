class Notificacao {
  final int id;
  final int? eventoId;
  final String tipo;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? dataCriacao;

  Notificacao({
    required this.id,
    required this.eventoId,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.dataCriacao,
  });

  factory Notificacao.fromJson(
    Map<String, dynamic> json,
  ) {
    return Notificacao(
      id: json['id'],
      eventoId: json['eventoId'],
      tipo: json['tipo'] ?? '',
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      lida: json['lida'] ?? false,
      dataCriacao:
          json['dataCriacao'] != null
              ? DateTime.parse(
                  json['dataCriacao'],
                )
              : null,
    );
  }
}