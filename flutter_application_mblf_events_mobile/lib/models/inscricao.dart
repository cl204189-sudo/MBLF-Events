class Inscricao {
  final int id;

  final int usuarioId;
  final String usuarioNome;

  final int eventoId;
  final String eventoTitulo;

  final String status;
  final String tokenQr;

  final DateTime? dataInscricao;

  final DateTime? dataCancelamento;

  Inscricao({
    required this.id,
    required this.usuarioId,
    required this.usuarioNome,
    required this.eventoId,
    required this.eventoTitulo,
    required this.status,
    required this.tokenQr,
    this.dataInscricao,
    required this.dataCancelamento,
  });

  factory Inscricao.fromJson(
    Map<String, dynamic> json,
  ) {
    return Inscricao(
      id: json['id'],
      usuarioId: json['usuarioId'],
      usuarioNome: json['usuarioNome'] ?? '',
      eventoId: json['eventoId'],
      eventoTitulo: json['eventoTitulo'] ?? '',
      status: json['status'] ?? '',
      tokenQr: json['tokenQr'] ?? '',
      dataInscricao:
          json['dataInscricao'] != null
              ? DateTime.parse(
                  json['dataInscricao'],
                )
              : null,
      dataCancelamento:
      json['dataCancelamento'] != null
        ? DateTime.parse(
            json['dataCancelamento'],
          )
        : null,        
    );
  }
}