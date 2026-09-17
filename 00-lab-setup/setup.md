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
- Note: `virtualbox-guest-utils` and `virtualbox-guest-x11` installed for clipboard and shared folder support

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

## 4. Installation & Troubleshooting

### 4.1 System Additions & Core Tools
```bash
sudo apt update
sudo apt install virtualbox-guest-utils virtualbox-guest-x11
sudo apt install -y build-essential gdb git python3 python3-pip python3-venv docker.io docker-compose-plugin
```

### 4.2 Docker Configuration
To allow running docker containers without sudo:

```bash
sudo usermod -aG docker $USER
```
Verification:
```bash
docker run --rm hello-world
```

### 4.3 pwndbg
```bash
git clone https://github.com/pwndbg/pwndbg
cd pwndbg && ./setup.sh && cd ..
```

### 4.4 pwntools
Troubleshooting Note: Initial installation attempts via pip inside a venv failed due to unicorn-engine binding dependencies. The issue was resolved by using the system package repository instead.
```bash
sudo apt update
sudo apt install -y python3-pwntools
```
Verification:
```bash
python3 -c "from pwn import *; print('pwntools OK')"
```

### 4.5 Ghidra
```bash
sudo snap install ghidra
```

## 5. VM Snapshot Management
A clean snapshot of the virtual machine was taken immediately after installing and verifying all the tools above.

When/Why to revert: This snapshot serves as a safe, baseline state. It is crucial to revert to this snapshot before analyzing potentially malicious files, running unknown exploits, or if the environment's configuration becomes corrupted, ensuring research is always conducted in a reproducible and controlled environment.

## 6. Target Platforms
picoCTF Username: LielKablan

pwn.college Username: LielKab

PortSwigger Username: lielikablan@gmail.com
