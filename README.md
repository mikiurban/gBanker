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
- BList - Add (left-click) or remove (right-click) the keyword to/from your blacklist. Displays your current blacklist, if no keyword is given. Only exact matches (not case sensitive, even if case sensitive search is enabled) will be blocked, e.g. inferno ruby will only block the raw gem, cut ones like brilliant inferno ruby will still be moved.
- QuickButtons - If enabled, you'll see a new frame with (at first) empty buttons. These can be left-clicked to take, or right-clicked to give items, which match the button's keyword. To set a keyword for a button, enter it into the textbox and click the button, or use the chat commands below. To remove it, use the options menu.

If you like them better, or want to create macros, slash commands for everything are still around. 
Arguments in [square brackets] are optional, letters in (b)rackets can be used instead of the whole word.

- /gb quicknum # -- sets number of QuickButtons to #
- /gb (t)ake [matchPhrase] -- move items from bank to inventory
- /gb (g)ive [matchPhrase] -- move items from inventory to bank
- /gb (c)ase -- toggle case sensitive search
- /gb (b)lacklist [(a)dd | (r)emove] [keyword] -- add or remove [keyword] from Blacklist, display current blacklist, if no keyword is given
- /gb (q)uick # [keyword] -- set or remove keyword for QuickButton #
 -/gb (q)uick # [label;matchPhrase;matchPhrase;] -- Setup multiple keywords for QuickButton #. Don't forget the semi-colon at the end!
- /gb delay # -- Set guild bank interaction delay (default: 0.4)
- note: give and take [matchPhrase] can be 'all', partial name match (e.g. 'Potion'), a specific expansion ('xpac:1'), or item type ('type:7:2')
-   expansion options: 0=WOW, 1=BC, 2=LK, 3=CAT, 4=PAN, 5=WOD, 6=LEG, 7=BFA, 8=SHA, 9=DF, 10=TWW
-   type options: 0=Consumable, 1=Contanier, 2=Weapon, 4=Armor, 7=Trade Good, 8=Enchant, 9=Recipe, 17=Pet
-   more type and subtype options, see https://warcraft.wiki.gg/wiki/ItemType

You may use the bold letters as shortcuts, e.g. /gb b a Hearthstone instead of /gbanker blacklist add Hearthstone