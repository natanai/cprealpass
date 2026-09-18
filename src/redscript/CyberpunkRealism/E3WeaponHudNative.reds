// Biology-owned E3-inspired weapon/ammo presentation.
//
// T003 proved the controller-root shell floats near lower-center while the actual
// on-foot weapon HUD is lower-right. W03.5 binds Biology chrome to the native 2.31
// m_onFootContainer, with m_weaponAmmoWrapper only as a semantic fallback. Because the
// chrome is a child of the authored content host it inherits native fold/visibility/
// animation coordinates; no arbitrary screen offset is used.
module CyberpunkRealism.Presentation

import CyberpunkRealism.Settings.*

@addField(WeaponRosterGameController)
private let crBiologyE3WeaponFrame: ref<inkCanvas>;

@addField(WeaponRosterGameController)
private let crBiologyE3WeaponHost: ref<inkCompoundWidget>;

@addField(WeaponRosterGameController)
private let crBiologyE3WeaponHostName: String;

@addField(WeaponRosterGameController)
private let crBiologyE3NativeWeaponNameTint: HDRColor;

@addField(WeaponRosterGameController)
private let crBiologyE3NativeCurrentAmmoTint: HDRColor;

@addField(WeaponRosterGameController)
private let crBiologyE3NativeTotalAmmoTint: HDRColor;

@addField(WeaponRosterGameController)
private let crBiologyE3HasNativeWeaponTints: Bool;

@addField(WeaponRosterGameController)
private let crBiologyE3WeaponStateKnown: Bool;

@addField(WeaponRosterGameController)
private let crBiologyE3WeaponLastEnabled: Bool;

@addMethod(WeaponRosterGameController)
private final func CRResolveBiologyE3WeaponHost() -> ref<inkCompoundWidget> {
  let host: ref<inkCompoundWidget> = inkWidgetRef.Get(this.m_onFootContainer) as inkCompoundWidget;
  if IsDefined(host) {
    this.crBiologyE3WeaponHostName = "m_onFootContainer";
    return host;
  }

  host = inkWidgetRef.Get(this.m_weaponAmmoWrapper) as inkCompoundWidget;
  if IsDefined(host) {
    this.crBiologyE3WeaponHostName = "m_weaponAmmoWrapper";
    return host;
  }

  this.crBiologyE3WeaponHostName = "UNRESOLVED";
  return null;
}

@addMethod(WeaponRosterGameController)
private final func CRCaptureBiologyE3WeaponTints() -> Void {
  let nameText: ref<inkText>;
  let currentAmmoText: ref<inkText>;
  let totalAmmoText: ref<inkText>;

  if this.crBiologyE3HasNativeWeaponTints {
    return;
  }

  nameText = inkTextRef.Get(this.m_weaponName) as inkText;
  currentAmmoText = inkTextRef.Get(this.m_weaponCurrentAmmo) as inkText;
  totalAmmoText = inkTextRef.Get(this.m_weaponTotalAmmo) as inkText;

  if IsDefined(nameText) && IsDefined(currentAmmoText) && IsDefined(totalAmmoText) {
    this.crBiologyE3NativeWeaponNameTint = nameText.GetTintColor();
    this.crBiologyE3NativeCurrentAmmoTint = currentAmmoText.GetTintColor();
    this.crBiologyE3NativeTotalAmmoTint = totalAmmoText.GetTintColor();
    this.crBiologyE3HasNativeWeaponTints = true;
  }
}

@addMethod(WeaponRosterGameController)
private final func CRCreateBiologyE3WeaponFrame() -> Void {
  if IsDefined(this.crBiologyE3WeaponFrame) {
    return;
  }

  this.crBiologyE3WeaponHost = this.CRResolveBiologyE3WeaponHost();
  if !IsDefined(this.crBiologyE3WeaponHost) {
    CRBiologyE3Primitives.Trace("WeaponRoster content-host unresolved; chrome not mounted");
    return;
  }

  this.crBiologyE3WeaponFrame = CRBiologyE3Primitives.CreateFillShell(this.crBiologyE3WeaponHost, n"CRBiologyE3WeaponFrame");
  CRBiologyE3Primitives.AddPanelChrome(this.crBiologyE3WeaponFrame, "WEAPON // AMMO", 178.0);
}

@addMethod(WeaponRosterGameController)
private final func CRRefreshBiologyE3WeaponFrame() -> Void {
  let enabled: Bool = CRRealpassSettings.UseE3FirstPersonHudVisuals(GetGameInstance());
  let nameText: ref<inkText>;
  let currentAmmoText: ref<inkText>;
  let totalAmmoText: ref<inkText>;

  this.CRCreateBiologyE3WeaponFrame();
  this.CRCaptureBiologyE3WeaponTints();

  if IsDefined(this.crBiologyE3WeaponFrame) {
    this.crBiologyE3WeaponFrame.SetVisible(enabled);
  }

  nameText = inkTextRef.Get(this.m_weaponName) as inkText;
  currentAmmoText = inkTextRef.Get(this.m_weaponCurrentAmmo) as inkText;
  totalAmmoText = inkTextRef.Get(this.m_weaponTotalAmmo) as inkText;

  if enabled {
    if IsDefined(nameText) {
      nameText.SetTintColor(CRBiologyE3Primitives.Red());
    }
    if IsDefined(currentAmmoText) {
      currentAmmoText.SetTintColor(CRBiologyE3Primitives.Red());
    }
    if IsDefined(totalAmmoText) {
      totalAmmoText.SetTintColor(CRBiologyE3Primitives.Red());
    }
  } else {
    if this.crBiologyE3HasNativeWeaponTints {
      if IsDefined(nameText) {
        nameText.SetTintColor(this.crBiologyE3NativeWeaponNameTint);
      }
      if IsDefined(currentAmmoText) {
        currentAmmoText.SetTintColor(this.crBiologyE3NativeCurrentAmmoTint);
      }
      if IsDefined(totalAmmoText) {
        totalAmmoText.SetTintColor(this.crBiologyE3NativeTotalAmmoTint);
      }
    }
  }

  if !this.crBiologyE3WeaponStateKnown || this.crBiologyE3WeaponLastEnabled != enabled {
    CRBiologyE3Primitives.TraceMountedRegion(
      "WeaponRoster",
      this.crBiologyE3WeaponHostName,
      this.crBiologyE3WeaponHost,
      this.crBiologyE3WeaponFrame,
      enabled
    );
    this.crBiologyE3WeaponStateKnown = true;
    this.crBiologyE3WeaponLastEnabled = enabled;
  }
}

@wrapMethod(WeaponRosterGameController)
protected cb func OnInitialize() -> Bool {
  let result: Bool = wrappedMethod();
  CRBiologyE3Primitives.Trace("WeaponRosterGameController.OnInitialize");
  this.CRRefreshBiologyE3WeaponFrame();
  return result;
}

@wrapMethod(WeaponRosterGameController)
private func SetRosterSlotData() -> Void {
  wrappedMethod();
  this.CRRefreshBiologyE3WeaponFrame();
}
