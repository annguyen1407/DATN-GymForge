/// Calorie formula v3 (see cong_thuc_tinh_calo_set_v3.md)
/// Implements energy expenditure per set based on adjusted MET.
/// All inputs are in SI-like units (kg, seconds) and reps count.
/// Returns kcal (double, precision ~0.1 recommended for display).
///
/// E_set = M_adj * 3.5 * (W / 200) * (R * T_rep / 60)
/// Where M_adj depends on loadUsed and oneRm availability.
/// See markdown for detailed explanation of parameters.
class CalorieFormula {
  // Configuration defaults (can be overridden by providing parameters to compute call)
  static const double defaultPrefPercent1Rm = 50; // P_ref
  static const double k = 0.5; // intensity sensitivity when 1RM known
  static const double kR = 0.5; // intensity sensitivity when 1RM unknown
  static const double lRef = 0.5; // L_ref (ratio reference load/bodyweight)
  static const double fMin = 0.6; // minimum adjustment factor
  static const double fMax = 1.5; // maximum adjustment factor
  static const double defaultRepTime = 5; // seconds

  /// Compute calories for a single set.
  /// Parameters:
  /// - metBase: base MET of exercise (M_base). If <=0 => return 0.
  /// - loadUsed: weight used for this set (kg); 0 for bodyweight-only sets.
  /// - oneRm: user 1RM (kg) (nullable). If null or <=0 treated as missing.
  /// - bodyWeight: user body weight in kg (nullable). If null uses fallback 70kg.
  /// - reps: number of reps performed in the set.
  /// - repTime: average seconds per rep (optional, defaults to 5s if <=0).
  static double caloriesForSet({
    required double metBase,
    required double loadUsed,
    required double? oneRm,
    required double? bodyWeight,
    required int reps,
    double repTime = defaultRepTime,
    double prefPercent1Rm = defaultPrefPercent1Rm,
  }) {
    if (metBase <= 0 || reps <= 0) return 0;
    final bw = (bodyWeight != null && bodyWeight > 0) ? bodyWeight : 70.0;
    final avgRepTime = repTime > 0 ? repTime : defaultRepTime;

    double mAdj;
    if (loadUsed <= 0) {
      // Bodyweight
      mAdj = metBase;
    } else if (oneRm != null && oneRm > 0) {
      final percent1Rm = (loadUsed / oneRm) * 100.0;
      double fInt = 1 + k * ((percent1Rm - prefPercent1Rm) / 100.0);
      if (fInt < fMin) fInt = fMin;
      if (fInt > fMax) fInt = fMax;
      mAdj = metBase * fInt;
    } else {
      final lRatio = loadUsed / bw; // load to body weight ratio
      double fDefault = 1 + kR * ((lRatio - lRef) / lRef);
      if (fDefault < fMin) fDefault = fMin;
      if (fDefault > fMax) fDefault = fMax;
      mAdj = metBase * fDefault;
    }

    // Convert: MET * 3.5 * W /200 gives kcal per minute. Multiply by workout minutes: (R * T_rep)/60
    final workMinutes = (reps * avgRepTime) / 60.0;
    final kcal = mAdj * 3.5 * (bw / 200.0) * workMinutes;
    if (kcal.isNaN || kcal.isInfinite) return 0;
    return kcal;
  }
}
