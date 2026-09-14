// Project-original Biology view-model projection.
// This layer deliberately exposes qualitative, player-knowable state while the
// underlying body model retains exact quantities for simulation and diagnostics.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*

public class CRBiologyViewModel extends IScriptable {
  public let valid: Bool = false;
  public let needs: String;
  public let conditions: String;
  public let hasNeeds: Bool = false;
  public let hasConditions: Bool = false;
}

public class CRBiologyPresentation extends IScriptable {
  private static func AddCondition(text: String, descriptor: ref<CRConditionDescriptor>) -> String {
    if !IsDefined(descriptor) || !descriptor.valid || !descriptor.hasCondition {
      return text;
    }
    if !Equals(text, "") {
      text += "\n";
    }
    return text + descriptor.regionName + " — " + descriptor.title + " / " + descriptor.severity;
  }

  public static func Current() -> ref<CRBiologyViewModel> {
    let result: ref<CRBiologyViewModel> = new CRBiologyViewModel();
    if !CRBodyStatusPresentation.Owns() {
      return result;
    }
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) || !body.initialized {
      return result;
    }

    result.needs = CRBodyStatusPresentation.BodyStatus(body);
    result.hasNeeds = !Equals(result.needs, "") && !Equals(result.needs, "No strong bodily need is demanding attention.");

    let conditions: String = "";
    let region: Int32 = 1;
    while region <= 6 {
      conditions = CRBiologyPresentation.AddCondition(conditions, CRConditionPresentation.Current(region));
      region += 1;
    }
    result.conditions = conditions;
    result.hasConditions = !Equals(conditions, "");
    result.valid = true;
    return result;
  }
}
