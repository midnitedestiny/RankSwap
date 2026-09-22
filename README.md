[![](https://img.shields.io/badge/Donate-PayPal-blue.svg?style=for-the-badge&logo=paypal)](https://paypal.me/midnitedestiny) [![](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://www.buymeacoffee.com/midnitedestiny)

# RankSwap

**RankSwap** is a lightweight, high-performance utility addon designed for World of Warcraft players who want to keep their action bars tidy and up to date without the hassle of manual spell checking.

Whenever you finish visiting a class trainer and close the training window, RankSwap automatically scans your active action bars (slots 1 through 120), detects any outdated spell ranks, and instantly swaps them out for your highest learned equivalent.

## Key Features

*   **Automated Trainer Scanning:** Instantly checks your action bars the moment you close a class trainer window (`TRAINER_CLOSED`).
*   **Precise Location Reports:** Prints a clear summary in your chat detailing exactly which Bar and Button were updated (e.g., _Updated Bar 6, Button 7 from Thorns (Rank 1) to Thorns (Rank 2)_).
*   **Hunter Ammo Monitor:** Automatically watches your inventory bags for arrows or bullets, alerting you via chat and an on-screen popup warning when your stock dips below safe thresholds (< 200 and < 50).
*   **Native UI Integration:** Features full **Addon Compartment** support with hover tooltips and a movable **LibDataBroker / LibDBIcon** minimap button for quick manual scans (`/rs`).
*   **Zero Bloat:** Written cleanly using modern Blizzard API standards to ensure minimal CPU usage and zero frame stutter.

## Commands

*   `/rs` — Manually trigger an action bar scan for outdated spell ranks.
