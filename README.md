
<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![Unlicense License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/szbnce/PetTrack">
    <img src="pictures/banner.png" alt="Logo" height="240">
  </a>

  <h3 align="center">PetTrack</h3>

  <p align="center">
    Your old phone is your new pet monitor!
    <br />
    <a href="https://github.com/othneildrew/Best-README-Template"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://pettrackdemo.szabence.com">Try PetTrack</a>
    &middot;
    <a href="https://github.com/szbnce/PetTrack/releases/latest">Download the app</a>
    &middot;
    <a href="https://github.com/szbnce/PetTrack/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/othneildrew/Best-README-Template/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
        <li><a href="#security-basics">Security basics</a></li>
        <li><a href="#vision-pipeline">Vision pipeline</a></li>
        <li><a href="#development--testing">Development &amp; testing</a></li>
      </ul>
    </li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#privacy-policy">Privacy Policy</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

In may of 2026, my brother got a rabbit as a gift for her goddaughter, but her mother wasn't very pleased and threw a tantrum, so he had to took the rabbit, and I took her in, her name is Berci, a lionhead dwarf rabbit, she is around 7-8 months old as I am writing this README.

<div align="center">
  <img src="pictures/BerciBed.jpeg" alt="BerciBed" height="240">
  <img src="pictures/BerciPortrait.png" alt="BerciPortrait" height="240">
  <img src="pictures/BerciBody.jpg" alt="BerciBody" height="240">
</div>

She is a very active and curious rabbit, and always finding loopholes around stuff, so when I was in school and working, I had no idea what she was up to, so I started searching for pet cameras, but they are expensive, sometimes even a paid subscription model, and I had lot's of phones laying around, with perfectly good cameras, WiFi, so I thought, why couldn't I make an IP-cam from those, and use that? I tried it, it worked, but it was not great. I mean, who would want to look at their beloved pets though an ugly, and not very user friendly application that was sometimes buggy, unstable? This is how PetTrack was born:

<div align="center">
  <img src="pictures/AndroidDashboard.jpg" alt="AndroidDashboard" height="480">
  <img src="pictures/AndroidZones.jpg" alt="AndroidZones" height="480">
  <img src="pictures/AndroidMedical.jpg" alt="AndroidMedical" height="480">
  <img src="pictures/AndroidReplay.jpg" alt="AndroidReplay" height="480">
  <img src="pictures/AndroidSettings.jpg" alt="AndroidSettings" height="480">
</div>

PetTrack is a lightweight Pet monitor that upcycles old phones, and uses them as Pet Monitors that you can put near their cage, and check up on them when you are not home, and more. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Features

* Live video Stream
* Take picture and send instantly
* Set name, pet type, profile picture
* Zone setting and pet tracking
* Movement recordings that are replayable instantly and shareable
* Activity log
* Vaccine and Medication tracking
* Alerts anywhere via [ntfy](https://ntfy.sh) (outside the LAN)
* Android / iOS / Web / WearOS Support

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Flutter][Flutter.dev]][Flutter-url]
* [![Dart][Dart.dev]][Dart-url]
* [![FastAPI][FastAPI.tiangolo]][FastAPI-url]
* [![Python][Python.org]][Python-url]
* [![OpenCV][OpenCV.org]][OpenCV-url]
* [![SQLite][SQLite.org]][SQLite-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

* An old phone (Android 7+ / iPhone 6s+)
* A PC/Server for the backend — pick **either** install method below:
  * anything that can run Docker, **or**
  * any machine with Python 3.10+ (Linux, Windows, macOS)
* [A DDNS service](https://www.noip.com) (optional, only for access from outside your LAN)

### Installation

Both options get you to the same place: a PetTrack server with the web dashboard at
`http://<server_ip>:8000`. Pick whichever you are more comfortable with.

#### Option A — Docker

1. Clone the repo
   ```sh
   git clone https://github.com/szbnce/PetTrack.git
   cd PetTrack
   ```
2. Build and start the container
   ```sh
   # Once: create the host paths Docker is about to mount. Docker creates a
   # *missing* bind-mount source as a directory, which is how pettrack.db
   # and .env end up as folders on the first run. Touching them first avoids it.
   mkdir -p pettrack_server/replays pettrack_server/captured_images pettrack_server/updates
   touch pettrack_server/pettrack.db pettrack_server/.env

   docker compose up -d --build pettrack
   ```
   The entrypoint also checks each mount and, if one is the wrong kind, says
   exactly which folder to move aside — it never deletes anything. If `.env`
   is already a directory (the Docker default), settings simply live in
   `.env/pettrack.env` on that same mount instead.
3. Read the startup logs and note the **4-digit PIN** (and the QR code for pairing phones)
   ```sh
   docker logs pettrack
   ```
4. Your server is now reachable at `http://<server_ip>:8000` (server API + web dashboard).

Your data (replays, snapshots, database, secrets) lives in `./pettrack_server/`, so it
survives container rebuilds.

#### Option B — Native (Linux, Windows, macOS)

> **The short way (Linux):** one command does the whole server setup —
> system packages, Python environment, dependencies, optionally a systemd
> service and HTTPS:
>
> ```sh
> curl -fsSL https://raw.githubusercontent.com/szbnce/PetTrack/main/setup_server.sh | bash
> ```
>
> or, from a cloned repo, with the extras:
>
> ```sh
> ./setup_server.sh --systemd --https pettrack.home.arpa
> ```

1. Clone the repo
   ```sh
   git clone https://github.com/szbnce/PetTrack.git
   cd PetTrack
   ```
2. Install system packages (Python 3 and Node.js)
   ```sh
   ./install_linux.sh        # or ./install_macos.sh, or install_windows.bat
   ```
3. Start the server
   ```sh
   ./run_linux_and_macos.sh  # or run_windows.bat
   ```
   The first run creates a virtualenv, installs the Python dependencies, and builds
   the web dashboard into `pettrack_server/static`.
4. Read the terminal output and note the **4-digit PIN** (and the QR code for pairing phones).

Your server is now reachable at `http://<server_ip>:8000` (server API + web dashboard).

> Building the phone apps yourself? Install the [Flutter SDK](https://docs.flutter.dev/get-started/install)
> as well — the web dashboard build in step 3 needs it.

#### HTTPS on the LAN (optional but recommended)

Plain HTTP means anyone on the same Wi-Fi can watch the camera stream. The
setup script can put [Caddy](https://caddyserver.com) in front of the server
with automatic TLS:

```sh
./setup_server.sh --https pettrack.home.arpa
```

* Real domains get Let's Encrypt certificates automatically.
* LAN-only names (`*.home.arpa`, `*.local`, `*.lan`, `*.internal`) get a
  private Caddy CA certificate instead — run `sudo caddy trust` on the server
  and install the root CA on each phone once.

Then connect the app with `https://pettrack.home.arpa` — it switches the live
stream to `wss://` automatically.

Already have a TLS certificate (from a reverse proxy, Let's Encrypt, or a
private CA)? The server can terminate HTTPS itself — no Caddy needed. Point
the two environment variables at your PEM files before starting it:

```sh
PETTRACK_TLS_CERT=/path/to/fullchain.pem PETTRACK_TLS_KEY=/path/to/privkey.pem ./run_linux_and_macos.sh
```

#### First steps (both options)

On phones, you can either use the web interface (add a home-screen shortcut) or sideload the native app.

Android:

1. Download the APK from the [Releases page](https://github.com/szbnce/PetTrack/releases) on Github.
2. Enable "Install from unknown sources" in your Android settings.
3. Install the APK.
4. Open the app, select your language, select if you want to use it as a Monitor or Client, then enter the IP and Port (On the Monitor phone, you should use the local IP, not the external IP, on the Client you should use the external IP, if DDNS is set up, or Tailscale.)

iOS:

1. Download the .iPA file from the [Releases page](https://github.com/szbnce/PetTrack/releases) on Github.
2. Use a tool like [Sideloadly](https://sideloadly.io/) to install the .iPA file to your iOS device.
    - Note that you will have to allow the developer account in the device management settings, and you will have to re-authorize the app every 7 days.
3. Open the app, select your language, select if you want to use it as a Monitor or Client, then enter the IP and Port (On the Monitor phone, you should use the local IP, not the external IP, on the Client you should use the external IP, if DDNS is set up, or Tailscale.)

Web:

1. Open `http://<server_ip>:8000` on your own server (or the [demo](https://pettrackdemo.szabence.com)).
2. Select your language, select if you want to use it as a Monitor or Client, then enter the IP and Port (On the Monitor phone, you should use the local IP, not the external IP, on the Client you should use the external IP, if DDNS is set up, or Tailscale.)

WearOS:

1. Download the .APK
2. Turn on Wi-Fi
3. Turn on Developer settings
4. Turn on ADB debugging
5. Connect the watch to your PC and authorize the ADB connection
6. Open a terminal and run: `adb install <path_to_apk>`
7. Open the app on the watch and paired phone
8. In settings, scroll to the bottom, there is a Sync watch button, press it, and it will now work on the watch!

### Security basics

PetTrack is built for your own homelab — a bit of care keeps it that way.
The full security model (sessions, token scopes, transport, threat notes)
lives in [SECURITY.md](SECURITY.md).

* The **4-digit PIN** and the **secret token** in `pettrack_server/.env` unlock your
  camera feed. Treat them like passwords; don't commit or share that file.
* The PIN login is rate-limited (5 attempts), and PIN logins only receive a scoped,
  time-limited token — never the master secret itself.
* By default the server is meant for a **trusted LAN**. If you want access from outside,
  use a VPN (e.g. [Tailscale](https://tailscale.com/)) or put a reverse proxy with HTTPS
  (e.g. Caddy) in front of port 8000 — don't just port-forward plain HTTP to the internet.
* Cross-origin browser access is disabled by default. If you host the web dashboard on a
  different origin, whitelist it with `PETTRACK_CORS_ORIGINS` in `.env`.

### Vision pipeline

Motion detection is built in cheap tiers so old / low-power homelab hardware
mostly stays idle when nothing is happening:

1. **Thumbnail diff (every frame):** a ~160px grayscale thumbnail is diffed
   against the previous one — Pillow + numpy only, no OpenCV work.
2. **Localize + zones (only when something moves):** the moving blob's center
   is tested against your zones. Whole-frame brightness shifts (lights turning
   on) are rejected as "not a pet".
3. **Full frames only while recording:** the expensive full-resolution decode
   happens just for replay clips.

Tune it via environment / `.env`:

| Variable | Default | Meaning |
|---|---|---|
| `PETTRACK_VISION_MODE` | `motion` | `motion` or `off` (disable detection) |
| `PETTRACK_MOTION_THRESHOLD` | `25` | Per-pixel brightness delta that counts as change |
| `PETTRACK_MOTION_MIN_PIXELS` | `12` | Ignore specks / compression noise |
| `PETTRACK_MOTION_MAX_COVERAGE` | `0.45` | Above this = lighting change, not motion |
| `PETTRACK_MOTION_WIDTH` | `160` | Thumbnail width in pixels |
| `PETTRACK_MOTION_TIMEOUT` | `5` | Seconds without motion before the tracked position is dropped |
| `PETTRACK_DARK_BRIGHTNESS` | `25` | Below this mean brightness, detection pauses |

#### Optional tier 3: pet / not-pet filter

For even less noise (people walking past, curtains, shadows), PetTrack can run a
small ONNX image classifier on every moving blob and only raise zone events for
actual pets. It is **off by default** — the ~14 MB model is not bundled with the
repo:

```sh
pip install -r pettrack_server/requirements-classifier.txt   # onnxruntime
python3 tools/fetch_classifier_model.py                      # model + labels
```

The server picks it up on the next start. With a rabbit in the house it happily
recognizes photos of her as `Angora, Angora rabbit` / `wood rabbit`, and drops
everything else.

| Variable | Default | Meaning |
|---|---|---|
| `PETTRACK_CLASSIFIER` | `auto` | `auto` (use model if present) or `off` |
| `PETTRACK_CLASSIFIER_MODEL` | `models/classifier.onnx` | Path to an ImageNet-style ONNX classifier |
| `PETTRACK_CLASSIFIER_LABELS` | `models/imagenet_classes.txt` | Label list (one per line, `synset.txt` format) |
| `PETTRACK_CLASSIFIER_MIN_CONF` | `0.2` | Minimum confidence for a "pet" verdict |

Works with any ImageNet-compatible ONNX classifier — bring your own model if
you want.

### Home Assistant

Point PetTrack at an MQTT broker and its sensors show up in Home Assistant
automatically — no yaml, no manual entity setup:

```env
PETTRACK_MQTT_HOST=192.168.1.10
PETTRACK_MQTT_USER=homeassistant
PETTRACK_MQTT_PASSWORD=...
```

Everything is announced as a single **PetTrack** device: Motion, Monitor
online, Monitor battery, Monitor charging, Last event, and a Camera snapshot
entity. Without `PETTRACK_MQTT_HOST` the bridge stays completely off.

| Variable | Default | Meaning |
|---|---|---|
| `PETTRACK_MQTT_HOST` | *(unset)* | MQTT broker host — unset disables the bridge |
| `PETTRACK_MQTT_PORT` | `1883` | Broker port |
| `PETTRACK_MQTT_USER` / `PETTRACK_MQTT_PASSWORD` | *(empty)* | Broker credentials |
| `PETTRACK_MQTT_DISCOVERY_PREFIX` | `homeassistant` | Home Assistant discovery prefix |
| `PETTRACK_MQTT_BASE` | `pettrack` | State topic prefix |
| `PETTRACK_MQTT_CAMERA_INTERVAL` | `30` | Seconds between camera snapshots (`0` = no camera entity) |

### Alerts outside the LAN (ntfy)

The in-app notifications only reach a phone on the same network. To hear
about a barking dog or a zone crossing at work, forward the events to an
[ntfy](https://ntfy.sh) topic and subscribe to it from the ntfy app, a
browser, or a self-hosted ntfy — the server never needs to be exposed.

1. Pick a topic name that is hard to guess (anything with the link can
   subscribe), e.g. `https://ntfy.sh/berci-7f3k9x`
2. In the app: **Settings → Alerts → "Alerts when I'm away"** — paste the
   topic URL (and an access token if the topic is protected), save
3. Tap **Send test notification** — if your phone rings, you are done

Zone crossings, sound events and watchdog warnings (camera offline, low
disk) are pushed in the app's language and with the pet's name; quiet
hours are honoured the same way local alerts honour them. Everything is
opt-in: without a topic URL nothing is ever sent.

### One-tap app updates

Your server ships updates to the phones already running PetTrack. Drop the
new build next to the server's data:

```bash
mkdir -p updates
cp PetTrack.apk updates/PetTrack.apk
echo '{"version": "2.1.0"}' > updates/update.json
```

Then on the phone: **Settings → About & updates → Check now**. If the
server has something newer, "Install update" appears — one tap downloads
the APK and opens Android's installer (which still asks you to confirm).
Nothing leaves your LAN; details and the security notes are in
[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) and
[SECURITY.md](SECURITY.md).

### Development & testing

* `flutter analyze` / `flutter test` — app static analysis and widget tests
* `python3 tools/check_i18n.py` — translation parity across all 7 locales
* Releases version app and server together: bump `pettrack_app/lib/app_info.dart`
  (`kAppVersion`), `pettrack_app/pubspec.yaml` (`version: X.Y.Z+N`) and
  `SERVER_VERSION` in `pettrack_server/api_routes.py` in one commit, fill in
  `CHANGELOG.md`, then `git tag vX.Y.Z && git push --tags` — CI publishes the
  APK release with notes from the changelog
* `pip install -r requirements.txt -r requirements-dev.txt && pytest tests` — server API + vision tests
* All of the above run in CI (GitHub Actions) on every push to `main`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Top contributors:

<a href="https://github.com/szbnce/pettrack/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=szbnce/pettrack" alt="contrib.rocks image" />
</a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- AI USAGE DECLARATION -->
## AI Usage Declaration

This project was developed with the assistance of Artificial Intelligence (AI) coding assistants. AI was used to help accelerate the development process by generating boilerplate code, assisting with UI layouts, brainstorming solutions, and helping write documentation.

While AI tools were utilized, the core architecture, design decisions, and ultimate responsibility for the codebase remain with the human author.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- PRIVACY POLICY -->
## Privacy Policy

You can read the Privacy Policy for PetTrack by referring to the [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) file.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the GNU General Public License v3.0. To read more, please refer to the `LICENSE` file.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Bence Szabó - [@szbnce](https://t.me/szbnce) - contact@szabence.com

Project Link: [https://github.com/szbnce/pettrack](https://github.com/szbnce/pettrack)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Stardance](https://stardance.hackclub.com)
* [Img Shields](https://shields.io)
* [Best-README-template](https://github.com/othneildrew/Best-README-Template)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/szbnce/pettrack.svg?style=for-the-badge
[contributors-url]: https://github.com/szbnce/pettrack/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/szbnce/pettrack.svg?style=for-the-badge
[forks-url]: https://github.com/szbnce/pettrack/network/members
[stars-shield]: https://img.shields.io/github/stars/szbnce/pettrack.svg?style=for-the-badge
[stars-url]: https://github.com/szbnce/pettrack/stargazers
[issues-shield]: https://img.shields.io/github/issues/szbnce/pettrack.svg?style=for-the-badge
[issues-url]: https://github.com/szbnce/pettrack/issues
[license-shield]: https://img.shields.io/github/license/szbnce/pettrack.svg?style=for-the-badge
[license-url]: https://github.com/szbnce/pettrack/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/szbnce
[product-screenshot]: images/screenshot.png
[Flutter.dev]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev/
[Dart.dev]: https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white
[Dart-url]: https://dart.dev/
[FastAPI.tiangolo]: https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white
[FastAPI-url]: https://fastapi.tiangolo.com/
[Python.org]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[Python-url]: https://python.org/
[OpenCV.org]: https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white
[OpenCV-url]: https://opencv.org/
[SQLite.org]: https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white
[SQLite-url]: https://sqlite.org/ 