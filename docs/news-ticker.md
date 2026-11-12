# News ticker (dwmblocks)

Scrolling RSS headlines in the dwm status bar. Implemented for x220/x230-style
installs; verified working on both (Nov 2026).

## Components
- `dwmblocks/bin/news-ticker.sh` — fetches Guardian UK RSS every 30 min and
  scrolls a 42-char window (0.2s/step) into `~/.cache/dwmblocks/news`, then
  signals dwmblocks with `pkill -RTMIN+5 dwmblocks` (block signal 5).
- `dwmblocks/systemd/news-ticker.service` — user service that runs the ticker
  forever (Restart=always).
- `scripts/install-news-ticker.sh` — installs + enables the user service.

## Requirements
1. `curl` and `libxml2` (`xmllint`) installed
2. dwmblocks built with a news block present. In `config.h`:
   ```c
   static const Block blocks[] = {
   /* command                            interval  signal */
   { "cat ~/.cache/dwmblocks/news",      0,        5 },
   ...
   { "$HOME/dwmblocks/weather.sh",       300,      0 },
   { "date '+%a, %d %b  %H:%M'",         30,       0 },
   { "$HOME/dwmblocks/wifi.sh",          5,        1 },
   ```
3. The block paths on disk: `~/dwmblocks/bin/news-ticker.sh`,
   `~/dwmblocks/weather.sh`, `~/dwmblocks/wifi.sh` (copy from the repo's
   `dwmblocks/` folder if missing).
4. `install -m 755 dwmblocks /usr/local/bin/dwmblocks`, restart dwmblocks.

## Install steps (fresh machine)
```bash
# from this repo
cp dwmblocks/bin/news-ticker.sh ~/dwmblocks/bin/   # create dirs if needed
cp dwmblocks/weather.sh dwmblocks/wifi.sh ~/dwmblocks/
cp dwmblocks/config.h ~/dwmblocks/config.h         # full config: news+weather+date+wifi
cd ~/dwmblocks && make && sudo make install
pkill -x dwmblocks && (DISPLAY=:0 /usr/local/bin/dwmblocks >/tmp/dwmblocks.session.log 2>&1 &)
scripts/install-news-ticker.sh
```

## Verify
```bash
systemctl --user is-active news-ticker.service   # active
cat ~/.cache/dwmblocks/news                      # scrolling window text
pkill -RTMIN+5 dwmblocks                         # force block refresh
DISPLAY=:0 xprop -root WM_NAME                   # bar content: must contain headline text
```
If `WM_NAME` contains the headline but you can't see it on a screen, check
you are looking at the right machine/display — the root window name is
ground truth.
