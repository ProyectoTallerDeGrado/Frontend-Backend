import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../widgets/pulsing_logo.dart';

/// Se muestra mientras se restaura la sesión guardada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy950,
      body: Center(child: PulsingLogo()),
    );
  }
}
