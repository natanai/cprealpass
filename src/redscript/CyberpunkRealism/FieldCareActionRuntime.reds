// Original short-lived gameplay action. No external process or diagnostic output.
module CyberpunkRealism.Integration
import CyberpunkRealism.Physiology.*

public class CRFieldCareActionCallback extends DelayCallback {
  public let owner: wref<CRFieldCareActionRuntime>;
  public let action: ref<CRFieldCareAction>;
  public let sample: Int32;
  public func Call() -> Void {
    if IsDefined(this.owner) {
      this.owner.OnSample(this.action, this.sample);
    }
  }
}
public class CRFieldCareActionRuntime extends ScriptableSystem {
  private let action: ref<CRFieldCareAction>;
  private let delay: DelayID;
  private let pending: Bool;
  private let completing: Bool;
  private let origin: Vector4;
  private let status: String;
  public static func Get() -> ref<CRFieldCareActionRuntime> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(NameOf<CRFieldCareActionRuntime>()) as CRFieldCareActionRuntime;
  }
  private func OnDetach() -> Void {
    this.Cancel(false);
  }
  private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    this.Cancel(false);
  }
  public func Active() -> Bool {
    return IsDefined(this.action);
  }
  public func Status() -> String {
    return this.status;
  }
  private static func InMenu() -> Bool {
    let board: ref<IBlackboard> = GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_System);
    return IsDefined(board) && board.GetBool(GetAllBlackboardDefs().UI_System.IsInMenu);
  }
  public static func HandsAvailable(player: ref<PlayerPuppet>) -> Bool {
    let board: ref<IBlackboard>;
    let weapon: gamePSMRangedWeaponStates;
    if !IsDefined(player) {
      return false;
    }
    board = player.GetPlayerStateMachineBlackboard();
    weapon = IntEnum<gamePSMRangedWeaponStates>(board.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Weapon));
    if !Equals(weapon, gamePSMRangedWeaponStates.Default) && !Equals(weapon, gamePSMRangedWeaponStates.Ready) && !Equals(weapon, gamePSMRangedWeaponStates.Safe) && !Equals(weapon, gamePSMRangedWeaponStates.NoAmmo) {
      return false;
    }
    return board.GetInt(GetAllBlackboardDefs().PlayerStateMachine.MeleeWeapon) == 0 && board.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Consumable) == 0 && board.GetInt(GetAllBlackboardDefs().PlayerStateMachine.CombatGadget) == 0 && board.GetInt(GetAllBlackboardDefs().PlayerStateMachine.LeftHandCyberware) == 0 && !Equals(IntEnum<gamePSMUpperBodyStates>(board.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody)), gamePSMUpperBodyStates.Aim);
  }
  private func CompletionContext() -> Bool {
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    return CRBodyRuntime.Get().CanContinueFieldCare() && !CRFieldCareActionRuntime.InMenu() && CRFieldCareActionRuntime.HandsAvailable(player) && Vector4.Length(player.GetVelocity()) <= 0.25 && Vector4.DistanceSquared(player.GetWorldPosition(), this.origin) <= 0.5625;
  }
  public func IsCompleting(action: ref<CRFieldCareAction>) -> Bool {
    return this.completing && IsDefined(action) && Equals(this.action, action) && action.stage == 3 && this.CompletionContext();
  }
  private func Notify(message: String, duration: Float) -> Void {
    let warning: SimpleScreenMessage;
    warning.isShown = true;
    warning.duration = duration;
    warning.message = "realpass  |  " + message;
    GameInstance.GetBlackboardSystem(GetGameInstance()).Get(GetAllBlackboardDefs().UI_Notifications).SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(warning), true);
  }
  private func Unschedule() -> Void {
    if this.pending {
      GameInstance.GetDelaySystem(GetGameInstance()).CancelCallback(this.delay);
      this.pending = false;
    }
  }
  private func Schedule() -> Void {
    let callback: ref<CRFieldCareActionCallback>;
    if !IsDefined(this.action) || this.pending || this.completing {
      return;
    }
    callback = new CRFieldCareActionCallback();
    callback.owner = this;
    callback.action = this.action;
    callback.sample = this.action.samples + 1;
    this.delay = GameInstance.GetDelaySystem(GetGameInstance()).DelayCallback(callback, 0.25, false);
    if Equals(this.delay, GetInvalidDelayID()) {
      this.Cancel(false);
      return;
    }
    this.pending = true;
  }
  public func OnMenuBoundary() -> Void {
    if IsDefined(this.action) && this.action.stage == 2 && CRFieldCareActionRuntime.InMenu() {
      this.Cancel(false);
    }
  }
  public func Cancel(notify: Bool) -> Void {
    let active: Bool = IsDefined(this.action);
    this.Unschedule();
    if active {
      this.action.stage = 0;
    }
    this.action = null;
    this.completing = false;
    if active {
      this.status = "Field care cancelled.";
      if notify {
        this.Notify(this.status, 3.0);
      }
    }
  }
  public func Begin(region: Int32, kind: Int32) -> Int32 {
    let player: ref<PlayerPuppet>;
    let body: ref<CRBodyState>;
    if this.Active() || !CRBodyRuntime.Get().CanUseFieldCare() {
      return 0;
    }
    CRBodyRuntime.Get().Observe();
    body = CRBodyRuntime.Get().GetBodySnapshot();
    if !IsDefined(body) || !CRFieldCareModel.CanHelp(body.injuries, region, kind) {
      return 6;
    }
    player = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if CRFieldCareInventory.Count(player, kind) < 1 {
      return 2;
    }
    this.action = CRFieldCareActionModel.Create(region, kind);
    if !IsDefined(this.action) {
      return 6;
    }
    this.status = "Close inventory and stay still for " + ToString(Cast<Int32>(CRFieldCareActionModel.Duration(kind))) + " seconds. Reopening a menu or moving cancels care.";
    this.Schedule();
    if !this.Active() {
      return 0;
    }
    return 8;
  }
  public func OnSample(action: ref<CRFieldCareAction>, sample: Int32) -> Void {
    let player: ref<PlayerPuppet>;
    let moving: Bool;
    let result: Int32;
    let outcome: Int32;
    if !IsDefined(action) || !Equals(this.action, action) || this.completing || !this.pending || sample != action.samples + 1 {
      return;
    }
    this.pending = false;
    player = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    moving = !IsDefined(player);
    if IsDefined(player) {
      moving = Vector4.Length(player.GetVelocity()) > 0.25;
      if action.stage == 2 && Vector4.DistanceSquared(player.GetWorldPosition(), this.origin) > 0.5625 {
        moving = true;
      }
    }
    result = CRFieldCareActionModel.Sample(action, GameInstance.GetSimTime(GetGameInstance()).ToFloat(), CRBodyRuntime.Get().CanUseFieldCare() && CRFieldCareActionRuntime.HandsAvailable(player), CRFieldCareActionRuntime.InMenu(), moving);
    if result == 0 {
      this.Cancel(true);
      return;
    }
    if result == 2 {
      this.origin = player.GetWorldPosition();
      this.status = "Field care in progress. Stay still; moving or opening a menu cancels.";
      this.Notify(this.status, CRFieldCareActionModel.Duration(action.kind));
    }
    if result == 4 {
      this.completing = true;
      outcome = CRBodyRuntime.Get().CommitFieldCare(action);
      this.completing = false;
      this.action = null;
      this.Unschedule();
      if outcome == 1 {
        this.status = "Field care completed. Used 1 treatment supply.";
      } else {
        if outcome == 4 {
          this.status = "Field care failed and the treatment supply could not be returned. Please report this error.";
        } else {
          this.status = "Field care did not complete. No treatment supply used, or the supply was returned.";
        }
      }
      this.Notify(this.status, 4.0);
      return;
    }
    this.Schedule();
  }
}
