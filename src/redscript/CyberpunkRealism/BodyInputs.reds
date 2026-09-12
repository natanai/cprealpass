// Cyberpunk Realism original source. Ordered, persistable simulation inputs.
module CyberpunkRealism.Physiology

public class CRBodyInput extends IScriptable {
  // 1 wound; 2 dressing; 3 support; 4 clinical care; 5 cyberware repair.
  public persistent let medicalKind: Int32 = 0;
  public persistent let injuryRegion: Int32 = 0;
  public persistent let tissueDamage: Float = 0.0;
  public persistent let boneDamage: Float = 0.0;
  public persistent let cyberwareDamage: Float = 0.0;
  public persistent let externalBleed: Float = 0.0;
  public persistent let internalBleed: Float = 0.0;
  public persistent let next: ref<CRBodyInput>;
  public persistent let isIntake: Bool = false;
  public persistent let interactionKind: Int32 = 0;
  public persistent let effectiveness: Float = 0.0;
  public persistent let submitted: Bool = false;
  public persistent let hours: Float = 0.0;
  public persistent let exertion: Float = 0.0;
  public persistent let sleeping: Bool = false;
  public persistent let waterMl: Float = 0.0;
  public persistent let energyKcal: Float = 0.0;
  public persistent let residueGrams: Float = 0.0;
}

public class CRBodyInputQueue extends IScriptable {
  public persistent let first: ref<CRBodyInput>;
  public persistent let count: Int32 = 0;
  public persistent let acceptedIntakes: Int32 = 0;
  public persistent let appliedIntakes: Int32 = 0;
  public persistent let appliedInteractions: Int32 = 0;
  public persistent let appliedWounds: Int32 = 0;
  public persistent let appliedTreatments: Int32 = 0;
  public persistent let faulted: Bool = false;
}

public class CRBodyInputs extends IScriptable {
  private static func Append(queue: ref<CRBodyInputQueue>, input: ref<CRBodyInput>) -> Void {
    // Keep only one owning chain in saves; do not depend on restored alias
    // identity between a separately serialized tail and the head's descendants.
    if IsDefined(queue.first) {
      let tail: ref<CRBodyInput> = queue.first;
      while IsDefined(tail.next) {
        tail = tail.next;
      }
      tail.next = input;
    } else {
      queue.first = input;
    }
    queue.count += 1;
  }

  public static func Time(queue: ref<CRBodyInputQueue>, hours: Float, exertion: Float, sleeping: Bool) -> Bool {
    if queue.faulted || !(hours > 0.0) || !(hours <= 1000000.0) || !(exertion >= 0.0) || !(exertion <= 1.0) {
      return false;
    }
    let input: ref<CRBodyInput> = new CRBodyInput();
    input.hours = hours;
    input.exertion = exertion;
    input.sleeping = sleeping;
    CRBodyInputs.Append(queue, input);
    return true;
  }

  public static func Intake(queue: ref<CRBodyInputQueue>, waterMl: Float, energyKcal: Float, residueGrams: Float) -> Bool {
    if queue.faulted || !(waterMl >= 0.0) || !(waterMl <= 10000.0) || !(energyKcal >= 0.0) || !(energyKcal <= 20000.0) || !(residueGrams >= 0.0) || !(residueGrams <= 5000.0) {
      return false;
    }
    let input: ref<CRBodyInput> = new CRBodyInput();
    input.isIntake = true;
    input.waterMl = waterMl;
    input.energyKcal = energyKcal;
    input.residueGrams = residueGrams;
    CRBodyInputs.Append(queue, input);
    queue.acceptedIntakes += 1;
    return true;
  }

  // 1 = wash, 2 = bladder, 3 = bowel, 4 = full toilet use. Explicit operations,
  // not incidental sound effects, proximity, automatic accidents or idle timers.
  public static func Interact(queue: ref<CRBodyInputQueue>, kind: Int32, effectiveness: Float) -> Bool {
    if queue.faulted || kind < 1 || kind > 4 || !(effectiveness >= 0.0) || !(effectiveness <= 1.0) {
      return false;
    }
    let input: ref<CRBodyInput> = new CRBodyInput();
    input.interactionKind = kind;
    input.effectiveness = effectiveness;
    CRBodyInputs.Append(queue, input);
    return true;
  }
  public static func Injury(queue: ref<CRBodyInputQueue>, region: Int32, tissue: Float, bone: Float, cyberware: Float, externalBleed: Float, internalBleed: Float) -> Bool {
    let input: ref<CRBodyInput>;
    if queue.faulted || region < 1 || region > 6 || !CRInjuryModel.ValidWound(tissue, bone, cyberware, externalBleed, internalBleed) {
      return false;
    }
    input = new CRBodyInput();
    input.medicalKind = 1;
    input.injuryRegion = region;
    input.tissueDamage = tissue;
    input.boneDamage = bone;
    input.cyberwareDamage = cyberware;
    input.externalBleed = externalBleed;
    input.internalBleed = internalBleed;
    CRBodyInputs.Append(queue, input);
    return true;
  }

  public static func Treatment(queue: ref<CRBodyInputQueue>, region: Int32, kind: Int32, effectiveness: Float) -> Bool {
    let input: ref<CRBodyInput>;
    if queue.faulted || region < 1 || region > 6 || kind < 2 || kind > 5 || !(effectiveness >= 0.0) || !(effectiveness <= 1.0) {
      return false;
    }
    input = new CRBodyInput();
    input.medicalKind = kind;
    input.injuryRegion = region;
    input.effectiveness = effectiveness;
    CRBodyInputs.Append(queue, input);
    return true;
  }

  private static func ValidMedical(input: ref<CRBodyInput>) -> Bool {
    if input.medicalKind < 0 || input.medicalKind > 5 {
      return false;
    }
    if input.medicalKind == 0 {
      return input.injuryRegion == 0 && input.tissueDamage == 0.0 && input.boneDamage == 0.0 && input.cyberwareDamage == 0.0 && input.externalBleed == 0.0 && input.internalBleed == 0.0;
    }
    if input.isIntake || input.interactionKind != 0 || input.hours != 0.0 || input.submitted || input.injuryRegion < 1 || input.injuryRegion > 6 {
      return false;
    }
    if input.medicalKind == 1 {
      return CRInjuryModel.ValidWound(input.tissueDamage, input.boneDamage, input.cyberwareDamage, input.externalBleed, input.internalBleed);
    }
    return input.effectiveness >= 0.0 && input.effectiveness <= 1.0 && input.tissueDamage == 0.0 && input.boneDamage == 0.0 && input.cyberwareDamage == 0.0 && input.externalBleed == 0.0 && input.internalBleed == 0.0;
  }
  // One 72-hour Advance at most per call, plus up to 32 input boundaries. The
  // submitted marker prevents replay when that advance leaves a long backlog.
  // Existing game ticks call this again; no independent timer is required.
  public static func Drain(queue: ref<CRBodyInputQueue>, state: ref<CRBodyState>, config: ref<CRBodyConfig>) -> Int32 {
    if queue.faulted || !state.initialized {
      return 0;
    }
    let advanced: Bool = false;
    let completed: Int32 = 0;
    while IsDefined(queue.first) && completed < 32 {
      let input: ref<CRBodyInput> = queue.first;
      if !CRBodyInputs.ValidMedical(input) || input.interactionKind < 0 || input.interactionKind > 4 || (input.interactionKind > 0 && (input.isIntake || !(input.effectiveness >= 0.0) || !(input.effectiveness <= 1.0))) {
        queue.faulted = true;
        return completed;
      }
      if state.pendingHours + 0.000001 >= 1.0 / 60.0 {
        if advanced {
          return completed;
        }
        CRBodyModel.Advance(state, config, 0.0, 0.0, false);
        advanced = true;
        if !state.lastAdvanceAccepted {
          queue.faulted = true;
          return completed;
        }
        if state.pendingHours + 0.000001 >= 1.0 / 60.0 {
          return completed;
        }
      }
      if input.medicalKind > 0 {
        if !CRBodyModel.CloseInterval(state, config) {
          queue.faulted = true;
          return completed;
        }
        if !IsDefined(state.injuries) {
          state.injuries = CRInjuryModel.Create();
        }
        if input.medicalKind == 1 {
          if !CRInjuryModel.Wound(state.injuries, input.injuryRegion, input.tissueDamage, input.boneDamage, input.cyberwareDamage, input.externalBleed, input.internalBleed) {
            queue.faulted = true;
            return completed;
          }
          queue.appliedWounds += 1;
        } else {
          if !CRInjuryModel.Treat(state.injuries, input.injuryRegion, input.medicalKind, input.effectiveness) {
            queue.faulted = true;
            return completed;
          }
          queue.appliedTreatments += 1;
        }
      } else {
        if input.interactionKind > 0 {
          if !CRBodyModel.CloseInterval(state, config) {
            queue.faulted = true;
            return completed;
          }
          if input.interactionKind == 1 {
            CRBodyModel.Wash(state, input.effectiveness);
          }
          if input.interactionKind == 2 || input.interactionKind == 4 {
            CRBodyModel.EmptyBladder(state);
          }
          if input.interactionKind == 3 || input.interactionKind == 4 {
            CRBodyModel.EmptyBowel(state);
          }
          queue.appliedInteractions += 1;
        } else {
          if input.isIntake {
            if !CRBodyModel.CloseInterval(state, config) || !CRBodyModel.Ingest(state, input.waterMl, input.energyKcal, input.residueGrams) {
              queue.faulted = true;
              return completed;
            }
            queue.appliedIntakes += 1;
          } else {
            if !input.submitted {
              if advanced {
                return completed;
              }
              CRBodyModel.Advance(state, config, input.hours, input.exertion, input.sleeping);
              advanced = true;
              if !state.lastAdvanceAccepted {
                queue.faulted = true;
                return completed;
              }
              input.submitted = true;
              if state.pendingHours + 0.000001 >= 1.0 / 60.0 {
                return completed;
              }
            }
          }
        }
      }
      queue.first = input.next;
      input.next = null;
      queue.count -= 1;
      completed += 1;
    }
    return completed;
  }
}
