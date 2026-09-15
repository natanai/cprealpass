// Shared project-original INK primitives for Biology's E3-inspired neutral HUD.
//
// These helpers contain no native hooks and no Project E3 resources. Individual
// controller adapters decide where the visual language is appropriate.
module CyberpunkRealism.Presentation

public class CRBiologyE3Primitives extends IScriptable {
  public static func Red() -> HDRColor {
    return new HDRColor(1.1761, 0.1400, 0.1200, 1.0);
  }

  public static func Neutral() -> HDRColor {
    return new HDRColor(1.0, 1.0, 1.0, 1.0);
  }

  public static func AddRect(parent: ref<inkCompoundWidget>, name: CName, x: Float, y: Float, width: Float, height: Float, opacity: Float) -> ref<inkRectangle> {
    let widget: ref<inkRectangle> = new inkRectangle();
    if !IsDefined(parent) {
      return widget;
    }
    widget.SetName(name);
    widget.SetSize(Vector2(width, height));
    widget.SetTranslation(x, y);
    widget.SetTintColor(CRBiologyE3Primitives.Red());
    widget.SetOpacity(opacity);
    widget.Reparent(parent, -1);
    return widget;
  }

  public static func TintNeutralHudRoot(root: wref<inkWidget>, enabled: Bool) -> Void {
    if IsDefined(root) {
      root.SetTintColor(enabled ? CRBiologyE3Primitives.Red() : CRBiologyE3Primitives.Neutral());
    }
  }
}
