// Cyberpunk Realism original source. Provisional energy bookkeeping, not a
// calibrated ballistic or tissue model. No game damage, timers, or logging.
module CyberpunkRealism.Combat

public class CRProjectileSpec extends IScriptable {
  public let massGrams: Float;
  public let speedMetersPerSecond: Float;
  public let diameterMm: Float;
  public let penetrationFactor: Float = 1.0;
}

public class CRProtectionLayer extends IScriptable {
  public let covered: Bool = false;
  // Empirical model parameter, not an NIJ rating or real material constant.
  public let resistanceJPerMm2: Float = 0.0;
  public let integrity: Float = 1.0;
  public let durabilityJ: Float = 100000.0;
  public let bluntTransferFraction: Float = 0.0;
}

public class CRImpactState extends IScriptable {
  public let valid: Bool = false;
  public let initialJ: Float;
  public let remainingJ: Float;
  public let dissipatedJ: Float;
  public let bluntJ: Float;
  public let areaMm2: Float;
  public let penetrationFactor: Float;
  public let layersApplied: Int32;
}

public class CRImpactModel extends IScriptable {
  public static func InRange(value: Float, low: Float, high: Float) -> Bool {
    return value >= low && value <= high;
  }

  public static func Begin(projectile: ref<CRProjectileSpec>) -> ref<CRImpactState> {
    let result: ref<CRImpactState> = new CRImpactState();
    if !IsDefined(projectile) {
      return result;
    }
    if !CRImpactModel.InRange(projectile.massGrams, 0.001, 10000.0) || !CRImpactModel.InRange(projectile.speedMetersPerSecond, 0.0, 5000.0) || !CRImpactModel.InRange(projectile.diameterMm, 0.01, 500.0) || !CRImpactModel.InRange(projectile.penetrationFactor, 0.01, 100.0) {
      return result;
    }
    result.initialJ = 0.0005 * projectile.massGrams * projectile.speedMetersPerSecond * projectile.speedMetersPerSecond;
    result.remainingJ = result.initialJ;
    result.areaMm2 = 0.785398163 * projectile.diameterMm * projectile.diameterMm;
    result.penetrationFactor = projectile.penetrationFactor;
    result.valid = true;
    return result;
  }

  public static func ValidState(state: ref<CRImpactState>) -> Bool {
    if !IsDefined(state) {
      return false;
    }
    if !state.valid || !CRImpactModel.InRange(state.initialJ, 0.0, 125000000.0) || !CRImpactModel.InRange(state.remainingJ, 0.0, state.initialJ) || !CRImpactModel.InRange(state.dissipatedJ, 0.0, state.initialJ) || !CRImpactModel.InRange(state.bluntJ, 0.0, state.initialJ) || !CRImpactModel.InRange(state.areaMm2, 0.00007, 200000.0) || !CRImpactModel.InRange(state.penetrationFactor, 0.01, 100.0) || state.layersApplied < 0 || state.layersApplied > 32 {
      return false;
    }
    let sum: Float = state.remainingJ + state.dissipatedJ + state.bluntJ;
    let tolerance: Float = MaxF(0.001, state.initialJ * 0.00001);
    return sum >= state.initialJ - tolerance && sum <= state.initialJ + tolerance;
  }

  public static func ValidLayer(layer: ref<CRProtectionLayer>) -> Bool {
    if !IsDefined(layer) {
      return false;
    }
    return CRImpactModel.InRange(layer.resistanceJPerMm2, 0.0, 100000.0) && CRImpactModel.InRange(layer.integrity, 0.0, 1.0) && CRImpactModel.InRange(layer.durabilityJ, 0.001, 1000000000.0) && CRImpactModel.InRange(layer.bluntTransferFraction, 0.0, 1.0);
  }

  // A layer affects this impact only where covered. It consumes projectile
  // energy once and partitions that energy between dissipation and blunt load.
  // Call on copied layers for previews; real condition changes only on commit.
  public static func ApplyLayer(state: ref<CRImpactState>, layer: ref<CRProtectionLayer>) -> Bool {
    let stoppingJ: Float;
    let absorbedJ: Float;
    let bluntJ: Float;
    if !CRImpactModel.ValidState(state) || !CRImpactModel.ValidLayer(layer) {
      return false;
    }
    if state.layersApplied >= 32 {
      return false;
    }
    state.layersApplied += 1;
    if !layer.covered || state.remainingJ == 0.0 {
      return true;
    }
    stoppingJ = layer.resistanceJPerMm2 * state.areaMm2 * layer.integrity / state.penetrationFactor;
    absorbedJ = MinF(state.remainingJ, stoppingJ);
    bluntJ = absorbedJ * layer.bluntTransferFraction;
    state.remainingJ -= absorbedJ;
    state.bluntJ += bluntJ;
    state.dissipatedJ += absorbedJ - bluntJ;
    layer.integrity = MaxF(0.0, layer.integrity - absorbedJ / layer.durabilityJ);
    return true;
  }

  public static func CopyLayer(layer: ref<CRProtectionLayer>) -> ref<CRProtectionLayer> {
    if !CRImpactModel.ValidLayer(layer) {
      return null;
    }
    let copy: ref<CRProtectionLayer> = new CRProtectionLayer();
    copy.covered = layer.covered;
    copy.resistanceJPerMm2 = layer.resistanceJPerMm2;
    copy.integrity = layer.integrity;
    copy.durabilityJ = layer.durabilityJ;
    copy.bluntTransferFraction = layer.bluntTransferFraction;
    return copy;
  }
}
