// Original game interaction adapters. No independent timer or background helper.
// Patch-sensitive native hooks live here; body physiology remains in the pure model.
import CyberpunkRealism.Integration.*

@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let runtime: ref<CRBodyRuntime>;
  if CRBodyRuntimeMasterPolicy.Enabled(this.GetGame()) && IsDefined(evt) && IsDefined(evt.staticData)
    && !evt.isAppliedOnSpawn && Equals(evt.staticData.GetID(), t"HousingStatusEffect.Refreshed") {
    runtime = CRBiologySessionAuthority.Body(this.GetGame());
    if IsDefined(runtime) {
      runtime.CompleteBodyInteraction(1);
    }
  }
  return result;
}

// A distinct explicit action. Merely flushing a toilet never changes body state.
// Reuse the stock Flush interaction record as presentation plumbing instead of
// creating a parallel TweakDB interaction record. realpass owns the separate action
// semantics and replaces only its displayed caption after CreateInteraction().
public class CRUseToilet extends ActionBool {
  public let completedByDevice: Bool = false;
  public let bodyApplied: Bool = false;

  public func SetProperties() -> Void {
    this.actionName = n"CRUseToilet";
    this.prop = DeviceActionPropertyFunctions.SetUpProperty_Bool(n"CRUseToilet", true, n"CRUseToilet", n"CRUseToilet");
  }

  public func GetTweakDBChoiceRecord() -> String {
    return "Flush";
  }

  public func GetTweakDBChoiceID() -> TweakDBID {
    return t"Interactions.Flush";
  }

  public func SetBodyCaption() -> Void {
    // Keep the first owned acceptance slice self-contained in REDscript and preserve
    // the vanilla Flush record/icon. A project-owned localization resource can
    // replace this literal later without changing action/body semantics.
    let caption: String = "Use toilet";
    this.interactionChoice.caption = caption;
    InteractionChoiceCaption.Clear(this.interactionChoice.captionParts);
    InteractionChoiceCaption.AddTextPart(this.interactionChoice.captionParts, caption);
  }
}

@addField(ToiletControllerPS)
private let crBodyUseActive: Bool = false;

@wrapMethod(ToiletControllerPS)
public func GetActions(out actions: array<ref<DeviceAction>>, context: GetActionsContext) -> Bool {
  let result: Bool = wrappedMethod(actions, context);
  let runtime: ref<CRBodyRuntime>;
  if this.crBodyUseActive || this.m_isFlushing || NotEquals(context.requestType, gamedeviceRequestType.Direct) {
    return result;
  }
  if !IsDefined(context.processInitiatorObject) || !context.processInitiatorObject.IsPlayer() {
    return result;
  }
  if !CRBodyRuntimeMasterPolicy.Enabled(context.processInitiatorObject.GetGame()) {
    return result;
  }
  runtime = CRBiologySessionAuthority.Body(context.processInitiatorObject.GetGame());
  if !IsDefined(runtime) || !runtime.CanUseBodyInteraction() {
    return result;
  }
  let action: ref<CRUseToilet> = new CRUseToilet();
  action.SetUp(this);
  action.SetProperties();
  action.AddDeviceName(this.GetDeviceName());
  action.SetDurationValue(5.0);
  action.CreateInteraction();
  action.SetBodyCaption();
  ArrayPush(actions, action);
  return result;
}

@addMethod(ToiletControllerPS)
public final func OnCRUseToilet(evt: ref<CRUseToilet>) -> EntityNotificationType {
  let runtime: ref<CRBodyRuntime>;
  if !IsDefined(evt) {
    return EntityNotificationType.DoNotNotifyEntity;
  }
  if evt.IsStarted() {
    if this.crBodyUseActive || this.m_isFlushing || !IsDefined(evt.GetExecutor()) || !evt.GetExecutor().IsPlayer() {
      return EntityNotificationType.DoNotNotifyEntity;
    }
    if !CRBodyRuntimeMasterPolicy.Enabled(evt.GetExecutor().GetGame()) {
      return EntityNotificationType.DoNotNotifyEntity;
    }
    runtime = CRBiologySessionAuthority.Body(evt.GetExecutor().GetGame());
    if !IsDefined(runtime) || !runtime.CanUseBodyInteraction() {
      return EntityNotificationType.DoNotNotifyEntity;
    }
    this.crBodyUseActive = true;
    this.m_isFlushing = true;
    this.ExecutePSActionWithDelay(evt, this, evt.GetDurationValue());
  } else {
    if !this.crBodyUseActive {
      return EntityNotificationType.DoNotNotifyEntity;
    }
    this.crBodyUseActive = false;
    this.m_isFlushing = false;
    evt.completedByDevice = true;
  }
  return EntityNotificationType.SendThisEventToEntity;
}

@addMethod(Toilet)
protected cb func OnCRUseToilet(evt: ref<CRUseToilet>) -> Bool {
  let runtime: ref<CRBodyRuntime>;
  if IsDefined(evt) && evt.completedByDevice && !evt.bodyApplied && IsDefined(evt.GetExecutor()) && evt.GetExecutor().IsPlayer() {
    evt.bodyApplied = true;
    // Walking away, entering combat or a protected scene cancels bodily relief.
    runtime = CRBiologySessionAuthority.Body(evt.GetExecutor().GetGame());
    if CRBodyRuntimeMasterPolicy.Enabled(evt.GetExecutor().GetGame()) && IsDefined(runtime)
      && Vector4.DistanceSquared(evt.GetExecutor().GetWorldPosition(), this.GetWorldPosition()) <= 9.0 && runtime.CanUseBodyInteraction() {
      if runtime.CompleteBodyInteraction(4) {
        GameObject.PlaySoundEvent(this, this.GetDevicePS().GetFlushSFX());
      }
    }
  }
  this.UpdateDeviceState();
  return true;
}
