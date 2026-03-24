Original prompt: make this smooth.

- Context: lockstep WebRTC fighter in `/Users/harshateja/Documents/New project/index.html`.
- Found earlier startup freeze cause: stale role closure routed remote inputs into the wrong buffer on one side.
- Current smoothing pass:
- Increased `INPUT_DELAY` from 3 to 6 frames to tolerate normal mobile/WebRTC jitter better.
- Reduced lockstep catch-up to `MAX_SIM_STEPS=1` per paint so recovered frames do not jump in visible bursts.
- Added render-side interpolation for fighter and projectile positions so 60 Hz simulation looks smoother on 90/120 Hz displays.
- Added render-side stall prediction using the next buffered input or last applied input so fighters keep moving visually while the next lockstep frame is late.
- Prefilled the first `INPUT_DELAY` frames with neutral inputs so the round starts immediately while the real jitter buffer warms up.
- Added a built-in `SIMULATED 2-DEVICE TEST` button plus `autostartSim=1` support and a hidden `#debug-output` state dump for headless testing.
- Environment note: `npx`/`node` are not installed here, so the Playwright validation loop from the web-game skill could not be run locally.
- Headless Chrome check: `?autostartSim=1` reaches `fight` and produces `{"simFrame":4,"inputFrame":4,"stalls":0,"p2":{"x":532...}}` in `#debug-output`, which confirms the simulated remote side is advancing instead of starving immediately.
- Remaining TODO: live-test two devices for movement smoothness, timer cadence, and input feel; if 6-frame delay feels too mushy, consider render-side interpolation or a slightly lower delay with a smarter jitter buffer.

- March 23 rollback pass:
- The active runtime is now the rollback-based `ActiveGame` path rather than the old lockstep/simulator path.
- Added a synchronized round start handshake (`ready` message) so both peers begin frame 0 at nearly the same wall-clock moment instead of free-running from connection-open timing.
- Added a bounded rollback prediction window (`MAX_PREDICTION_FRAMES=10`) so a peer cannot run arbitrarily far ahead and then snap back through a huge correction burst.
- Kept rollback replay from late inputs, but capped backlog accumulation during stalls to avoid visible catch-up teleports.
- Removed active PeerJS debug logging from the rollback path.
- Browser validation: local headless Chrome load against `http://127.0.0.1:8123/index.html` now completes successfully after the rollback pacing changes.
- Removed the dead legacy lockstep/debug/simulator component from `index.html`, so the file now only contains the active rollback runtime.
- Browser validation was rerun after deleting the legacy block; the page still loads successfully in headless Chrome.

- March 24 scheduler fix:
- The periodic half-second/one-second freezes were likely caused by rollback input starvation: each peer was only sending input when its simulation advanced, so when prediction hit the lead cap both sides could pause and wait on each other.
- Added a separate `inputFrameR` wall-clock scheduler so inputs are sampled, buffered, and sent every 60 Hz tick even if simulation is temporarily behind.
- Simulation now consumes buffered local inputs from `localInputsR` and advances toward `inputFrameR` instead of coupling send cadence to `simFrameR`.
- Browser validation was rerun after the scheduler change; the page still loads successfully in headless Chrome.

- March 24 transport pass:
- Switched the active input transport away from per-frame object messages to compact binary packets with redundant recent-frame history (`INPUT_PACKET_HISTORY=6`).
- Removed `reliable:true` from the PeerJS join path and explicitly use binary serialization for the input connection.
- Added periodic pre-start ready resends so an unreliable control packet drop cannot deadlock the round start.
- Forced the open data channel to use `arraybuffer` delivery when available to avoid Blob/object overhead on hot input paths.
- Browser validation was rerun after the transport change; the page still loads successfully in headless Chrome.

- March 24 message-path fallback:
- The raw-buffer input path was too brittle with PeerJS delivery behavior, so the active transport now uses compact object messages again for startup/control and redundant frame-history input bundles for gameplay.
- Prediction cap was widened to reduce hard stalls while late frames are still being corrected by rollback.
- Browser validation was rerun after the message-path change; the page still loads successfully in headless Chrome.

- March 24 Playwright validation:
- After enabling Node/Playwright in a fresh login shell, ran two isolated browser sessions (`ml-a`, `ml-b`) against the local server and completed the actual create-room / join-room WebRTC flow.
- Verified both sessions transition from splash -> lobby -> waiting/fight without runtime console errors other than Babel warning + missing favicon.
- Captured fight-screen screenshots for both peers showing active round timer progression.
- Held `d` on the host session for ~1.2s and confirmed Gandhi moved significantly to the right on the host screenshot; captured the joiner screenshot afterward and confirmed the remote view also reflected Gandhi's moved position.
- Held `ArrowLeft` on the joiner session and captured follow-up screenshots showing both fighters still synchronized on both peers.
- Remaining TODO: keep iterating on subjective smoothness/lag feel, but the current rollback + P2P + WebRTC path is now functionally moving and syncing in real browser automation.

- March 24 rollback architecture pass:
- Switched the hot input path back to compact binary packets with redundant recent frame history, while keeping object-message fallback only as a compatibility path.
- Added `LOCAL_INPUT_DELAY=2` and a `confirmedRemoteFrame` gate so the sim behaves more like a proper GGPO-style predicted tail: it can run ahead briefly, but it no longer free-runs 30 frames into heavy correction territory.
- Replaced the Map-heavy frame history with fixed ring buffers for local inputs, remote inputs, used remote inputs, and saved game-state snapshots.
- Rollback now reuses a scratch game-state object on rewinds instead of cloning a brand new full state every time a late remote input arrives.
- Added `window.render_game_to_text` and `window.advanceTime` hooks plus a `#start-btn` id so the web-game Playwright client can read state and drive the page more reliably.
- Tried `serialization:"none"` on the PeerJS join path for raw packets, but PeerJS `1.5.4` on this CDN build threw `this._serializers[t.serialization] is not a constructor`; removed that option and kept the binary packet format with plain `reliable:false`.
- Manual browser retest is intentionally paused here per user request: finish code changes first, then let the user do the next full multiplayer playtest.
