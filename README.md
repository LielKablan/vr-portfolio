# Vulnerability Research Portfolio

This repository contains a structured vulnerability research environment alongside a collection of writeups, exploits, and root-cause analyses. It is built as a progressive roadmap covering low-level memory fundamentals, reverse engineering, binary exploitation, and public CVE analysis.

## Project Structure

The repository is organized into progressive research stages:

- [x] **00-lab-setup:** Reproducible isolated research environment.
- [ ] **01-foundations:** Memory layout analysis, C internals, and x86-64 assembly.
- [ ] **02-reverse-engineering:** Static and dynamic analysis of stripped binaries.
- [ ] **03-binexp-control-flow:** Buffer overflows and control flow hijacking mechanisms.
- [ ] **04-binexp-defeating-mitigations:** Bypassing NX and ASLR (Ret2libc).
- [ ] **05-ctf:** Vulnerability discovery and writeups for designated CTF challenges.
- [ ] **06-web:** Web application vulnerability assessments and reports.
- [ ] **07-cve-analysis:** Root cause analysis and 1-day reproduction of public CVEs.
- [ ] **08-methodology:** Research notes and techniques.

## Lab Environment & Tools

All research is conducted within an isolated Ubuntu Linux virtual machine. Core tools utilized in this repository include:
* **Analysis & Debugging:** GDB, pwndbg, Ghidra
* **Exploitation:** Python 3, pwntools
* **Environment:** VirtualBox, Docker, GCC

### 🔗 [View the complete Lab Setup Guide](00-lab-setup/setup.md)
The full documentation for provisioning the virtual machine and installing all required dependencies is detailed in the setup directory linked above.

## Usage

Each directory contains a standalone component of the research. Navigate to the relevant stage directory to view the source code, vulnerable binaries, exploits, and the accompanying Markdown writeup detailing the methodology and execution steps.

## Rules of Engagement

All research, scripts, and exploits documented in this repository are executed strictly within local, isolated virtual environments.
