# Lab Setup Documentation

## 1. Objective

The purpose of this lab is to provide an isolated and reproducible
environment for learning and practicing reverse engineering,
binary exploitation, and related security research techniques.

## 2. Environment

- Hypervisor: VirtualBox
- Operating System: Ubuntu 26.04 LTS
- Architecture: x86_64
- CPU: 2
- RAM: 4096 MB
- Disk: 40 GB

## 3. Tools and Versions

| Tool | Version |
|------|---------|
| GCC | 15.2.0 |
| GDB | 17.1 |
| pwndbg | 2026.07.29 build: 714c79541 |
| Python | 3.14.4 |
| pwntools | 4.15.0 |
| Docker | 29.1.3 |
| Ghidra | 12.1.2 |
| Git | 2.35.0 |

## 4. Installation
first:
```bash
sudo apt update
```

### 4.1 GCC

Commands used to install GCC:

```bash
sudo apt install virtualbox-guest-utils virtualbox-guest-x11
sudo reboot
```
