class Plano {
  final int id;
  final String nome;
  final String tipo;
  final int duracaoDias;
  final double valor;
  final bool ativo;

  Plano({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.duracaoDias,
    required this.valor,
    required this.ativo,
  });

  factory Plano.fromJson(
    Map<String, dynamic> json,
  ) {
    return Plano(
      id: json['id'],
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      duracaoDias: json['duracaoDias'] ?? 0,
      valor: (json['valor'] ?? 0).toDouble(),
      ativo: json['ativo'] ?? false,
    );
  }
}