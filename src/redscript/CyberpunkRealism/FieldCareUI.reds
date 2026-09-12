// Original backpack entry and modal regional treatment controls.
// Uses the pinned Codeware popup layer and game fonts; no custom archive assets.
module DarkFuture.UI
import CyberpunkRealism.Integration.*
import CyberpunkRealism.Physiology.*
import Codeware.UI.*

public class CRFieldCareUI extends IScriptable {
  private let alive: Bool = true;
  private let region: Int32 = 2;
  private let focus: Int32 = 1;
  private let popup: wref<CRFieldCarePopup>;
  private let message: wref<inkText>;
  private let injurySummary: wref<inkText>;
  private let bodyNote: wref<inkText>;
  private let regionButtons: array<wref<inkText>>;
  private let controls: array<wref<inkText>>;

  public static func Create(parent: ref<inkCompoundWidget>, note: ref<inkText>) -> ref<CRFieldCareUI> {
    if !CRBodyPreviewUI.Owns() || !CRCombatRuntimePolicy.Enabled() { return null; }
    let ui: ref<CRFieldCareUI> = new CRFieldCareUI();
    ui.bodyNote = note;
    CRFieldCareMenuSession.Get().Register(ui);
    ui.Button(parent, n"CRCareOpen", "realpass  |  FIELD CARE  |  Inspect injuries and choose treatment", 1760.0, 42.0);
    return ui;
  }

  public func IsAlive() -> Bool { return this.alive; }

  public func Teardown() -> Void {
    this.alive = false;
    CRFieldCareMenuSession.Get().Clear(this);
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
    if !this.alive || !CRBodyPreviewUI.Owns() || !CRCombatRuntimePolicy.Enabled() { return false; }
    if IsDefined(this.popup) { return true; }
    let manager: ref<CustomPopupManager> = CustomPopupManager.GetInstance();
    if !IsDefined(manager) || !manager.IsInitialized() { return false; }
    let popup: ref<CRFieldCarePopup> = new CRFieldCarePopup();
    popup.SetOwner(this);
    this.popup = popup;
    manager.ShowPopup(popup);
    return true;
  }

  public func BuildContent(parent: ref<inkCompoundWidget>) -> Void {
    ArrayClear(this.controls);
    ArrayClear(this.regionButtons);
    this.Label(parent, n"CRCareTitle", "realpass  |  FIELD CARE", 1600.0, 64.0).SetFontSize(44);
    this.Label(parent, n"CRCareHelp", "Select a region, then a treatment. Close the backpack and stay still to complete care.", 1600.0, 60.0);
    this.injurySummary = this.Label(parent, n"CRCareInjuries", "", 1600.0, 100.0);
    let row: ref<inkHorizontalPanel>;
    let i: Int32 = 0;
    while i < 6 {
      if i == 0 || i == 3 {
        row = new inkHorizontalPanel();
        row.SetHAlign(inkEHorizontalAlign.Center);
        row.Reparent(parent);
      }
      let button: ref<inkText> = this.Button(row, this.ControlName(i), this.RegionName(i + 1), 520.0, 64.0);
      ArrayPush(this.regionButtons, button);
      ArrayPush(this.controls, button);
      i += 1;
    }
    row = new inkHorizontalPanel();
    row.SetHAlign(inkEHorizontalAlign.Center);
    row.Reparent(parent);
    ArrayPush(this.controls, this.Button(row, n"CRCareDress", "", 520.0, 88.0));
    ArrayPush(this.controls, this.Button(row, n"CRCareSupport", "", 520.0, 88.0));
    ArrayPush(this.controls, this.Button(row, n"CRCareCancel", "", 520.0, 88.0));
    this.message = this.Label(parent, n"CRCareMessage", "", 1600.0, 120.0);
    ArrayPush(this.controls, this.Button(parent, n"CRCareClose", "", 1600.0, 64.0));
    this.Label(parent, n"CRCareNavigation", "Move between controls with directional input; confirm to select; cancel to return.", 1600.0, 64.0);
    this.Refresh("");
  }

  private func Label(parent: ref<inkCompoundWidget>, name: CName, caption: String, width: Float, height: Float) -> ref<inkText> {
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
    text.SetInteractive(false);
    text.Reparent(parent);
    return text;
  }

  private func Button(parent: ref<inkCompoundWidget>, name: CName, caption: String, width: Float, height: Float) -> ref<inkText> {
    let text: ref<inkText> = this.Label(parent, name, caption, width, height);
    text.SetInteractive(true);
    text.RegisterToCallback(n"OnRelease", this, n"OnRelease");
    text.RegisterToCallback(n"OnEnter", this, n"OnEnter");
    return text;
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

  private func UpdateActionLabels() -> Void {
    let captions: array<String>;
    ArrayPush(captions, "Apply dressing\n8 sec  |  1 trauma kit");
    ArrayPush(captions, "Support limb\n12 sec  |  1 trauma kit");
    ArrayPush(captions, "Cancel queued care");
    ArrayPush(captions, "Return to backpack");
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
    if !IsDefined(this.popup) || !this.popup.CanInteract() || !IsDefined(evt.GetTarget()) { return false; }
    let i: Int32 = 0;
    while i < ArraySize(this.controls) {
      if Equals(evt.GetTarget().GetName(), this.ControlName(i)) { this.focus = i; this.Refresh(""); return true; }
      i += 1;
    }
    return false;
  }

  private cb func OnRelease(evt: ref<inkPointerEvent>) -> Bool {
    if evt.IsHandled() || !evt.IsAction(n"click") || !IsDefined(evt.GetTarget()) { return false; }
    if Equals(evt.GetTarget().GetName(), n"CRCareOpen") { this.Open(); evt.Handle(); return true; }
    if this.Activate(evt.GetTarget().GetName()) { evt.Handle(); return true; }
    return false;
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

  private func Refresh(result: String) -> Void {
    if !IsDefined(this.message) { return; }
    let i: Int32 = 0;
    let label: String;
    while i < ArraySize(this.regionButtons) {
      label = this.RegionName(i + 1);
      if this.region == i + 1 {
        label = "[ " + label + " ]";
      }
      if this.focus == i { label = "> " + label; }
      this.regionButtons[i].SetText(label);
      i += 1;
    }
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let summary: String = this.RegionName(this.region) + "  |  Trauma kits: " + ToString(CRFieldCareInventory.Count(player));
    let body: ref<CRBodyState> = CRBodyRuntime.Get().GetBodySnapshot();
    if IsDefined(body) {
      if CRFieldCareModel.CanHelp(body.injuries, this.region, 2) {
        summary += "  |  External bleeding: dressing can help";
      }
      if CRFieldCareModel.CanHelp(body.injuries, this.region, 3) {
        summary += "  |  Bone injury: support can help";
      }
    }
    if !CRBodyRuntime.Get().CanUseFieldCare() {
      summary += "  |  Care unavailable here";
    }
    if Equals(result, "") {
      result = CRFieldCareActionRuntime.Get().Status();
    }
    if Equals(result, "") {
      result = "Field care does not restore lost blood, heal bone, stop internal bleeding or repair chrome.";
    }
    this.message.SetText(summary + "\n" + result);
    let bodySummary: String = "Injury status unavailable";
    if IsDefined(body) { bodySummary = CRBodyPreviewUI.InjuryStatus(body.injuries); }
    this.injurySummary.SetText(bodySummary);
    this.UpdateActionLabels();
    CRBodyPreviewUI.ShowCurrent(this.bodyNote);
  }

  public func Activate(name: CName) -> Bool {
    if !IsDefined(this.popup) || !this.popup.CanInteract() || !this.alive { return false; }
    let kind: Int32 = 0;
    switch name {
      case n"CRCareClose":
        this.popup.Close();
        return true;
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
        case 2: feedback = "A trauma kit is required. Available from medical vendors."; break;
        case 3: feedback = "Body state changed. Treatment cancelled and the trauma kit returned."; break;
        case 4: feedback = "Treatment failed and the kit could not be returned. Please report this error."; break;
        case 5: feedback = "The kit could not be used. No treatment was applied."; break;
        case 6: feedback = "That treatment would not help this region. No kit used."; break;
        case 7: feedback = "Resolve the existing injury with its normal treatment before using regional care. No kit used."; break;
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

@wrapMethod(BackpackMainGameController)
protected cb func OnUninitialize() -> Bool {
  if IsDefined(this.crFieldCare) { this.crFieldCare.Teardown(); }
  return wrappedMethod();
}

// Transient menu registration shared by standard and Revised Backpack.
public class CRFieldCareMenuSession extends ScriptableSystem {
  private let current: wref<CRFieldCareUI>;

  public static func Get() -> ref<CRFieldCareMenuSession> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRFieldCareMenuSession>()) as CRFieldCareMenuSession;
  }

  public func Register(ui: wref<CRFieldCareUI>) -> Void {
    if IsDefined(this.current) && !Equals(this.current, ui) {
      this.current.Teardown();
    }
    this.current = ui;
  }

  public func Clear(ui: wref<CRFieldCareUI>) -> Void {
    if Equals(this.current, ui) { this.current = null; }
  }

  public func RequestOpen() -> Bool {
    return IsDefined(this.current) && this.current.IsAlive() && this.current.Open();
  }
}