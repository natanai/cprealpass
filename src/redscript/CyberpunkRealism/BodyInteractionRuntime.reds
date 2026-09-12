// Original game interaction adapters. No independent timer or background helper.
import CyberpunkRealism.Integration.*

@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  if CRBodyRuntimePolicy.Enabled() && !evt.isAppliedOnSpawn && Equals(evt.staticData.GetID(), t"HousingStatusEffect.Refreshed") {
    CRBodyRuntime.Get().CompleteBodyInteraction(1);
  }
  return result;
}

// A distinct explicit action. Merely flushing a toilet never changes body state.
public class CRUseToilet extends ActionBool {
  public let completedByDevice: Bool = false;
  public let bodyApplied: Bool = false;

  public func SetProperties() -> Void {
    this.actionName = n"CRUseToilet";
    this.prop = DeviceActionPropertyFunctions.SetUpProperty_Bool(n"CRUseToilet", true, n"Use toilet", n"Use toilet");
  }

  public func GetTweakDBChoiceRecord() -> String {
    return "Flush";
  }

  public func SetBodyCaption() -> Void {
    this.interactionChoice.caption = "Use toilet";
    // GetInteractionChoice generates Flush text from the borrowed record when
    // captionParts is empty. The HUD renders those parts ahead of caption.
    InteractionChoiceCaption.Clear(this.interactionChoice.captionParts);
    InteractionChoiceCaption.AddTextPart(this.interactionChoice.captionParts, "Use toilet");
  }
}

@addField(ToiletControllerPS)
private let crBodyUseActive: Bool = false;

@wrapMethod(ToiletControllerPS)
public func GetActions(out actions: array<ref<DeviceAction>>, context: GetActionsContext) -> Bool {
  let result: Bool = wrappedMethod(actions, context);
  if !CRBodyRuntimePolicy.Enabled() || !CRBodyRuntime.Get().CanUseBodyInteraction() || this.crBodyUseActive || this.m_isFlushing || NotEquals(context.requestType, gamedeviceRequestType.Direct) {
    return result;
  }
  if !IsDefined(context.processInitiatorObject) || !context.processInitiatorObject.IsPlayer() {
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
  if evt.IsStarted() {
    if this.crBodyUseActive || this.m_isFlushing || !CRBodyRuntimePolicy.Enabled() || !CRBodyRuntime.Get().CanUseBodyInteraction() || !IsDefined(evt.GetExecutor()) || !evt.GetExecutor().IsPlayer() {
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
  if evt.completedByDevice && !evt.bodyApplied && IsDefined(evt.GetExecutor()) && evt.GetExecutor().IsPlayer() {
    evt.bodyApplied = true;
    // Walking away, entering combat or a protected scene cancels bodily relief.
    if Vector4.DistanceSquared(evt.GetExecutor().GetWorldPosition(), this.GetWorldPosition()) <= 9.0 && CRBodyRuntime.Get().CanUseBodyInteraction() {
      if CRBodyRuntime.Get().CompleteBodyInteraction(4) {
        GameObject.PlaySoundEvent(this, this.GetDevicePS().GetFlushSFX());
      }
    }
  }
  this.UpdateDeviceState();
  return true;
}
