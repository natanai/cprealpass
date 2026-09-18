// Biology-owned E3-inspired quest/objective presentation.
//
// W03.6 keeps W03.5's proven m_questTrackerContainer mount, but stops treating a tiny
// fixed label/rail as the finished tracker design. Biology frames the semantic tracker
// host itself and recolors the actual native title/objective text + tracking indicators.
// m_ObjectiveContainer remains an objective-controller-only native child list: Biology
// never reparents custom chrome into it and never owns Journal data/spawning/animation.
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

@addField(QuestTrackerObjectiveLogicController)
private let crBiologyE3NativeObjectiveTitleTint: HDRColor;

@addField(QuestTrackerObjectiveLogicController)
private let crBiologyE3NativeTrackingIconTint: HDRColor;

@addField(QuestTrackerObjectiveLogicController)
private let crBiologyE3NativeTrackingFrameTint: HDRColor;

@addField(QuestTrackerObjectiveLogicController)
private let crBiologyE3HasObjectiveStyle: Bool;

@addMethod(QuestTrackerGameController)
private final func CRResolveBiologyE3QuestHost() -> ref<inkCompoundWidget> {
  let host: ref<inkCompoundWidget> = inkWidgetRef.Get(this.m_questTrackerContainer) as inkCompoundWidget;
  if IsDefined(host) {
    this.crBiologyE3QuestHostName = "m_questTrackerContainer";
    return host;
  }

  this.crBiologyE3QuestHostName = "UNRESOLVED";
  return host;
}

@addMethod(QuestTrackerObjectiveLogicController)
public final func CRRefreshBiologyE3ObjectiveStyle(enabled: Bool) -> Void {
  let title: ref<inkText> = inkTextRef.Get(this.m_objectiveTitle) as inkText;
  let trackingIcon: ref<inkWidget> = inkWidgetRef.Get(this.m_trackingIcon);
  let trackingFrame: ref<inkWidget> = inkWidgetRef.Get(this.m_trackingFrame);

  if !this.crBiologyE3HasObjectiveStyle
    && IsDefined(title)
    && IsDefined(trackingIcon)
    && IsDefined(trackingFrame) {
    this.crBiologyE3NativeObjectiveTitleTint = title.GetTintColor();
    this.crBiologyE3NativeTrackingIconTint = trackingIcon.GetTintColor();
    this.crBiologyE3NativeTrackingFrameTint = trackingFrame.GetTintColor();
    this.crBiologyE3HasObjectiveStyle = true;
  }

  if !this.crBiologyE3HasObjectiveStyle {
    return;
  }

  if enabled {
    title.SetTintColor(CRBiologyE3Primitives.Red());
    trackingIcon.SetTintColor(CRBiologyE3Primitives.Red());
    trackingFrame.SetTintColor(CRBiologyE3Primitives.Red());
  } else {
    title.SetTintColor(this.crBiologyE3NativeObjectiveTitleTint);
    trackingIcon.SetTintColor(this.crBiologyE3NativeTrackingIconTint);
    trackingFrame.SetTintColor(this.crBiologyE3NativeTrackingFrameTint);
  }
}

@addMethod(QuestTrackerGameController)
private final func CRRefreshBiologyE3ObjectiveStyles(enabled: Bool) -> Void {
  let i: Int32 = 0;
  let objectiveController: wref<QuestTrackerObjectiveLogicController>;

  while i < inkCompoundRef.GetNumChildren(this.m_ObjectiveContainer) {
    objectiveController = (inkCompoundRef.GetWidgetByIndex(this.m_ObjectiveContainer, i).GetController() as QuestTrackerObjectiveLogicController);
    if IsDefined(objectiveController) {
      objectiveController.CRRefreshBiologyE3ObjectiveStyle(enabled);
    }
    i += 1;
  }
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
  CRBiologyE3Primitives.AddSegmentedRegionChrome(this.crBiologyE3QuestFrame);
}

@addMethod(QuestTrackerGameController)
private final func CRRefreshBiologyE3QuestFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  let title: ref<inkText>;

  this.CRCreateBiologyE3QuestFrame();
  this.CRCaptureBiologyE3QuestTitleTint();
  this.CRRefreshBiologyE3ObjectiveStyles(enabled);

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

  if !this.crBiologyE3QuestStateKnown
    || (this.crBiologyE3QuestLastEnabled && !enabled)
    || (!this.crBiologyE3QuestLastEnabled && enabled) {
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
