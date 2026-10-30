/// Playback policy only; these sounds never replace Caio's visual cues.
class AudioMix {
  final Map<String, double> _last = {};

  static double volume(String cue) => switch (cue) {
    'step' => .16,
    'cat' || 'dog' || 'bird' => .26,
    'door' || 'window' => .30,
    'hit' => .40,
    'push' || 'swing' => .25,
    'phone' || 'pickup' || 'heal' => .22,
    'engine' => .24,
    'pulse' => .28,
    _ => .30,
  };

  static double ambientVolume({required bool indoors}) => indoors ? .055 : .15;

  bool allow(String cue, double time) {
    final interval = switch (cue) {
      'cat' || 'dog' => 2.2,
      'bird' => 3.5,
      'step' => .09,
      _ => .15,
    };
    final previous = _last[cue];
    if (previous != null && time >= previous && time - previous < interval) {
      return false;
    }
    _last[cue] = time;
    return true;
  }
}
