import 'package:flutter/material.dart';

/// Logotipo do BicoLocal: ferramenta num círculo, nome e lema.
class BicoLocalLogo extends StatelessWidget {
  const BicoLocalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'BicoLocal. Serviços rápidos perto de você',
      child: ExcludeSemantics(
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: cores.primary,
              child: Icon(Icons.handyman, size: 36, color: cores.onPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'BicoLocal',
              style: texto.headlineSmall?.copyWith(color: cores.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Serviços rápidos perto de você',
              textAlign: TextAlign.center,
              style: texto.bodyMedium?.copyWith(color: cores.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
