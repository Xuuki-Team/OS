/* modify this file to change what commands output to your statusbar.
 * matches the verified working x230 status bar (news + weather + date + wifi). */

static const Block blocks[] = {
	/* command                interval    signal */
	{ "cat ~/.cache/dwmblocks/news",        0,        5 },
	{ "$HOME/dwmblocks/weather.sh",         300,      0 },
	{ "$HOME/dwmblocks/date.sh",            30,       0 },
	{ "$HOME/dwmblocks/wifi.sh",            5,        1 },
};

static char delim[] = "\x1f";
