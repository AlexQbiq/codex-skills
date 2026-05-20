# Studio Editor Memory

Use this file as the durable starting context for Studio Editor work in this repo.

Treat this note as a codebase-orientation guide first and a historical bug note second.

## Fast Start

- Read `Investigation Workflow`, `Editor Architecture`, and `Symptom -> First Files` before diving into old Jira context.
- Bring a task-specific `Context delta`: `design_result_id`, before/after snapshots, exact repro steps, expected behavior, scope, and validation target.
- Prefer the smallest safe fix.
- Avoid broad shared-geometry rewrites unless a narrow fix is clearly invalid.

## Investigation Workflow

1. Classify the bug first:
   - mode / selection / click-outside / `Esc`
   - handle / hover / drag-start / pointer lifecycle
   - ghost geometry during drag
   - selected-room or circulation persistence on pointer-up
   - neighbor / door / furniture propagation
   - save / reload / render timing
2. Decide whether the bug is in ephemeral UI state or persistent design state:
   - ephemeral UI state lives in `apps/studio/src/stores/studio.ts`
   - persistent design state lives in `apps/studio/src/stores/design/design.ts`
3. Compare ghost geometry against final persisted geometry:
   - ghost wrong while dragging -> inspect ghost renderer, `useStretchTool.ts`, behavior, and math helpers
   - ghost right, saved geometry wrong -> inspect `handlePointerUp` in `useStretchTool.ts` and `useRoomsUpdater.ts`
   - geometry right, selection wrong -> inspect selection tools, mouse mode, and shared container listeners
4. Check whether the failure happens before or after neighbor recomputation:
   - selected shape wrong -> behavior / `polygonStretchCore.ts`
   - neighbors wrong -> `useRoomsUpdater.ts` + `neighborGeometryOps.ts`
   - doors or furniture wrong -> `getUpdatedDoors` / `getUpdatedFurniture`
5. If the bug changes only after save, reload, or deploy, inspect `design.helpers.ts`, sync, and server-facing state preparation.

## Editor Architecture

### Runtime Layers

- UI shell: `apps/studio/src/pages/studio/StudioPage.vue` -> `apps/studio/src/components/canvas/StudioEditor.vue`
- Pixi app + viewport + shared containers: `apps/studio/src/components/canvas/ApplicationRenderer.vue`
- Ephemeral editor state: `apps/studio/src/stores/studio.ts`
- Persistent design model + sync: `apps/studio/src/stores/design/design.ts`
- Selection and mouse mode tools: `apps/studio/src/composables/canvas/useMouseModeController.ts`, `apps/studio/src/tools/useBaseSelectTool.ts`, `apps/studio/src/tools/useRoomSelectTool.ts`, `apps/studio/src/tools/useCirculationSelectTool.ts`
- Stretch runtime: `apps/studio/src/components/canvas/Room/GhostRoomRenderer.vue`, `apps/studio/src/components/canvas/Circulation/GhostCirculationRenderer.vue`, `apps/studio/src/tools/useStretchTool.ts`
- Behavior strategies: `apps/studio/src/tools/behaviors/RoomStretchBehavior.ts`, `apps/studio/src/tools/behaviors/CirculationStretchBehavior.ts`
- Neighbor/update bridge: `apps/studio/src/composables/canvas/useRoomsUpdater.ts`, `apps/studio/src/composables/canvas/useRoomsUpdater.utils.ts`
- Lookup/snap caches: `apps/studio/src/composables/canvas/useRoomSearch.ts`, `apps/studio/src/composables/canvas/useSnap.ts`
- Geometry engine: `apps/studio/src/math/polygonStretchCore.ts`, `apps/studio/src/math/chainMovement.ts`, `apps/studio/src/math/neighborGeometryOps.ts`, `apps/studio/src/math/polygonPreprocessing.ts`, `apps/studio/src/math/edgeSupportHelpers.ts`, `apps/studio/src/math/searchNeighborsHelpers.ts`, `apps/studio/src/math/circulationRoundingHelpers.ts`
- Geometry helpers / JSTS boundary: `apps/studio/src/helpers/geom.ts`, `apps/studio/src/helpers/jsts.ts`
- Durable mutations: `apps/studio/src/stores/design/design.mutations.ts`, `apps/studio/src/stores/design/design.helpers.ts`

### State Ownership

- `studioStore` owns ephemeral UI state:
  - current mouse mode
  - selected room / circulation / furniture / door
  - viewport and app refs
  - snap toggles
  - drag / stretch flags
- `designStore` owns persistent design state:
  - `designState.rooms`
  - `designState.circulation`
  - program rows / furniture DB / customization / NFP / flood / columns
  - debounced sync + deploy + history
- Editing bugs often live at the boundary between these two stores, not in one store alone.

### Container Model

- `ApplicationRenderer.vue` creates one Pixi app and one viewport.
- It mounts `backgroundContainer`, `workingContainer`, and `foregroundContainer` under a shared `mainContainer`.
- `mainContainer.scale.y = -1`, so Studio geometry lives in an inverted Y-axis design coordinate system.
- Room graphics render under `workingContainer`.
- Circulation graphics render under `backgroundContainer`.
- Ghost handles and stretch interaction use the shared `mainContainer`, not the room-only container.

### Selection Model

- Room selection is keyed by `selectedRoomCounter`.
- Circulation selection is a separate boolean: `isCirculationSelected`.
- Mouse mode is separate again: `selectedMouseMode`.
- A bug can therefore come from:
  - wrong mode
  - correct mode but wrong selected entity
  - correct selection but stale container interactivity

## Stretch Data Flow

1. Toolbar or click selection sets mouse mode and selection flags.
2. Selected room mounts `GhostRoomRenderer`; selected circulation mounts `GhostCirculationRenderer`.
3. Ghost renderer computes a base polygon and owns a local `roomUpdates` ref.
4. `useStretchTool.ts` attaches pointer listeners to the shared container, tracks near edge, movement, moved segment, and `ghostGeometry`.
5. `useStretchTool.ts` chooses a behavior:
   - `RoomStretchBehavior` for rooms
   - `CirculationStretchBehavior` for circulation
6. Behavior delegates movement math to:
   - `polygonStretchCore.ts`
   - `chainMovement.ts`
   - snapping / rounding / support-edge helpers
7. On pointer-up, `useStretchTool.ts` finalizes geometry and writes a `SelectedRoomUpdate` into `roomUpdates`.
8. `useRoomsUpdater.ts` watches `roomUpdates`, mutates selected room or circulation, recomputes neighbors, updates doors and furniture, and creates or deletes empty rooms if needed.
9. `designStore` mutates `designState`, recalculates program rows, and its deep watcher triggers debounced API sync.

## Main Players

- `apps/studio/src/components/canvas/ApplicationRenderer.vue`
  - Pixi bootstrap, shared containers, viewport drag/zoom, first-postrender canvas reveal.
- `apps/studio/src/stores/studio.ts`
  - Source of truth for selection, mouse mode, snap settings, viewport refs, and stretch/drag flags.
- `apps/studio/src/stores/design/design.ts`
  - Source of truth for rooms, circulation, customization, NFP/flood/columns, history, sync, and deploy.
- `apps/studio/src/tools/useStretchTool.ts`
  - Central pointer-drag controller. If a bug mentions handles, hover, drag start, pointer-up, or ghost geometry, start here.
- `apps/studio/src/tools/behaviors/RoomStretchBehavior.ts`
  - Room-specific stretching, neighbor candidate collection, circulation subtraction on finalize.
- `apps/studio/src/tools/behaviors/CirculationStretchBehavior.ts`
  - Circulation-specific multi-face reconstruction, rounding, hole handling, cleanup, and collapsed-shell artifact removal.
- `apps/studio/src/composables/canvas/useRoomsUpdater.ts`
  - Bridge from ghost geometry to durable room/circulation updates. Owns neighbor propagation, door/furniture recalculation, and empty-space creation.
- `apps/studio/src/composables/canvas/useRoomSearch.ts`
  - Singleton interval-tree cache over room bounding boxes. Broad candidate search only; precise filtering happens later.
- `apps/studio/src/composables/canvas/useSnap.ts`
  - Snap data PlanarSets for walls, columns, and mullions plus room snapping via `useRoomSearch`.
- `apps/studio/src/math/polygonStretchCore.ts`
  - Core moved-edge math for rooms and circulation. High-value file for topology or movement-shape bugs.
- `apps/studio/src/math/neighborGeometryOps.ts`
  - Neighbor shrink/extend/subtract/unify helpers. High-value file for "selected geometry looks right, neighbors wrong".
- `apps/studio/src/stores/design/design.mutations.ts`
  - Final room/circulation mutations, program-row recalculation, and furniture mutations.
- `apps/studio/src/helpers/jsts.ts`
  - FlattenJS <-> JSTS bridge for `buffer`, `parallelOffset`, and `simplify`. JSTS failures usually mean invalid upstream topology, not just a bad simplifier call.

## Symptom -> First Files

| Symptom | Start Here | Then Check |
| --- | --- | --- |
| Cannot select, clear, or exit mode | `EditorToolbar.vue`, `useMouseModeController.ts`, `useBaseSelectTool.ts` | `useRoomSelectTool.ts`, `useCirculationSelectTool.ts`, `stores/studio.ts` |
| Handles visible but not draggable | `useStretchTool.ts`, `HandlesRenderer.vue` | ghost renderer mount/unmount, shared container lifecycle in `ApplicationRenderer.vue` |
| Ghost shape wrong while dragging | `useStretchTool.ts`, relevant behavior | `polygonStretchCore.ts`, `chainMovement.ts`, `circulationRoundingHelpers.ts`, `searchNeighborsHelpers.ts` |
| Ghost shape right but saved geometry wrong | `handlePointerUp` in `useStretchTool.ts` | `useRoomsUpdater.ts`, `design.ts`, `design.mutations.ts` |
| Selected room updates but neighbors do not | `useRoomsUpdater.ts` | `neighborGeometryOps.ts`, `edgeSupportHelpers.ts`, `searchNeighborsHelpers.ts`, `useRoomSearch.ts` |
| Geometry right but doors or furniture wrong | `useRoomsUpdater.ts:getUpdatedDoors/getUpdatedFurniture` | `math/moveDoorHelpers.ts`, `helpers/furniture.ts`, `design.mutations.ts` |
| Bug only happens for circulation | `CirculationStretchBehavior.ts`, `GhostCirculationRenderer.vue` | `polygonStretchCore.ts:applyMovementCirculation`, `circulationRoundingHelpers.ts`, `useRoomsUpdater.utils.ts` |
| Bug only happens after save or reload | `stores/design/design.ts` | `design.helpers.ts`, `sync.composable.ts`, server-facing state assumptions |
| Bug depends on zoom or hit testing | `useStretchTool.ts`, `HandlesRenderer.vue`, `useViewportController.ts` | `stores/studio.ts.currentScale`, Pixi container hierarchy |
| Black flash, reveal timing, or locked preview | `ApplicationRenderer.vue`, `StudioEditor.vue` | `studio-lock.ts` |

## Fragile Seams / Weak Patterns

- Shared `mainContainer` pointer lifecycle:
  - room and circulation ghost renderers share the same container for handles and stretch interaction
  - listener teardown in one path can break the other if interactivity is reset too aggressively
- Selection tool listener reset:
  - `useBaseSelectTool.ts:configureSpaceContainers()` calls `removeAllListeners()` on room/background containers
  - mode-switch bugs can come from this broad reset, not just from the active tool
- Separate selection sources:
  - room selection, circulation selection, and mouse mode are stored separately and can drift
- Circulation uses a sentinel counter:
  - `CIRCULATION_COUNTER_ID = -1`
  - circulation reuses room update machinery through this sentinel, so branch conditions around `isCirculationUpdated` matter a lot
- Hidden modifier paths:
  - `Space` pans the viewport
  - `Alt` on pointer-up changes split / empty-space behavior
  - `Tab` toggles `splitEdgesMode` for room ghost flow
  - `Escape` is centralized in `useBaseSelectTool.ts`
- Scale-dependent behavior:
  - hit-test thresholds and handle sizes depend on `currentScale`
  - zoom-dependent bugs are often hit-testing issues, not topology issues
- Bounding-box room search:
  - `useRoomSearch.ts` returns broad candidates from an interval tree
  - exact neighbor relevance must be enforced later
- Heavy topology conversions:
  - the stretch/update pipeline repeatedly uses `parseWKT` / `toWkt`, FlattenJS booleans, and JSTS simplify/buffer calls
  - cleanup tolerances can change topology, not just prettify geometry
- JSTS failure masking:
  - `helpers/jsts.ts` often logs and returns original geometry or `null`
  - the visible failure may be downstream, while the real cause is earlier invalid geometry generation
- Sync and lock side effects:
  - `designStore.designState` is deeply watched for debounced sync
  - lock refresh and sync are not the main bug source most of the time, but they can hide whether a bug is UI-only or truly persisted

## Known Root Causes

- Shared stretch-container teardown in `useStretchTool.ts` can disable active handles if another stretch instance still depends on the same container. (`QBIQ-10014`)
- Neighbor candidate search from `useRoomSearch.ts` is intentionally broad; `useRoomsUpdater.ts` must perform a second-stage edge-based filter for circulation and geometry-based filter for rooms. Weakening that filter over-updates unrelated rooms. (`QBIQ-9894`)
- `useRoomsUpdater.ts` must treat circulation inner movement differently from room inner movement when deciding whether to create `EmptySpace`. (`QBIQ-9899`)
- `useRoomSearch.ts` cache invalidation matters because the engine is singleton and lookup-driven flows depend on fresh room geometry and counters. (`QBIQ-9895`)
- Circulation cleanup often needs both `simplify(...)` and `cleanCollinear(..., NON_ZERO_ANGULAR_DIFFERENCE)`; default collinear cleanup can over-collapse valid nearly-straight boundaries or preserve broken tiny steps. (`QBIQ-10036`, `QBIQ-10094`)
- Room stretching should avoid `simplify(...)` and `cleanCollinear(...)` during drag-time ghost updates because those cleanups can auto-straighten edges and merge adjacent room boundaries; keep them in finalize/pointer-up only. (`QBIQ-10044`)
- Circulation stretch can turn one edited face into multiple real islands when the moved edge crosses a rest edge. The stretch core should split both the moved/replacement chain and the rest chain at the crossing, and the circulation behavior must splice all returned faces back into the face list before regrouping. Whole-polygon validity can reject this self-touching split even when each resulting face is meaningful, so guard against tiny slivers rather than dropping the split. (`QBIQ-10272`)
- Room wall reference-line snapping should mirror circulation by applying the extra snap inside `applyMovementRoom -> getMainMovement`, after the regular room snap. Only draw and snap room reference lines for direct collinear continuations of the moving edge, under `Rooms` snap mode, and only when the guide segment crosses circulation/corridor geometry. Candidate reference rooms should come from `useRoomSearch` along the moving-edge line instead of a behavior-owned all-room polygon cache. (`QBIQ-10302`)
- `Escape` and click-outside behavior are centralized in `useBaseSelectTool.ts`; mode-exit bugs are often not in room-specific or circulation-specific tools. (`QBIQ-10133`)
- Canvas reveal timing belongs in the first-postrender path in `ApplicationRenderer.vue`, not in a generic timeout. (`QBIQ-10009`)

## Known Suspects / Architectural Constraints

- `QBIQ-9995`: chain or newly exposed neighbors are likely lost after the first deletion changes adjacency; inspect `neighborRoomsIds`, `affectedNeighbors`, and `extendNeighborGeometry(...)`.
- `QBIQ-10013`: sharp circulation ghost angles likely appear before final cleanup, probably in `polygonStretchCore.ts` or circulation face reconstruction, not in the renderer.
- Room stretching is fundamentally edge-centric today. Vertex drag is not a drop-in extension of the same pipeline.
- `roomActionsState.isStretchingRoom` is used for both room and circulation stretch UI despite the room-specific name.
- If JSTS throws `FlattenJs Polygon must have at least 3 edges`, treat it as an upstream topology bug first.

## Context Delta Checklist

Include these in a fresh thread whenever possible:

- `design_result_id`
- before / after snapshot ids
- affected room counter or circulation
- exact drag direction and whether `Alt`, `Tab`, `Space`, or `Esc` matter
- whether the bug appears:
  - during ghost drag
  - only on pointer-up
  - only after reload or deploy
- expected invariant:
  - which room should move
  - which neighbors must remain unchanged
  - whether doors, furniture, or empty space should be preserved

## Resolved Issues Log

- 2026-03-18: `QBIQ-9894` tightened circulation neighbor updates so unrelated rooms and doors no longer move just because they were bbox-nearby.
- 2026-03-19: `QBIQ-9895` rebuilt room-search state after in-place room changes so lookup-driven flows stop using stale geometry.
- 2026-03-22: `QBIQ-9899` added the correct empty-space fallback for circulation inner shrink with no updated neighbors.
- 2026-04-05: `QBIQ-10014` preserved shared stretch-container interactivity across tool switches so circulation handles stay responsive.
- 2026-04-06: `QBIQ-10036` preserved valid collinear circulation-adjacent neighbors by using non-zero angular cleanup tolerance.
- 2026-04-09: `QBIQ-10043` clamped circulation collapse at the zero-width boundary instead of allowing a far-side ghost.
- 2026-04-14: `QBIQ-10094` extended saved circulation cleanup with `simplify(...)` and `cleanCollinear(...)` to remove broken tiny steps.
- 2026-04-17: `QBIQ-10133` made `Escape` exit `Select Circulation` back to `Select Room`.
- 2026-04-17: `No Jira` made circulation click clear room selection consistently with other space types.
- 2026-04-17: `QBIQ-10009` gated canvas reveal on a real render-ready signal and removed the startup black blink.
- 2026-04-29: `QBIQ-10044` aligned room stretch with circulation behavior by deferring `simplify(...)` + `cleanCollinear(...)` to pointer-up finalization so drag-time room edges do not auto-straighten or merge.
- 2026-05-04: `QBIQ-10272` preserved circulation islands when a moved stretch edge crosses a rest edge by reconstructing both split faces and splicing multi-face stretch results back into circulation processing.
- 2026-05-04: `QBIQ-10266` cleaned tiny spike artifacts before room rendering and selected-room ghost setup so small adjacent-room remnants are hidden without broadening the persistent geometry mutation path.
- 2026-05-05: `QBIQ-10302` added room-wall red alignment guides and matching snap behavior for non-connected room walls, scoped to `Rooms` snap mode and limited to direct edge continuations crossing circulation.

## Starter Prompt For New Threads

```md
Use $studio-editor-memory-workflow for this Studio Editor task.

Task: <ticket or goal>
Context delta: <design id / snapshot ids / repro path / what is new vs the shared memory>
Expected result: <what should change>
Scope: <minimal local fix only / helper refactor allowed / broader change acceptable>
Validation: <unit only / studio suite / live verification / prepare PR>
Branch notes: <optional>
```

## Maintenance Rules

- Prefer codebase lessons over ticket diaries.
- Add historical Jira details only when they reinforce a reusable code lesson.
- Promote a finding to `Known Root Causes` only after code-level validation or a stable repro-backed test.
- Put speculative but reusable insights under `Known Suspects / Architectural Constraints`.
- Add full repro assets only when they materially shorten future debugging.
