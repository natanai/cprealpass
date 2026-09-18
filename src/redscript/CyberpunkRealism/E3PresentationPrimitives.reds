// Shared project-original INK primitives for Biology's E3-inspired presentation.
//
// W03.4 standardized compact chrome. W03.5 adds bounded geometry traces so attended
// evidence can distinguish "hook fired" from "chrome is mounted in the visible native
// content region". Geometry is read from the native host after mounting; no global
// screen-space offsets are inferred or stored.
module CyberpunkRealism.Presentation

public class CRBiologyE3Primitives extends IScriptable {
  public static func Red() -> HDRColor {
    return new HDRColor(1.1761, 0.1400, 0.1200, 1.0);
  }

  public static func Trace(hook: String) -> Void {
    FTLog("[Biology:E3] " + hook);
  }

  public static func TraceMountedRegion(surface: String, hostName: String, host: ref<inkCompoundWidget>, chrome: ref<inkCanvas>, enabled: Bool) -> Void {
    let hostSize: Vector2;
    let hostTranslation: Vector2;
    let hostMargin: inkMargin;
    let chromeSize: Vector2;
    let chromeTranslation: Vector2;
    let chromeMargin: inkMargin;

    if !IsDefined(host) {
      CRBiologyE3Primitives.Trace(surface + " host=" + hostName + " resolved=false enabled=" + BoolToString(enabled));
      return;
    }

    hostSize = host.GetSize();
    hostTranslation = host.GetTranslation();
    hostMargin = host.GetMargin();

    if !IsDefined(chrome) {
      CRBiologyE3Primitives.Trace(
        surface
        + " host=" + hostName
        + " resolved=true chrome=false enabled=" + BoolToString(enabled)
        + " hostSize=" + FloatToString(hostSize.X) + "x" + FloatToString(hostSize.Y)
        + " hostTranslation=" + FloatToString(hostTranslation.X) + "," + FloatToString(hostTranslation.Y)
        + " hostMargin=" + FloatToString(hostMargin.left) + "," + FloatToString(hostMargin.top) + "," + FloatToString(hostMargin.right) + "," + FloatToString(hostMargin.bottom)
      );
      return;
    }

    chromeSize = chrome.GetSize();
    chromeTranslation = chrome.GetTranslation();
    chromeMargin = chrome.GetMargin();

    CRBiologyE3Primitives.Trace(
      surface
      + " host=" + hostName
      + " resolved=true chrome=true enabled=" + BoolToString(enabled)
      + " hostSize=" + FloatToString(hostSize.X) + "x" + FloatToString(hostSize.Y)
      + " hostTranslation=" + FloatToString(hostTranslation.X) + "," + FloatToString(hostTranslation.Y)
      + " hostMargin=" + FloatToString(hostMargin.left) + "," + FloatToString(hostMargin.top) + "," + FloatToString(hostMargin.right) + "," + FloatToString(hostMargin.bottom)
      + " chromeSize=" + FloatToString(chromeSize.X) + "x" + FloatToString(chromeSize.Y)
      + " chromeTranslation=" + FloatToString(chromeTranslation.X) + "," + FloatToString(chromeTranslation.Y)
      + " chromeMargin=" + FloatToString(chromeMargin.left) + "," + FloatToString(chromeMargin.top) + "," + FloatToString(chromeMargin.right) + "," + FloatToString(chromeMargin.bottom)
    );
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

  public static func AddAnchoredRect(parent: ref<inkCompoundWidget>, name: CName, anchor: inkEAnchor, anchorPoint: Vector2, x: Float, y: Float, width: Float, height: Float, opacity: Float) -> ref<inkRectangle> {
    let widget: ref<inkRectangle> = new inkRectangle();
    if !IsDefined(parent) {
      return widget;
    }
    widget.SetName(name);
    widget.SetAnchor(anchor);
    widget.SetAnchorPoint(anchorPoint);
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

  public static func AddPanelChrome(parent: ref<inkCompoundWidget>, label: String, span: Float) -> Void {
    CRBiologyE3Primitives.AddRect(parent, n"CRBiologyE3ChromeTop", 0.0, 0.0, span, 2.0, 0.94);
    CRBiologyE3Primitives.AddRect(parent, n"CRBiologyE3ChromeLeft", 0.0, 0.0, 2.0, 26.0, 0.86);
    CRBiologyE3Primitives.AddRect(parent, n"CRBiologyE3ChromeAccent", 7.0, 6.0, 7.0, 7.0, 1.00);
    CRBiologyE3Primitives.AddRect(parent, n"CRBiologyE3ChromeLabelBand", 18.0, 4.0, 104.0, 17.0, 0.13);
    CRBiologyE3Primitives.AddLabel(parent, n"CRBiologyE3ChromeLabel", label, 23.0, 4.0, 10, 0.82);
    CRBiologyE3Primitives.AddAnchoredRect(parent, n"CRBiologyE3ChromeBRH", inkEAnchor.BottomRight, Vector2(1.0, 1.0), -4.0, -4.0, 22.0, 2.0, 0.54);
    CRBiologyE3Primitives.AddAnchoredRect(parent, n"CRBiologyE3ChromeBRV", inkEAnchor.BottomRight, Vector2(1.0, 1.0), -4.0, -4.0, 2.0, 15.0, 0.54);
  }
}
