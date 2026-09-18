// Shared project-original INK primitives for Biology's E3-inspired presentation.
//
// W03.3 deliberately sizes owned presentation from the native controller root instead
// of guessing large fixed canvases inside controller-local layouts. This keeps the
// treatment visible without replacing CDPR controller logic and makes E3 OFF a clean
// yield: owned shells are hidden rather than native roots being repainted.
module CyberpunkRealism.Presentation

public class CRBiologyE3Primitives extends IScriptable {
  public static func Red() -> HDRColor {
    return new HDRColor(1.1761, 0.1400, 0.1200, 1.0);
  }

  public static func Trace(hook: String) -> Void {
    LogChannel(n"DEBUG", "[Biology:E3] " + hook);
  }

  public static func CreateFillShell(parent: ref<inkCompoundWidget>, name: CName) -> ref<inkCanvas> {
    let shell: ref<inkCanvas> = new inkCanvas();
    if !IsDefined(parent) {
      return shell;
    }
    shell.SetName(name);
    shell.SetAnchor(inkEAnchor.Fill);
    shell.SetSizeRule(inkESizeRule.Stretch);
    shell.Reparent(parent, -1);
    return shell;
  }

  public static func AddFillWash(parent: ref<inkCompoundWidget>, name: CName, opacity: Float) -> ref<inkRectangle> {
    let widget: ref<inkRectangle> = new inkRectangle();
    if !IsDefined(parent) {
      return widget;
    }
    widget.SetName(name);
    widget.SetAnchor(inkEAnchor.Fill);
    widget.SetSizeRule(inkESizeRule.Stretch);
    widget.SetTintColor(CRBiologyE3Primitives.Red());
    widget.SetOpacity(opacity);
    widget.Reparent(parent, 0);
    return widget;
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

  public static func AddLabel(parent: ref<inkCompoundWidget>, name: CName, text: String, x: Float, y: Float, size: Int32, opacity: Float) -> ref<inkText> {
    let label: ref<inkText> = new inkText();
    if !IsDefined(parent) {
      return label;
    }
    label.SetName(name);
    label.SetText(text);
    label.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    label.SetFontStyle(n"Medium");
    label.SetFontSize(size);
    label.SetFitToContent(true);
    label.SetTranslation(x, y);
    label.SetTintColor(CRBiologyE3Primitives.Red());
    label.SetOpacity(opacity);
    label.Reparent(parent, -1);
    return label;
  }
}
