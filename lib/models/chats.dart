import 'package:cloud_firestore/cloud_firestore.dart';

class Chats {
  final String id;
  final List<String> participantes;
  final DateTime ultimaActualizacion;

  Chats({
    required this.id,
    required this.participantes,
    required this.ultimaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantes': participantes,
      'ultimaActualizacion': Timestamp.fromDate(ultimaActualizacion),
    };
  }

  factory Chats.fromMap(Map<String, dynamic> map) {
    return Chats(
      id: map['id'] as String,
      participantes: List<String>.from(map['participantes'] as List<dynamic>),
      ultimaActualizacion: (map['ultimaActualizacion'] as Timestamp).toDate(),
    );
  }
}