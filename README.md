
The Scripter addon provides a text UI to common ESO operations and provides ongoing notification of game events. See the Commands section below for the full list of commands available.

#### Source Code: https://github.com/neonatura/Scripter.git
#### Release Download: http://www.esoui.com/downloads/info793-Scripter-TextUINotifications.html

Functions
=========

Create and execute LUA functions from inside the game. Several examples and an easy to use interface makes a novice capable of running there own code.

#### Reference: The [Scripting API](Scripting-API) provides a list of the core functions available.

Triggers
========

The addon provides the following automatic triggers. All triggers can be disabled via the Addon configuration.

* Set's keybinding based on the individual character loaded.
* Automatically accept friend group invitations.
* Persistently mark items as junk.
* Create persistent or temporary timed events.

Notifications
=============

All notifications are displayed in a seperate UI window. The notification window can be disabled via the Addon configuration. The main event categories can be disabled individually.

Ongoing notifications are displayed to the character relating to book, money, lore books, money, inventory, experience, buffs, and other misc events.

All notifications are recorded to a character log which can be reviewed or search on via the "/log" command. In addition, a separate chat history log is provided.

Alias
=====

Provides the ability to create new, and manage existing, slash comments. All commands can be given a description for enhanced display in the "/cmd" command.

Synchronization
===============

Character attributes, craft traits, skills, worn items, and quests can optionally be synchronized between players in order to review a friend's character information. [Synchronization](Synchronization) can be configured to be performed manually or automatically.

Addon Compatibility
===================

All Scripter commands, except for "alias" and the commands generated from such, are compatible with the Wykkyd's Macros addon.

The Core API functions utilize the LibDataBank addon in order to store and retrieve information.

Commands
========
<pre>
/alias    Create and manage slash commands.
/away    Manage "away from keyboard" mode.
/clear    Clear the chat window history.
/cmd    Display slash commands.
/eq    Character inventory.
/friend    Display contacts information.
/junk    Display the junk item list.
/keybind    Setup key bindings.
/filter    Manage chat filter.
/invite    Perform group invite.
/leave    Perform group leave
/loc    Character location information.
/log    Manage character activity log.
/mail    Manage character's mail messages.
/min    Minimize the chat window.
/quest    Display character quest information.
/research    Display researchable items.
/sguild    Display guild character information.
/sgroup    Manage the character's party group.
/rl    Reload user intrface.
/scripter    Scripter command usage.
/sconfig    Scripter configuration settings.
/stat    Character attributes information.
/scmd    List all scripter commands
/feedback    Submit a Scripter bug or enhancement.
/snap    Take a screenshot.
/sync    Synchronize character attributes.
/time    Display current time.
/timer    Manage timed events.
/ttime    Display current Tamriel time.
/vendor    Display item vendor information.
/who    Display list of online friends.
</pre>
