# airspace-radar

Retrofuturistic 90s sci-fi live ADS-B airplane radar designed for OLED laptops in tent mode.

## Features
- Pure `#000000` OLED background with 4 switchable themes (`Amber`, `Phosphor`, `MAGI`, `Cyber`)
- Full-bleed azimuthal vector map (`countries-50m.json`) with drag-to-pan and mouse-wheel zoom
- Live ADS-B aircraft tracking via `adsb.lol` (with automatic local proxy and simulation fallback)
- Tent-mode friendly: Fullscreen (`F`), Screen Wake Lock (`WAKE`), and Auto-Cycle target lock-on

## Launch
Double-click `launch-radar.bat` (starts a local PowerShell server on `http://localhost:8765/`).
