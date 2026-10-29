import 'dart:math' as math;

/// Slow ambient clock; narrative milestones retain ownership of story time.
class WorldAtmosphere {
  double minutes = 7 * 60 + 12;
  double nightBlend = 0;
  bool get isNight => nightBlend >= .5;
  String get clock {
    final value = minutes.floor() % 1440;
    return '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  }

  void restore({required bool night}) {
    minutes = night ? 20 * 60 + 45 : 7 * 60 + 12;
    nightBlend = night ? 1 : 0;
  }

  void update(double dt, {required bool storyNight}) {
    if (storyNight && minutes < 18 * 60) minutes = 20 * 60 + 45;
    minutes = (minutes + dt * .5) % 1440;
    final target = storyNight || minutes >= 18 * 60 || minutes < 6 * 60
        ? 1.0
        : 0.0;
    nightBlend += (target - nightBlend) * (1 - math.exp(-dt * .7));
  }
}

enum InfectedHabitat { daytime, nocturnal, sewer }

/// Future spawns ask this rule before activation; no extra story enemies spawn.
bool habitatAllowsActivity(InfectedHabitat habitat, {required double light}) =>
    switch (habitat) {
      InfectedHabitat.daytime => light >= .25,
      InfectedHabitat.nocturnal => light < .45,
      InfectedHabitat.sewer => light < .15,
    };
