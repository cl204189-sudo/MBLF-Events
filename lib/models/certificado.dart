class Certificado {
  final int id;
  final int inscricaoId;

  final int usuarioId;
  final String nomeParticipante;

  final int eventoId;
  final String tituloEvento;

  final String codigo;
  final int? cargaHoraria;

  final String status;

  final DateTime? dataGeracao;
  final DateTime? dataLiberacao;

  final int? liberadoPorId;
  final String? liberadoPorNome;

  Certificado({
    required this.id,
    required this.inscricaoId,
    required this.usuarioId,
    required this.nomeParticipante,
    required this.eventoId,
    required this.tituloEvento,
    required this.codigo,
    required this.cargaHoraria,
    required this.status,
    required this.dataGeracao,
    required this.dataLiberacao,
    required this.liberadoPorId,
    required this.liberadoPorNome,
  });

  factory Certificado.fromJson(
    Map<String, dynamic> json,
  ) {
    return Certificado(
      id: json['id'],
      inscricaoId: json['inscricaoId'],
      usuarioId: json['usuarioId'],
      nomeParticipante:
          json['nomeParticipante'] ?? '',
      eventoId: json['eventoId'],
      tituloEvento:
          json['tituloEvento'] ?? '',
      codigo: json['codigo'] ?? '',
      cargaHoraria: json['cargaHoraria'],
      status: json['status'] ?? '',
      dataGeracao:
          json['dataGeracao'] != null
              ? DateTime.parse(
                  json['dataGeracao'],
                )
              : null,
      dataLiberacao:
          json['dataLiberacao'] != null
              ? DateTime.parse(
                  json['dataLiberacao'],
                )
              : null,
      liberadoPorId:
          json['liberadoPorId'],
      liberadoPorNome:
          json['liberadoPorNome'],
    );
  }
}