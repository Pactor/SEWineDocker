# 🚀 Space Engineers Dedicated Server
A fully automated Docker-based **Space Engineers dedicated server** featuring **mod support**, running under Wine inside Ubuntu. Includes automatic port configuration, plugin selection, mod setup, and world configuration scripts.

---

## 🧱 Image Summary
- Base OS: Ubuntu (headless)
- Final Image Size: ~4.4 GB (with a new world created)
- Features: Mod support, auto-port mapping, configuration tools

---

## 📦 Installed Packages
| Package | Required | Notes |
|----------|-----------|-------|
| software-properties-common | ❌ | Optional helper for repos |
| curl | ✅ | Required for downloads |
| gnupg2 | ✅ | For secure repo setup |
| wget | ✅ | Required |
| net-tools | ✅ | Useful for debugging |
| winbind | ✅ | Recommended |
| cabextract | ✅ | Required by Winetricks |
| unzip | ✅ | Required |
| zip | ✅ | Optional |
| xvfb | ✅ | Required (for headless Wine) |
| sudo | ✅ | Required |
| nano | ❌ | Optional |
| wine64 | ✅ | Required |
| wine32 | ✅ | Recommended |
| winetricks | ✅ | Required |
> 💡 Optional packages can be removed to slightly reduce image size.

---

## ⚙️ Setup
Clone this repository:  
`git clone https://github.com/Pactor/SEWineDocker.git`  
`cd SEWineDocker`

Install and configure Docker for user access:  
`sudo ./setup_docker_user.sh`  
(Log out and back in if prompted.)

Build the Docker image:  
`./build.sh`

Configure the server ports (you’ll be asked for Game, Steam, and RCON ports):  
Defaults → 27016 / 8766 / 8080

You can simply press enter when asked to accept the default ports.

Enter the container:  
`docker attach sewine`  
or, if not yet running:  
`docker start -ai sewine`

Inside the container, create your world:  
`./install_world.sh`  
You’ll be prompted to choose a scenario, mods, and plugins (search by partial name such as “quan” or “sed”). After setup, you’ll be asked whether to configure the world now or later.

To adjust gameplay and world settings later:  
`./configure_game.sh`

---

Backups are automatically created before configuration changes. This image supports Steam Workshop mods, and headless server operation — ideal for dedicated Linux hosts for friends and family.

