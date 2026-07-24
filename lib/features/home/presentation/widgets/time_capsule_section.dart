import 'package:flutter/material.dart';

import '../../../time_capsule/presentation/widgets/time_capsule_rail.dart';

/// Home Time Capsule section — delegates to the Time Capsule feature rail.
class TimeCapsuleSection extends StatelessWidget {
  const TimeCapsuleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const TimeCapsuleRail();
  }
}
