// Project-original backpack access and regional treatment popup.
// Codeware supplies generic popup plumbing only; all behavior/state/presentation
// decisions here are owned by realpass.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*
import Codeware.UI.*

public class CRFieldCareUI extends IScriptable {
  private let alive: Bool = true;
  private let region: Int32 = 2;
  private let focus: Int32 = 1;
  private let popup: wref<CRFieldCarePopup>;
  private let openButton: wref<inkText>;
  private let message: wref<inkText>;
  private let injurySummary: wref<inkText>;
  private let regionButtons: array<wref<inkText>>;
  private let controls: array<wref<inkText>>;

  public static func Create(parent: ref<inkCompoundWidget>) -> ref<CRFieldCareUI> {
    if !CRBodyStatusPresentation.Owns() || !CRCombatRuntimePolicy.Enabled() || !IsDefined(parent) {
      return null;
    }
    let ui: ref<CRFieldCareUI> = new CRFieldCareUI();
    CRFieldCareMenuSession.Get().Register(ui);
    let button: ref<inkText> = ui.MakeText(parent, n"CRCareOpen", "realpass  |  FIELD CARE", 620.0, 54.0, true);
    button.SetAnchor(inkEAnchor.BottomCenter);
    button.SetAnchorPoint(Vector2(0.5, 1.0));
    button.SetHAlign(inkEHorizontalAlign.Center);
    button.SetVAlign(inkEVerticalAlign.Bottom);
    button.SetMargin(inkMargin(0.0, 0.0, 0.0, 110.0));
    ui.openButton = button;
    return ui;
  }

  public func IsAlive() -> Bool { return this.alive; }

  public func Teardown() -> Void {
    this.alive = false;
    CRFieldCareMenuSession.Get().Clear(this);
    if IsDefined(this.openButton) { this.openButton.SetVisible(false); }
    if IsDefined(this.popup) && this.popup.IsInitialized() { this.popup.Close(); }
  }

  public func PopupClosed(popup: wref<CRFieldCarePopup>) -> Void {
    if Equals(this.popup, popup) {
      this.popup = null;
      ArrayClear(this.controls);
      ArrayClear(this.regionButtons);
      this.message = null;
      this.injurySummary = null;
    }
  }

  public func Open() -> Bool {
    if !this.alive || !CRBodyStatusPresentation.Owns() || !CRCombatRuntimePolicy.Enabled() {
      return false;
    }
    if IsDefined(this.popup) { return true; }
    let manager: ref<CustomPopupManager> = CustomPopupManager.GetInstance();
    if !IsDefined(manager) || !manager.IsInitialized() { return false; }
    let popup: ref<CRFieldCarePopup> = new CRFieldCarePopup();
    popup.SetOwner(this);
    this.popup = popup;
    manager.ShowPopup(popup);
    return true;
  }

  private func MakeText(parent: ref<inkCompoundWidget>, name: CName, caption: String, width: Float, height: Float, interactive: Bool) -> ref<inkText> {
    let text: ref<inkText> = new inkText();
    text.SetName(name);
    text.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily", n"Medium");
    text.SetFontSize(28);
    text.SetSize(Vector2(width, height));
    text.SetHorizontalAlignment(textHorizontalAlignment.Center);
    text.SetHAlign(inkEHorizontalAlign.Center);
    text.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
    text.BindProperty(n"tintColor", n"MainColors.Red");
    text.SetText(caption);
    text.SetInteractive(interactive);
    if interactive {
      text.RegisterToCallback(n"OnRelease", this, n"OnRelease");
      text.RegisterToCallback(n"OnEnter", this, n"OnEnter");
    }
    text.Reparent(parent);
    return text;
  }

  public func BuildContent(parent: ref<inkCompoundWidget>) -> Void {
    ArrayClear(this.controls);
    ArrayClear(this.regionButtons);
    let title: ref<inkText> = this.MakeText(parent, n"CRCareTitle", "realpass  |  FIELD CARE", 1600.0, 64.0, false);
    title.SetFontSize(44);
    this.MakeText(parent, n"CRCareHelp", "Select a region, then a treatment. Stay still and out of combat until care completes.", 1600.0, 60.0, false);
    this.injurySummary = this.MakeText(parent, n"CRCareInjuries", "", 1600.0, 100.0, false);

    let row: ref<inkHorizontalPanel>;
    let i: Int32 = 0;
    while i < 6 {
      if i == 0 || i == 3 {
        row = new inkHorizontalPanel();
        row.SetHAlign(inkEHorizontalAlign.Center);
        row.Reparent(parent);
      }
      let button: ref<inkText> = this.MakeText(row, this.ControlName(i), this.RegionName(i + 1), 520.0, 64.0, true);
      ArrayPush(this.regionButtons, button);
      ArrayPush(this.controls, button);
      i += 1;
    }

    row = new inkHorizontalPanel();
    row.SetHAlign(inkEHorizontalAlign.Center);
    row.Reparent(parent);
    ArrayPush(this.controls, this.MakeText(row, n"CRCareDress", "", 520.0, 88.0, true));
    ArrayPush(this.controls, this.MakeText(row, n"CRCareSupport", "", 520.0, 88.0, true));
    ArrayPush(this.controls, this.MakeText(row, n"CRCareCancel", "", 520.0, 88.0, true));
    this.message = this.MakeText(parent, n"CRCareMessage", "", 1600.0, 120.0, false);
    ArrayPush(this.controls, this.MakeText(parent, n"CRCareClose", "", 1600.0, 64.0, true));
    this.MakeText(parent, n"CRCareNavigation", "Directional input moves; confirm selects; cancel returns.", 1600.0, 64.0, false);
    this.Refresh("");
  }

  private func ControlName(index: Int32) -> CName {
    switch index {
      case 0: return n"CRCareHead";
      case 1: return n"CRCareTorso";
      case 2: return n"CRCareLeftArm";
      case 3: return n"CRCareRightArm";
      case 4: return n"CRCareLeftLeg";
      case 5: return n"CRCareRightLeg";
      case 6: return n"CRCareDress";
      case 7: return n"CRCareSupport";
      case 8: return n"CRCareCancel";
      case 9: return n"CRCareClose";
    }
    return n"";
  }

  private func RegionName(region: Int32) -> String {
    switch region {
      case 1: return "Head";
      case 2: return "Torso";
      case 3: return "Left arm";
      case 4: return "Right arm";
      case 5: return "Left leg";
      case 6: return "Right leg";
    }
    return "Unknown";
  }

  private func UpdateActionLabels() -> Void {
    let captions: array<String>;
    ArrayPush(captions, "Apply dressing\n8 sec  |  1 trauma kit");
    ArrayPush(captions, "Support limb\n12 sec  |  1 trauma kit");
    ArrayPush(captions, "Cancel queued care");
    ArrayPush(captions, "Close field care");
    let i: Int32 = 6;
    while i < ArraySize(this.controls) {
      this.controls[i].SetText((this.focus == i ? "> " : "") + captions[i - 6]);
      i += 1;
    }
  }

  public func Navigate(delta: Int32) -> Void {
    this.focus = Clamp(this.focus + delta, 0, 9);
    this.Refresh("");
  }

  public func Confirm() -> Void { this.Activate(this.ControlName(this.focus)); }

  private cb func OnEnter(evt: ref<inkPointerEvent>) -> Bool {
    if !IsDefined(evt.GetTarget()) { return false; }
    let name: CName = evt.GetTarget().GetName();
    if Equals(name, n"CRCareOpen") { return true; }
    if !IsDefined(this.popup) || !this.popup.CanInteract() { return false; }
    let i: Int32 = 0;
    while i < ArraySize(this.controls) {
      if Equals(name, this.ControlName(i)) { this.focus = i; this.Refresh(""); return true; }
      i += 1;
    }
    return false;
  }

  private cb func OnRelease(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsHandled() || !evt.IsAction(n"click") || !IsDefined(evt.GetTarget()) { return false; }
    if Equals(evt.GetTarget().GetName(), n"CRCareOpen") {
      if this.Open() { evt.Handle(); return true; }
      return false;
    }
    if this.Activate(evt.GetTarget().GetName()) { evt.Handle(); return true; }
    return false;
  }

  private func Refresh(result: String) -> Void {
    if !IsDefined(this.message) { return; }
    let i: Int32 = 0;
    let label: String;
    while i < ArraySize(this.regionButtons) {
      label = this.RegionName(i + 1);
      if this.region == i + 1 { label = "[ " + label + " ]"; }
      if this.focus == i { label = "> " + label; }
      this.regionButtons[i].SetText(label);
      i += 1;
    }

    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let summary: String = this.RegionName(this.region) + "  |  Trauma kits: " + ToString(CRFieldCareInventory.Count(player));
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if IsDefined(body) {
      if CRFieldCareModel.CanHelp(body.injuries, this.region, 2) { summary += "  |  external bleeding: dressing can help"; }
      if CRFieldCareModel.CanHelp(body.injuries, this.region, 3) { summary += "  |  bone injury: support can help"; }
    }
    if !CRBodyRuntime.Get().CanUseFieldCare() { summary += "  |  care unavailable here"; }
    if Equals(result, "") { result = CRFieldCareActionRuntime.Get().Status(); }
    if Equals(result, "") { result = "Field care does not restore lost blood, heal bone, stop internal bleeding or repair chrome."; }
    this.message.SetText(summary + "\n" + result);
    this.injurySummary.SetText(IsDefined(body) ? CRBodyStatusPresentation.InjuryStatus(body.injuries) : "Injury status unavailable");
    this.UpdateActionLabels();
  }

  public func Activate(name: CName) -> Bool {
    if !IsDefined(this.popup) || !this.popup.CanInteract() || !this.alive { return false; }
    let kind: Int32 = 0;
    switch name {
      case n"CRCareClose": this.popup.Close(); return true;
      case n"CRCareHead": this.region = 1; break;
      case n"CRCareTorso": this.region = 2; break;
      case n"CRCareLeftArm": this.region = 3; break;
      case n"CRCareRightArm": this.region = 4; break;
      case n"CRCareLeftLeg": this.region = 5; break;
      case n"CRCareRightLeg": this.region = 6; break;
      case n"CRCareCancel": CRFieldCareActionRuntime.Get().Cancel(false); break;
      case n"CRCareDress": kind = 2; break;
      case n"CRCareSupport": kind = 3; break;
      default: return false;
    }

    let feedback: String = "";
    let outcome: Int32;
    if kind > 0 {
      outcome = CRBodyRuntime.Get().UseFieldCare(this.region, kind);
      switch outcome {
        case 8: feedback = CRFieldCareActionRuntime.Get().Status(); break;
        case 1: feedback = "Treatment applied to " + this.RegionName(this.region) + ". Used 1 trauma kit."; break;
        case 2: feedback = "A trauma kit is required."; break;
        case 3: feedback = "Body state changed. Treatment cancelled and the trauma kit returned."; break;
        case 4: feedback = "Treatment failed and the kit could not be returned."; break;
        case 5: feedback = "The kit could not be used. No treatment was applied."; break;
        case 6: feedback = "That treatment would not help this region. No kit used."; break;
        default: feedback = "Care unavailable during combat, travel, protected scenes or pending body updates. No kit used.";
      }
    }
    this.Refresh(feedback);
    return true;
  }
}

public class CRFieldCarePopup extends CustomPopup {
  private let owner: ref<CRFieldCareUI>;
  private let closing: Bool = false;

  public func SetOwner(owner: ref<CRFieldCareUI>) -> Void { this.owner = owner; }
  public func UseCursor() -> Bool { return true; }
  public func CanInteract() -> Bool {
    return !this.closing && this.IsInitialized() && this.IsTopPopup() && IsDefined(this.owner) && this.owner.IsAlive();
  }

  protected cb func OnCreate() {
    super.OnCreate();
    let background: ref<inkRectangle> = new inkRectangle();
    background.SetAnchor(inkEAnchor.Fill);
    background.SetTintColor(new HDRColor(0.01, 0.01, 0.015, 1.0));
    background.SetOpacity(0.97);
    background.SetInteractive(true);
    background.Reparent(this.GetRootCompoundWidget());
    let panel: ref<inkVerticalPanel> = new inkVerticalPanel();
    panel.SetName(n"CRFieldCarePanel");
    panel.SetAnchor(inkEAnchor.Centered);
    panel.SetAnchorPoint(Vector2(0.5, 0.5));
    panel.SetSize(Vector2(1600.0, 800.0));
    panel.Reparent(this.GetRootCompoundWidget());
    this.owner.BuildContent(panel);
  }

  protected cb func OnShown() {
    if !IsDefined(this.owner) || !this.owner.IsAlive() { this.Close(); }
  }

  public func Close() {
    if this.closing { return; }
    this.closing = true;
    super.Close();
  }

  protected cb func OnDetach() {
    this.closing = true;
    if IsDefined(this.owner) { this.owner.PopupClosed(this); }
    super.OnDetach();
  }

  protected cb func OnGlobalReleaseInput(evt: ref<inkPointerEvent>) -> Bool {
    if super.OnGlobalReleaseInput(evt) { return true; }
    if evt.IsHandled() || !this.CanInteract() { return false; }
    if evt.IsAction(n"navigate_left") { this.owner.Navigate(-1); }
    else { if evt.IsAction(n"navigate_right") { this.owner.Navigate(1); }
    else { if evt.IsAction(n"navigate_up") { this.owner.Navigate(-3); }
    else { if evt.IsAction(n"navigate_down") { this.owner.Navigate(3); }
    else { if evt.IsAction(n"proceed") || evt.IsAction(n"select") { this.owner.Confirm(); }
    else { return false; } } } } }
    evt.Handle();
    return true;
  }
}

@addField(BackpackMainGameController)
private let crFieldCare: ref<CRFieldCareUI>;

@wrapMethod(BackpackMainGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  if CRBodyRuntimePolicy.Enabled() && CRCombatRuntimePolicy.Enabled() {
    this.crFieldCare = CRFieldCareUI.Create(this.GetRootCompoundWidget());
  }
  return result;
}

@wrapMethod(BackpackMainGameController)
protected cb func OnUninitialize() -> Bool {
  if IsDefined(this.crFieldCare) {
    this.crFieldCare.Teardown();
    this.crFieldCare = null;
  }
  return wrappedMethod();
}

public class CRFieldCareMenuSession extends ScriptableSystem {
  private let current: wref<CRFieldCareUI>;

  public static func Get() -> ref<CRFieldCareMenuSession> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRFieldCareMenuSession>()) as CRFieldCareMenuSession;
  }

  public func Register(ui: wref<CRFieldCareUI>) -> Void {
    if IsDefined(this.current) && !Equals(this.current, ui) { this.current.Teardown(); }
    this.current = ui;
  }

  public func Clear(ui: wref<CRFieldCareUI>) -> Void {
    if Equals(this.current, ui) { this.current = null; }
  }

  public func RequestOpen() -> Bool {
    return IsDefined(this.current) && this.current.IsAlive() && this.current.Open();
  }
}
