local name, gb = ...
local loc = GetLocale()
if loc == "deDE" then
	gb.L = {
		-- (error) messages
		["on"] =	    "An",
		["off"] =	    "Aus",
		["nobank"] =	"Keine Bank offen.",
		["bagsfull"] =	"Taschen sind voll.",
		["moving"] =	"Bewege ", -- number of items follows
		["items"] =		" Item(s).",
		["added"] =		"Füge ", -- itemname follows
		["toblist"] =	" zu deiner Blacklist hinzu.",
		["blist"] =		"Blacklist: ", -- actual blacklist follows
		["removed"] =	"Entferne ", -- itemname follows
		["fromblist"] =	" von deiner Blacklist.",
		["updv"] =		"Aktualisiere auf v", -- version number follows
		["qb0"] =		"Die Anzahl der QuickButtons muss größer als 0 sein. Wenn du sie nicht benutzen willst, kannst du sie im Optionsmenü abschalten.",
		["unknown1"] =	"Unbekannter Befehl - gib ", -- slash command (see: helpkey) follows
		["unknown2"] =	" ein, um Hilfe zu erhalten.",
		["rdy"] =		"Fertig!",
		["delay"] =		"Gildenbank-Interaktions-Verzögerung: ",
		-- button texts
		["t"] =			"Nehmen",
		["g"] =			"Geben",
		["bl"] =		"BList",
		-- options menu
		["css"] =		"Groß-/Kleinschreibung bei der Suche berücksichtigen",
		["aob"] =		"Automatisch zusammen mit der Bank öffnen",
		["aog"] =		"Automatisch zusammen mit der Gildenbank öffnen",
		["sqb"] =		"Zeige QuickButtons",
		["qbhelp"] =	'"/gb quicknum #" um die Anzahl der Buttons zu ändern',
		["cqb"] =		"QuickButton löschen",
		["silent"] = 	"Chatnachrichten verstecken",
		-- slash commands
		["helpkey"] =	"hilfe",
		-- help text
		["help1"] =		"gBanker v", -- version number follows
		["help2"] =		" - Hilfe",
		["help"] = {
			"/gb quicknum # -- setzt die Anzahl an QuickButtons auf #",
			"Argumente in [eckigen Klammern] sind optional, Buchstaben in (K)lammern können anstatt des ganzen Wortes verwendet werden.",
			"/gb (t)ake [Suchbegriff] -- bewegt alle Items [die den Suchbegriff enthalten] von der Bank ins Inventar",
			"/gb (g)ive [Suchbegriff] -- bewegt alle Items [die den Suchbegriff enthalten] vom Inventar in die Bank",
			"/gb (c)ase -- Berücksichtigung der Groß-/Kleinschreibung bei der Suche an-/ausschalten",
			"/gb (b)lacklist [(a)dd | (r)emove] [Begriff] -- Füge [Begriff] zu deiner Blacklist hinzu (add), oder entferne ihn (remove), zeige den aktuellen Inhalt der Blacklist, wenn kein Begriff angegeben wird",
			"/gb (q)uick # [Suchbegriff] -- Suchbegriff für QuickButton # festlegen oder entfernen",
			"/gb (q)uick # [Beschriftung;Suchbegriff1;Suchbegriff2;] -- QuickButton # mit mehreren Suchbegriffen belegen. Semikolon am Ende nicht vergessen!",
			"/gb delay # -- Gildenbank-Interaktions-Verzögerung einstellen (Standard: 0.4)",
		},
	}
else -- default english locale
	gb.L = {
		-- (error) messages
		["on"] =	    "on",
		["off"] =	    "off",
		["nobank"] =	"No bank open.",
		["bagsfull"] =	"Bags are full.",
		["moving"] =	"Moving ", -- number of items follows
		["items"] =		" item(s).",
		["added"] =		"Added ", -- itemname follows
		["toblist"] =	" to your blacklist.",
		["blist"] =		"Blacklist: ", -- actual blacklist follows
		["removed"] =	"Removed ", -- itemname follows
		["fromblist"] =	" from your blacklist.",
		["updv"] =		"Updating to v", -- version number follows
		["qb0"] =		"Number of QuickButtons must be greater than 0, if you don't want to use them, disable them via the options menu.",
		["unknown1"] =	"Unknown command - type ", -- slash command (see: helpkey) follows
		["unknown2"] =	" for help.",
		["rdy"] = 		"Done!",
		["delay"] =		"Guild bank interaction delay: ",
		-- button texts
		["t"] =			"Take",
		["g"] =			"Give",
		["bl"] =		"BList",
		-- options menu
		["css"] =		"Case sensitive search",
		["aob"] =		"Auto-open at bank",
		["aog"] =		"Auto-open at guild bank",
		["sqb"] =		"Show QuickButtons",
		["qbhelp"] =	'"/gb quicknum #" to change # of buttons',
		["cqb"] =		"Clear QuickButton",
		["silent"] = 	"Hide chat feedback",
		-- slash commands
		["helpkey"] =	"help",
		-- help text
		["help1"] =		"gBanker v", -- version number follows
		["help2"] =		" - help",
		["help"] = {
			"/gb quicknum # -- sets number of QuickButtons to #",
			"Arguments in [square brackets] are optional, letters in (b)rackets can be used instead of the whole word.",
			"/gb (t)ake [keyword] -- move all items [which contain keyword] from bank to inventory",
			"/gb (g)ive [keyword] -- move all items [which contain keyword] from inventory to bank",
			"/gb (c)ase -- toggle case sensitive search",
			"/gb (b)lacklist [(a)dd | (r)emove] [keyword] -- add or remove [keyword] from Blacklist, display current blacklist, if no keyword is given",
			"/gb (q)uick # [keyword] -- set or remove keyword for QuickButton #",
			"/gb (q)uick # [label;keyword1;keyword2;] -- Setup multiple keywords for QuickButton #. Don't forget the semi-colon at the end!",
			"/gb delay # -- Set guild bank interaction delay (default: 0.4)",
		},
	}
end
loc = nil