# Steam Multiplayer
Thanks to the wonderful library of Sh0wdown called RedirectPlay, it is possible to play Stronghold Crusader via Steam!

## Usage

### In-game
1. Activate this extension
2. Select Multiplayer in the main menu of the game.
3. Choose Steamworks as the provider.
![Select steamworks](https://github.com/gynt/ucp-extension-steam-multiplayer/blob/main/locale/image.png?raw=true)

4. Either click Host or Join. When you click Host, a pop-up will appear to configure the lobby. Make sure to set it to Public (not Friends only), and add a password if you want to play only with people you know. When clicking Join, and selecting a lobby, a password pop-up may appear if the lobby has a password set.

### From within Steam (joining only)
To join a lobby, you can also click on the "join game" link found on a Steam profile page.

As a host, first create a multiplayer lobby (see above), then open the Steam overlay (shift+tab) and click on your name/icon to navigate to your profile page. Then, right click the "join game" button and copy the link. Send this link to the people you want to play with. When they click it, Steam opens the game and the game immediately connects to the lobby.

### From the command line

These are the command line options:
- `+connect_lobby <lobby id>` Added by Steam. The lobby id is a uint64.
- `+host_game` Claim host, everyone waits for you to join the lobby. If no lobby was specified via `+connect_lobby`, create a lobby.
- `+join_directly` Use the `<lobby id>` to directly join to the lobby at launch without enumerating available lobbies (and therefore non nice GUI). The UI can seem frozen if the host isn't responding yet. Preferred method for invite-only (private) lobbies.
- `+join_enumerated` Enumerate lobbies and compare the `<lobby id>` to them, if a match, join the lobby. Only works for public and friend-lobbies.

## Known issues
1. People joining a public lobby without a password may crash an ongoing game.
2. The pop-up window may be hidden behind the game window, requiring alt+tab to see it.