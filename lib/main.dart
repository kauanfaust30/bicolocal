import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/app.dart';
import 'core/firebase/firebase_initializer.dart';
import 'features/candidaturas/data/firestore_candidatura_repository.dart';
import 'features/conta/data/private_contact_repository.dart';
import 'features/conta/data/firebase_conta_repository.dart';
import 'features/pedidos/data/firestore_pedido_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseInitializer.initialize();
    runApp(
      BicoLocalApp(
        contaRepository: FirebaseContaRepository(
          FirebaseAuth.instance,
          FirebaseFirestore.instance,
        ),
        pedidoRepository: FirestorePedidoRepository(FirebaseFirestore.instance),
        candidaturaRepository: FirestoreCandidaturaRepository(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
          PrivateContactRepository(FirebaseFirestore.instance),
        ),
      ),
    );
  } catch (_) {
    runApp(const ConfiguracaoFirebasePage());
  }
}

class ConfiguracaoFirebasePage extends StatelessWidget {
  const ConfiguracaoFirebasePage({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BicoLocal',
    home: Scaffold(
      appBar: AppBar(title: const Text('BicoLocal')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Não foi possível conectar ao serviço. Configure o Firebase de desenvolvimento e tente novamente.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
