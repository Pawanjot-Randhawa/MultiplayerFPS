# Multiplayer FPS + Anti-Cheat Research Project

This project is a practical testbed where I developed both:

- A multiplayer FPS game.
- A supporting anti-cheat service designed to detect cheating behavior.

The game acts as a controlled environment for repeatable testing, while the backend anti-cheat pipeline analyzes gameplay frames using:

- A filtering algorithm.
- Gemini-based prompting.

Together, these are used to identify suspicious player behavior patterns.

## Backend

Backend repository / deployment link: https://github.com/Pawanjot-Randhawa/MultiplayerFPS-FastAPI-service

- [INSERT BACKEND LINK HERE]

## Running Locally

### Requirements

- [Godot Engine](https://godotengine.org/) (compatible with this project version)
- Steam client installed and running
- A Steam account with access/configuration needed for local multiplayer testing

### Notes

- Steam is required to run this project locally because multiplayer/session features rely on Steam integration (via the GodotSteam addon).
- Open this folder as a Godot project and run the main scene from the editor.

## Project Structure (High Level)

- `Player/` - Player scene and gameplay logic.
- `World/` - World and arena scenes.
- `Steam/` - Steam manager/integration scripts.
- `Anticheat/` - In-project anti-cheat related scene/script assets.
- `Console/` - Debug/console utilities.
- `addons/godotsteam/` - GodotSteam plugin binaries and extension setup.

## Purpose

This repository is focused on experimentation and evaluation of cheat-detection ideas in a real-time multiplayer context.
