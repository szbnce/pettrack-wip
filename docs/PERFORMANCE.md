# Performance targets

Two numbers define "feels premium" for PetTrack, and both are structural —
the code paths below are what make them hold, not just aspirations.

| Target | Definition |
| --- | --- |
| **Cold start < 2 s** | App process start → first meaningful frame (the routing screen), on a mid-range phone in release mode. |
| **Stream latency < 1 s** | Monitor captures a frame → a viewer's screen shows it, over Wi-Fi on the LAN. |

## Cold start < 2 s

What holds the budget (all in `pettrack_app/lib/main.dart`):

- **Parallel platform init.** Camera discovery, prefs, the auth session and
  the WearOS check run in one `Future.wait`, not four serial awaits.
- **Nothing artificial in the boot path.** `BootScreen` routes the moment
  prefs say where to go — there is no fixed splash delay in front of the
  wizard or the dashboard.
- **First frame before the network.** Token refresh is kicked off in the
  background (`unawaited`); no screen waits on it to render.

Measuring it (device, release/profile build):

```sh
adb shell am start -W dev.szbnce.pettrack/.MainActivity   # TotalTime line
```

or run in profile mode and read logcat for the debug line the app prints
on its first frame:

```
cold start: first frame in 1234 ms
```

## Stream latency < 1 s

At 5 fps a frame is captured every 200 ms, so latency is won or lost in how
frames fan out (`pettrack_server/manager.py`, `main.py`):

- **Per-peer senders, not a serial fan-out.** Every socket drains on its own
  task; one full TCP buffer delays only that client, never the others
  (`tests/test_manager.py::test_a_stuck_client_never_delays_the_others`).
- **Latest-wins for frames.** A client that cannot keep up skips to the
  newest frame instead of replaying a backlog of stale ones — a backlog is
  what turns a live stream into a time machine
  (`test_a_lagging_client_skips_to_the_newest_frame`).
- **Analysis beside the stream, never in front of it.** The monitor's
  receive loop broadcasts first and only enqueues for the vision worker
  (decode, motion, zones, DB writes), which preserves frame order for the
  replay writer. Classifier inference runs in a thread so it cannot stall
  the event loop.
- **Commands are the exception.** Text messages (play sound, night mode,
  fps changes) queue in order and are never dropped
  (`test_text_commands_are_never_dropped_and_keep_order`).

Measuring it: hold a stopwatch (or a phone showing milliseconds) in front of
the monitor and watch the viewer's screen, or diff the frame timestamps in
the monitor's log against the moment they paint. On a healthy LAN link the
budget is dominated by one frame interval (200 ms) plus network and decode
time — well under a second.
