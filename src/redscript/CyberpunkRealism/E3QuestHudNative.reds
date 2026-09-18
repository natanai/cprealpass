// Biology-owned E3-inspired quest/objective presentation.
//
// W03.5 stops assuming QuestTrackerGameController.GetRootCompoundWidget() shares the
// authored coordinate space of the visible right-hand tracker. Current 2.31 script
// authority identifies m_questTrackerContainer as the semantic quest-stack container
// and m_ObjectiveContainer as its objective-list fallback. Biology mounts only inside
// those native content regions; no guessed global translation is used.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(QuestTrackerGameController)
private let crBiologyE3QuestFrame: ref<inkCanvas>;

@addField(QuestTrackerGameController)
private let crBiologyE3QuestHost: ref<inkCompoundWidget>;

@addField(QuestTrackerGameController)
private let crBiologyE3QuestHostName: String;

@addField(QuestTrackerGameController)
private let crBiologyE3NativeQuestTitleTint: HDRColor;

@addField(QuestTrackerGameController)
private let crBiologyE3HasNativeQuestTitleTint: Bool;

@addField(QuestTrackerGameController)
private let crBiologyE3QuestStateKnown: Bool;

@addField(QuestTrackerGameController)
private let crBiologyE3QuestLastEnabled: Bool;

@addMethod(QuestTrackerGameController)
private final func CRResolveBiologyE3QuestHost() -> ref<inkCompoundWidget> {
  let host: ref<inkCompoundWidget> = inkWidgetRef.Get(this.m_questTrackerContainer) as inkCompoundWidget;
  if IsDefined(host) {
    this.crBiologyE3QuestHostName = "m_questTrackerContainer";
    return host;
  }

  host = inkCompoundRef.Get(this.m_ObjectiveContainer);
  if IsDefined(host) {
    this.crBiologyE3QuestHostName = "m_ObjectiveContainer";
    return host;
  }

  this.crBiologyE3QuestHostName = "UNRESOLVED";
  return NULL;
}

@addMethod(QuestTrackerGameController)
private final func CRCaptureBiologyE3QuestTitleTint() -> Void {
  let title: ref<inkText> = inkTextRef.Get(this.m_QuestTitle) as inkText;
  if IsDefined(title) && !this.crBiologyE3HasNativeQuestTitleTint {
    this.crBiologyE3NativeQuestTitleTint = title.GetTintColor();
    this.crBiologyE3HasNativeQuestTitleTint = true;
  }
}

@addMethod(QuestTrackerGameController)
private final func CRCreateBiologyE3QuestFrame() -> Void {
  if IsDefined(this.crBiologyE3QuestFrame) {
    return;
  }

  this.crBiologyE3QuestHost = this.CRResolveBiologyE3QuestHost();
  if !IsDefined(this.crBiologyE3QuestHost) {
    CRBiologyE3Primitives.Trace("QuestTracker content-host unresolved; chrome not mounted");
    return;
  }

  this.crBiologyE3QuestFrame = CRBiologyE3Primitives.CreateFillShell(this.crBiologyE3QuestHost, n"CRBiologyE3QuestFrame");
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3QuestFrame, "OBJECTIVES", 188.0);
}

@addMethod(QuestTrackerGameController)
private final func CRRefreshBiologyE3QuestFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  let title: ref<inkText>;

  this.CRCreateBiologyE3QuestFrame();
  this.CRCaptureBiologyE3QuestTitleTint();

  if IsDefined(this.crBiologyE3QuestFrame) {
    this.crBiologyE3QuestFrame.SetVisible(enabled);
  }

  title = inkTextRef.Get(this.m_QuestTitle) as inkText;
  if IsDefined(title) {
    if enabled {
      title.SetTintColor(CRBiologyE3Primitives.Red());
    } else {
      if this.crBiologyE3HasNativeQuestTitleTint {
        title.SetTintColor(this.crBiologyE3NativeQuestTitleTint);
      }
    }
  }

  if !this.crBiologyE3QuestStateKnown || this.crBiologyE3QuestLastEnabled != enabled {
    CRBiologyE3Primitives.TraceMountedRegion(
      "QuestTracker",
      this.crBiologyE3QuestHostName,
      this.crBiologyE3QuestHost,
      this.crBiologyE3QuestFrame,
      enabled
    );
    this.crBiologyE3QuestStateKnown = true;
    this.crBiologyE3QuestLastEnabled = enabled;
  }
}

@wrapMethod(QuestTrackerGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("QuestTrackerGameController.OnInitialize");
  this.CRRefreshBiologyE3QuestFrame();
  return result;
}

@wrapMethod(QuestTrackerGameController)
private func UpdateTrackerData() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3QuestFrame();
}
