# gBanker
Continuation of the original gBanker addon by SaraFDS

Original source: https://www.wowinterface.com/downloads/info17826-gBanker.html

A small AddOn to simplify moving (lots of) items to and from your bank or guild bank. You may move simply all items, or only those (partially) matching a keyword.

The GUI can automatically be opened and closed with your (guild) bank.

- Opt. - Open options menu
- x - Close GUI
- Textbox - Enter your keyword there
- Give - Move all items (which match the keyword, if given) from inventory to bank
- Take - Move all items (which match the keyword, if given) from bank to inventory
- BList - Add (left-click) or remove (right-click) the keyword to/from your blacklist. Displays your current blacklist, if no keyword is given. Only exact matches (not case sensitive, even if case sensitive search is enabled) will be blocked, e.g. "inferno ruby" will only block the raw gem, cut ones like "brilliant inferno ruby" will still be moved.
- QuickButtons - If enabled, you'll see a new frame with (at first) empty buttons. These can be left-clicked to take, or right-clicked to give items, which match the button's keyword. To set a keyword for a button, enter it into the textbox and click the button, or use the chat commands below. To remove it, use the options menu.

If you like them better, or want to create macros, slash commands for everything are still around:

- /gbanker - Open GUI
- /gbanker give|take [keyword]
- /gbanker case - Toggle case sensitive search
- /gbanker blacklist [add|remove keyword]
- /gbanker quick # [keyword] - Sets keyword for QuickButton #. Enter no keyword, to clear the button
- new To create a QuickButton with multiple keywords, enter them like this: label;keyword1;keyword2; e.g. gems;cardinal ruby;jade;dawnstone; You're free to use as many keywords as you like, but don't forget the ; after the last keyword.

You may use the bold letters as "shortcuts", e.g. /gb b a Hearthstone instead of /gbanker blacklist add Hearthstone