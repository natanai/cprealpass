// Native shell synchronization for Biology/Cyberware mode and drill-down.
//
// This file intentionally hooks Cyberpunk's existing Ripperdoc selector/back/content
// state machine. Biology-specific data lives elsewhere; navigation remains native.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

// -----------------------------------------------------------------------------
// Biology overview nodes reuse stock Cyberware category label widgets.
// -----------------------------------------------------------------------------

@addField(CyberwareInventoryMiniGrid)
private let crBiologyStockLabelCallbacksSuspended: Bool;

@addMethod(CyberwareInventoryMiniGrid)
public final func CRSetBiologyLabelInteractive(active: Bool) -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    active = false;
  }
  inkTextRef.SetInteractive(this.m_label, active);

  // The stock label callback opens cyberware-category tooltips. While the same label
  // is a Biology body node, suspend only those two callbacks; restore them exactly
  // once when Cyberware mode returns.
  if active && !this.crBiologyStockLabelCallbacksSuspended {
    inkTextRef.UnregisterFromCallback(this.m_label, n"OnHoverOver", this, n"OnHoverOverCategoryLabel");
    inkTextRef.UnregisterFromCallback(this.m_label, n"OnHoverOut", this, n"OnHoverOutCategoryLabel");
    this.crBiologyStockLabelCallbacksSuspended = true;
  } else {
    if !active && this.crBiologyStockLabelCallbacksSuspended {
      inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOver", this, n"OnHoverOverCategoryLabel");
      inkTextRef.RegisterToCallback(this.m_label, n"OnHoverOut", this, n"OnHoverOutCategoryLabel");
      this.crBiologyStockLabelCallbacksSuspended = false;
    }
  }
}

// -----------------------------------------------------------------------------
// Reuse the native Ripperdoc category selector, including its arrows and global
// option_switch_prev/next input. Biology changes only the displayed category names
// and skips the two Cyberware-only categories it does not model.
// -----------------------------------------------------------------------------

@addField(RipperdocSelectorController)
private let crBiologyDetailMode: Bool;

@addField(RipperdocSelectorController)
private let crBiologyStockNames: array<String>;

@addField(RipperdocSelectorController)
private let crBiologyStockNamesCaptured: Bool;

@addMethod(RipperdocSelectorController)
private final func CRBiologySelectorIndexSupported(index: Int32) -> Bool {
  return index == 0
    || index == 1
    || index == 2
    || index == 4
    || index == 6
    || index == 7
    || index == 8
    || index == 9;
}

@addMethod(RipperdocSelectorController)
private final func CRCaptureBiologySelectorStockNames() -> Void {
  if this.crBiologyStockNamesCaptured {
    return;
  }
  ArrayClear(this.crBiologyStockNames);
  let i: Int32 = 0;
  while i < ArraySize(this.m_names) {
    ArrayPush(this.crBiologyStockNames, this.m_names[i]);
    i += 1;
  }
  this.crBiologyStockNamesCaptured = true;
}

@addMethod(RipperdocSelectorController)
public final func CRSetBiologyDetailMode(active: Bool) -> Void {
  this.CRCaptureBiologySelectorStockNames();
  this.crBiologyDetailMode = active;

  if !active {
    if this.crBiologyStockNamesCaptured {
      ArrayClear(this.m_names);
      let i: Int32 = 0;
      while i < ArraySize(this.crBiologyStockNames) {
        ArrayPush(this.m_names, this.crBiologyStockNames[i]);
        i += 1;
      }
    }
    return;
  }

  // Ripperdoc's selector order is the same fixed ten-area order used by
  // RipperDocGameController. Eyes (3) and Hands (5) remain Cyberware-only and are
  // skipped rather than relabeled as invented physiology.
  if ArraySize(this.m_names) >= 10 {
    this.m_names[0] = "HEAD / BRAIN";
    this.m_names[1] = "METABOLISM";
    this.m_names[2] = "ARMS";
    this.m_names[4] = "MUSCULOSKELETAL";
    this.m_names[6] = "NERVOUS";
    this.m_names[7] = "CIRCULATION";
    this.m_names[8] = "SKIN / WOUNDS";
    this.m_names[9] = "LEGS";
  }
}

@addMethod(RipperdocSelectorController)
public final func CRSetBiologyLayoutDiagnostic(status: String) -> Void {
  if !this.crBiologyDetailMode {
    return;
  }

  let index: Int32 = this.m_indicatorIndex;
  if index < 0 || index >= ArraySize(this.m_names) {
    return;
  }

  if Equals(status, "") {
    inkTextRef.SetText(this.m_label, this.m_names[index]);
    return;
  }

  // Bounded attended evidence: T003 proved this native selector remains visible even
  // when Biology detail disappears. Show the exact native-region result, INCLUDING
  // MOUNTED, so a still-blank integrated capture can distinguish "mount failed" from
  // "mount succeeded; investigate clipping/size/opacity/async layout next." No new
  // overlay or absolute-positioned diagnostic is created.
  inkTextRef.SetText(this.m_label, this.m_names[index] + "  [BIOLOGY LAYOUT: " + status + "]");
}

@addMethod(RipperdocSelectorController)
private final func CRNextBiologySelectorIndex(current: Int32, toNext: Bool) -> Int32 {
  let count: Int32 = ArraySize(this.m_indicatorAnchors);
  if count <= 0 {
    return current;
  }

  let candidate: Int32 = current;
  let attempts: Int32 = 0;
  while attempts < count {
    candidate += toNext ? 1 : -1;
    if candidate >= count {
      candidate = 0;
    } else {
      if candidate < 0 {
        candidate = count - 1;
      }
    }
    if this.CRBiologySelectorIndexSupported(candidate) {
      return candidate;
    }
    attempts += 1;
  }
  return current;
}

@wrapMethod(RipperdocSelectorController)
private func SwitchIndicator(toNext: Bool) -> Void {
  if !this.crBiologyDetailMode {
    wrappedMethod(toNext);
    return;
  }

  let next: Int32 = this.CRNextBiologySelectorIndex(this.m_indicatorIndex, toNext);
  if next == this.m_indicatorIndex {
    return;
  }

  this.SetIndicator(this.m_indicatorIndex, false);
  this.SetIndicator(next, true);
  let selectorEvent: ref<RipperdocSelectorChangeEvent> = new RipperdocSelectorChangeEvent();
  selectorEvent.Index = next;
  selectorEvent.SlidingRight = toNext;
  this.QueueEvent(selectorEvent);
}

// -----------------------------------------------------------------------------
// RipperDocGameController native transition synchronization.
// -----------------------------------------------------------------------------

@addMethod(RipperDocGameController)
private final func CRSyncBiologyNodeInteractivity(active: Bool) -> Void {
  let i: Int32 = 0;
  while i < ArraySize(this.m_equipmentMinigrids) {
    if IsDefined(this.m_equipmentMinigrids[i]) {
      this.m_equipmentMinigrids[i].CRSetBiologyLabelInteractive(
        active && !this.CRBodyShellInDetail() && CRBiologyDetailPresentation.Supported(this.m_equipmentMinigrids[i].CRBiologyArea())
      );
    }
    i += 1;
  }
}

@addMethod(RipperDocGameController)
private final func CRSyncSpawnedBiologyNode(widget: ref<inkWidget>) -> Void {
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) || !IsDefined(widget) {
    return;
  }
  let minigrid: ref<CyberwareInventoryMiniGrid> = widget.GetController() as CyberwareInventoryMiniGrid;
  if !IsDefined(minigrid) {
    return;
  }

  // Stock SpawnMinigrids is asynchronous. Apply the already-selected shell mode at
  // the actual native creation boundary so overview nodes remain deterministic. W02.2
  // additionally keeps labels non-actionable until the complete ten-grid shell and
  // required native controllers are ready, independent of wrapper composition order.
  minigrid.CRSetBiologyMode(this.crBiologyShellMode);
  minigrid.CRSetBiologyLabelInteractive(
    this.crBiologyShellMode
      && this.CRBiologyNativeDetailReady()
      && !this.CRBodyShellInDetail()
      && CRBiologyDetailPresentation.Supported(minigrid.CRBiologyArea())
  );
}

@wrapMethod(RipperDocGameController)
protected cb func OnMinigridSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool {
  let result: Bool = wrappedMethod(widget, userData);
  this.CRSyncSpawnedBiologyNode(widget);
  return result;
}

// Native Cyberware enters/leaves detail through DisplayInventory. Keep Biology's
// internal mode selector synchronized with that same depth so Cyberware drill-down
// cannot switch directly to Biology either.
@wrapMethod(RipperDocGameController)
private func DisplayInventory(visible: Bool) -> Void {
  wrappedMethod(visible);
  this.CRSyncBiologyModeSwitcher();
}

// The native Ripperdoc selector owns arrows, A/D-style option-switch input, wrapping
// and category-change events. Biology consumes those same events while its detail is
// active; Cyberware receives the untouched stock implementation otherwise.
@wrapMethod(RipperDocGameController)
protected cb func OnSelectorChange(evt: ref<RipperdocSelectorChangeEvent>) -> Bool {
  if this.CRHandleBiologySelectorChange(evt) {
    return true;
  }
  return wrappedMethod(evt);
}

// The stock menu dispatcher already routes Back/Cancel here. Biology intercepts only
// its own Item-depth state and returns to its overview using the same native shell
// primitives. Every other Cyberware/menu Back path stays stock.
@wrapMethod(RipperDocGameController)
protected cb func OnBack(userData: ref<IScriptable>) -> Bool {
  if this.CRHandleBiologyBack() {
    return true;
  }
  let result: Bool = wrappedMethod(userData);
  this.CRSyncBiologyModeSwitcher();
  return result;
}

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  if !CRRealpassSettings.IsEnabled(GetGameInstance()) {
    return result;
  }

  // The old action panel was rooted independently on the fullscreen. Move the same
  // authoritative item/treatment controls into Cyberware's native content anchor and
  // let selected Biology areas decide when they are relevant. W02.2 keeps first-open
  // labels gated until the asynchronous native shell has fully initialized.
  this.CRMountBiologyActionsInNativeContent();
  this.CRSyncBiologyNodeInteractivity(this.crBiologyShellMode && this.CRBiologyNativeDetailReady());
  this.CRRefreshBiologyActions();
  this.CRConstrainBiologyActionsToSelectedArea();
  this.CRSyncBiologyModeSwitcher();
  return result;
}
