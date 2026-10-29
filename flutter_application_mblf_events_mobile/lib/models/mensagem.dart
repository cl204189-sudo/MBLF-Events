class Mensagem {
  final int id;

  final int eventoId;

  final int usuarioId;
  final String usuarioNome;

  final String mensagem;

  final DateTime? dataEnvio;

  Mensagem({
    required this.id,
    required this.eventoId,
    required this.usuarioId,
    required this.usuarioNome,
    required this.mensagem,
    required this.dataEnvio,
  });

  factory Mensagem.fromJson(
    Map<String, dynamic> json,
  ) {
    return Mensagem(
      id: json['id'],
      eventoId: json['eventoId'],
      usuarioId: json['usuarioId'],
      usuarioNome: json['usuarioNome'] ?? '',
      mensagem: json['mensagem'] ?? '',
      dataEnvio: json['dataEnvio'] != null
          ? DateTime.parse(json['dataEnvio'])
          : null,
    );
  }
}