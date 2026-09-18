# Biology UI — Cyberware/Ripperdoc reference archaeology

Status: W17.1 source/resource archaeology before T005  
Issue: #107  
Parent issue: #39  
Process gate: #105  
Cyberpunk target: 2.31

## Decision summary

The native selected-category/detail **lifecycle authority** is `RipperdocInventoryController`, reached from `RipperDocGameController.m_inventoryViewAnchor`.

The native `m_virtualGridContainer` is **not** the selected-detail authority. It is the inventory controller's virtualized item-list child. Native code populates it through `ShowArea -> OnShow -> PopulateInventory`; the inventory controller root owns show/hide opacity and the top-level `RipperDocGameController.DisplayInventory` method owns transition into and out of Item depth.

Therefore W02.6's mount beside `m_virtualGridContainer` is currently proven only as a **same-local-coordinate-space mount**. It is not source-proven to be the authored generic detail/content host. T004's live `MOUNTED` breadcrumb plus invisible Biology children is consistent with that distinction.

Do not add another screenshot-derived offset and do not treat the grid's direct parent as reusable content authority until its exact current-2.31 INK role is established.

## Evidence classes

### A. Current installed CP2077 2.31 resource evidence — authoritative for layout

W02.4 / PR #93 ran the repository-owned read-only archive probe against the owner's installed 2.31 game and identified:

- resource: `base\gameplay\gui\fullscreen\ripperdoc\ripperdoc.inkwidget`
- source archive: `content\basegame_1_engine.archive`
- extracted resource SHA-256: `9E96DF6CECC0F3A0A492B0F7B6ED84C105901504B1508BE9BFA3696B977E1112`

That serialized resource proved:

- the `RipperdocInventoryController` root is a zero-margin Fill lifecycle container;
- `m_virtualGridContainer` is nested below an additional native parent;
- the virtual grid's layout values are local to that nested parent;
- `MinigridTargetAnchor` carries authored non-origin placement, so the screen is composed by child/ancestor layout rather than by the inventory-controller root itself.

Source: https://github.com/natanai/cprealpass/pull/93

The owner's retained W02.4 probe report was recovered from their File Library during W17.1. It adds a concrete handle-level chain that PR #93 did not preserve:

- `inventoryViewAnchor -> HandleRefId 141` in the library instance (package copy `632`);
- that widget is named `Inventory` and carries `RipperdocInventoryController`;
- controller refs are label prefix/suffix `208/210`, scrollbar `215`, and virtual grid `221` (package copy `727/730/737/746`);
- the actual `virtualGridContainer` widget `221` declares `parentWidget -> HandleRefId 219`; package copy `746 -> 743`;
- `Inventory` itself is attached to the larger Ripperdoc root (`parentWidget 4`; package copy `412`).

The retained report is still intentionally insufficient to classify the missing wrapper: its bounded needle windows do not include the object definitions for handles `219/743`. W17.1 therefore narrows the remaining resource-level question to the type/name/layout/clip/child-order semantics of those exact nodes rather than guessing from nearby widgets or handle numbering.

### B. Native controller behavior — authoritative for ownership/lifecycle, cross-checked against installed 2.31 symbols

The public CDPR Modding Documentation script mirror is v2.3-era rather than a 2.31 payload, so it is used only as a readable behavioral cross-check. Current Biology source has continued to compile against the owner's 2.31 game/toolchain, and the installed 2.31 INK evidence above establishes the current resource identity.

Readable mirror:
- `ripperdoc.script`: https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts/blob/fce9ab7e6a608b0d729290d898003589515900e1/scripts/cyberpunk/UI/fullscreen/ripperdoc/ripperdoc.script
- `ripperdocInventoryController.script`: https://github.com/CDPR-Modding-Documentation/Cyberpunk-Scripts/blob/fce9ab7e6a608b0d729290d898003589515900e1/scripts/cyberpunk/UI/fullscreen/ripperdoc/ripperdocInventoryController.script

The controller contract is:

```text
RipperDocGameController
  owns screen/navigation state
  owns anatomy/category minigrids and their authored target/selector anchors
  owns m_inventoryViewAnchor
    -> controller = RipperdocInventoryController
  owns m_selectorAnchor
    -> controller = RipperdocSelectorController
```

`RipperDocGameController.DisplayInventory(visible)` is the detail-depth transition authority:

- `visible = false`: sets `m_filterArea = Invalid` and calls `m_inventoryView.Hide()`;
- `visible = true`: filters items for `m_filterArea` and calls `m_inventoryView.ShowArea(..., m_filterArea)`;
- it also changes `m_isInventoryOpen` and `m_filterMode` between Default and Item.

Native category selection combines several separate responsibilities rather than one widget owning all of "detail":

```text
select category
  -> m_filterArea = selected equipment area
  -> DollHover(area)           # body/anatomy animation target
  -> DollSelect(true)          # selected body animation state
  -> DisplayInventory(true)    # selected-area inventory surface
  -> AnimateMinigrids()
  -> selected minigrid moves to m_minigridTargetAnchorMargin
  -> selector becomes the category/detail navigator
```

Native selector changes keep the screen in Item depth, repopulate the inventory surface for the new area, slide the body animation, and move the newly selected minigrid to the authored target anchor.

Native Back from Item depth performs the reverse transition:

```text
DisplayInventory(false)
m_animationController.SetOutside()
DollHover(Invalid)
ClearMinigridSelection()
ResetMinigridPositions()
AnimateMinigrids()
```

This is why Biology should continue to reuse native `m_filterArea`, `DollHover`, `DollSelect`, selector, minigrid movement, and Back. W02.2-W02.6 were correct to converge on those lifecycle seams.

Inside `RipperdocInventoryController`:

```text
Configure()
  -> m_root = GetRootWidget()
  -> root visible, root opacity starts at 0
  -> SetupVirtualGrid()

ShowArea(...)
  -> cache selected-area data
  -> OnShow()
       -> AnimateOpacity(false) on m_root
       -> update filter labels
       -> PopulateInventory() into the virtual grid

Hide()
  -> AnimateOpacity(true) on m_root
```

This makes the ownership boundary explicit:

- **inventory-controller root** = selected-detail surface lifecycle/opacity authority;
- **m_virtualGridContainer** = virtualized item-list implementation;
- **m_scrollBarContainer + m_labelPrefix + m_labelSuffix** = stock inventory-surface chrome;
- **the direct parent of m_virtualGridContainer** = a layout ancestor whose exact semantic role must come from current 2.31 INK, not inferred from the grid child.

### C. Cyberware-EX 1.5.6 — maintained reference implementation

Reference commit inspected:
`psiberx/cp2077-cyberware-ex@855d9a42eecdb635d5c9d15e6949107b9b3b1b00`

Version source:
https://github.com/psiberx/cp2077-cyberware-ex/blob/855d9a42eecdb635d5c9d15e6949107b9b3b1b00/scripts/Facade.reds

Ripperdoc override:
https://github.com/psiberx/cp2077-cyberware-ex/blob/855d9a42eecdb635d5c9d15e6949107b9b3b1b00/scripts/Overrides/UI/RipperDocGameController.reds

Mini-grid override:
https://github.com/psiberx/cp2077-cyberware-ex/blob/855d9a42eecdb635d5c9d15e6949107b9b3b1b00/scripts/Overrides/UI/CyberwareInventoryMiniGrid.reds

Cyberware-EX does not establish a second Ripperdoc body/detail screen. Its UI changes wrap/replace native `RipperDocGameController` slot/perk/hover behavior and `CyberwareInventoryMiniGrid` slot selection while leaving the stock screen, anatomy/category lifecycle, inventory controller, and item displays authoritative.

That is useful architectural evidence: a mature extension changes Cyberware semantics at native controller seams rather than cloning the screen. It does **not** prove which private INK wrapper should host an arbitrary non-item Biology panel.

## W02.2–W02.6 / T001–T004 interpretation

The attended sequence narrows the problem monotonically:

| Evidence | What it proved | What it did not prove |
| --- | --- | --- |
| T001 / W02.2 | first-open selected anatomy and runtime-backed selected-system detail can be made deterministic | correct detail composition |
| T002 / W02.3 | data is live; direct/root-relative composition resolves at extreme top-left | usable authored content host |
| installed 2.31 probe / W02.4 | controller root is not the visual coordinate authority; grid has an additional parent | direct parent is a generic detail host |
| T003 / W02.4 | selected anatomy and Back survive; fail-closed mount removed top-left telemetry | why custom children disappeared |
| T004 / W02.5 | live resolver finds the grid and reparents Biology beside it: `MOUNTED` | sibling is visible, unclipped, or semantically supported |
| W02.6 source repair | copying virtual-grid fixed sizing onto ordinary `inkVerticalPanel` was invalid; panel should size from children | that the grid's parent is the correct long-term host |

The key correction for future work is terminological and architectural:

> "direct parent of `m_virtualGridContainer`" is not synonymous with "authored selected-detail/content host."

It is currently a geometry-discovered parent. Native scripts identify `RipperdocInventoryController` as the selected-detail surface authority and `m_virtualGridContainer` as one child implementation inside that surface.

## Current hierarchy: proven vs unresolved

```text
RipperDocGameController                         [PROVEN screen/orchestration authority]
└─ root / fullscreen Ripperdoc INK             [PROVEN current 2.31 resource identity]
   ├─ anatomy/category anchors + minigrids      [PROVEN category/body presentation]
   │  └─ selected minigrid -> target anchor     [PROVEN native detail transition]
   ├─ selectorAnchor
   │  └─ RipperdocSelectorController            [PROVEN detail category navigation]
   └─ inventoryViewAnchor
      └─ RipperdocInventoryController root      [PROVEN selected-detail lifecycle/opacity]
         └─ authored nested layout subtree      [PARTIALLY RECOVERED]
            ├─ Handle 219 / 743                  [PROVEN direct grid parent; type/role unresolved]
            │  └─ m_virtualGridContainer 221/746 [PROVEN virtualized item-list child]
            ├─ m_scrollBarContainer 215/737      [PROVEN inventory chrome]
            ├─ m_labelPrefix 208/727              [PROVEN inventory chrome]
            ├─ m_labelSuffix 210/730              [PROVEN inventory chrome]
            └─ 219/743 ancestor/clip/layout role [REFERENCE PACKAGE REQUIRED]
```

The unresolved line is intentionally not filled with a guessed wrapper name.

## Assessment of W02.6

W02.6 should be preserved as diagnostic evidence, not promoted to a final layout contract.

What remains valid:
- keeping Biology under the stock inventory-controller subtree;
- retaining native `DisplayInventory` / `ShowArea` / `Hide` lifecycle;
- selected anatomy/filter identity;
- native selector and Back;
- positive `MOUNTED` and post-mount diagnostics;
- avoiding fixed screen offsets;
- allowing Biology's ordinary panel to size from its real children rather than copying virtual-grid size semantics.

What is **not** established:
- that the parent which happens to own `m_virtualGridContainer` is the reusable content host;
- that copying the grid's anchor/margin/translation is a stable 2.31 contract for arbitrary children;
- that the parent does not clip, mask, virtualize, reorder, or otherwise constrain non-grid siblings;
- that appending Biology at child index `-1` places it in the visible authored layer.

No further visual-placement implementation should be added until the current 2.31 serialized INK answers those questions.

## #105 private-reference request

W17.1 requested on #105 a targeted Biology/Cyberware UI bundle containing the current 2.31 serialized Ripperdoc INK ancestry and relevant Cyberware-EX provenance.

Request comment:
https://github.com/natanai/cprealpass/issues/105#issuecomment-5736788293

The retained W02.4 report already supplies the handle chain through `virtualGridContainer`, so the decisive derived result needed back is now narrowly:

```text
Handle 219 / package-copy 743
-> exact widget type and authored name
-> own parent(s) back to Inventory
-> sibling set and child order
-> clipping / fit-to-content / size rule / size / visibility / opacity
-> whether this node is item-grid/scroll-specific or a reusable content host
```

Private game/mod payload remains outside Git. Only this derived mapping should be committed.

## T005 gate

T005 should validate a reasoned implementation, not discover the hierarchy.

Already source/live-proven before T005:
- selected Biology anatomy identity can drive native focus;
- native selector/Back and overview/detail depth are reusable;
- runtime-backed selected-system data reaches presentation;
- the inventory controller is the native detail lifecycle authority;
- `m_virtualGridContainer` resolves live and W02.5 can mount a sibling beside it;
- virtual-grid sizing must not be copied onto an ordinary Biology panel.

Must be source-proven before T005:
- exact current-2.31 definition and ancestor chain for the proven grid parent handles `219/743`;
- which node is the authored reusable content/layout host, if any;
- relevant clip/mask/child-order constraints;
- the minimal Biology-owned mount seam derived from that host.

T005 then validates only the live/visual properties source cannot prove:
- Biology title/summary/metrics are visibly composed in the native selected-detail region;
- LEGS plus another system show authoritative runtime-backed detail;
- no top-left regression, clipping, or invisible subtree;
- overview -> detail -> Back -> another detail remains stable;
- ordinary Cyberware remains stock/usable after Biology round-trips.

If the private 2.31 resource proves there is no safe generic child host, the next implementation should adapt the native inventory surface deliberately rather than inventing coordinates. That decision belongs to the evidence, not to screenshot matching.
