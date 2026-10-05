
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
   docker compose up -d --build pettrack
   ```
3. Read the startup logs and note the **4-digit PIN** (and the QR code for pairing phones)
   ```sh
   docker logs pettrack
   ```
4. Your server is now reachable at `http://<server_ip>:8000` (server API + web dashboard).

Your data (replays, snapshots, database, secrets) lives in `./pettrack_server/`, so it
survives container rebuilds.

#### Option B — Native (Linux, Windows, macOS)

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

PetTrack is built for your own homelab — a bit of care keeps it that way:

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

### Development & testing

* `flutter analyze` / `flutter test` — app static analysis and widget tests
* `python3 tools/check_i18n.py` — translation parity across all 7 locales
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