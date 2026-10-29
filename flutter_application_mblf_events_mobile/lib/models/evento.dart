class Evento {
  final int id;
  final String status;
  final String? imagemUrl;
  final String titulo;
  final String descricao;
  final String tipo;
  final String cidade;
  final String endereco;
  final DateTime dataInicio;
  final DateTime dataFim;
  final DateTime? hubAte;
  final DateTime? publicacaoAte;
  final bool inscricoesAbertas;
  final int? vagasTotal;
  final int? vagasDisponiveis;
  final int? cargaHoraria;

  Evento({
    required this.id,
    this.status = 'PUBLICADO',
    this.imagemUrl,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.cidade,
    required this.endereco,
    required this.dataInicio,
    required this.dataFim,
    required this.hubAte,
    required this.publicacaoAte,
    required this.inscricoesAbertas,
    this.vagasTotal,
    this.vagasDisponiveis,
    this.cargaHoraria,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'],
      status: (json['status'] ?? 'PUBLICADO').toString(),
      imagemUrl: json['imagemUrl']?.toString(),
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: json['tipo'] ?? '',
      cidade: json['cidade'] ?? '',
      endereco: json['endereco'] ?? '',
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      hubAte: json['hubAte'] != null
          ? DateTime.parse(json['hubAte'])
          : null,

      publicacaoAte:
          json['publicacaoAte'] != null
              ? DateTime.parse(
                  json['publicacaoAte'],
                )
              : null,

      inscricoesAbertas:
          json['inscricoesAbertas'] ?? false,
      vagasTotal: json['vagasTotal'],
      vagasDisponiveis: json['vagasDisponiveis'],
      cargaHoraria: json['cargaHoraria'],
    );
  }
}