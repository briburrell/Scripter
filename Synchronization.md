[CENTER][SIZE="5"][I]Scripter Synchronization[/I][/SIZE][/CENTER]

Character information synchronization in Scripter can be performed on a manual or automatic basis. Run [I]/sconfig[/I] in order to configure this setting.

The synchronization is performed by sending generated mail messages to another user's account. This mail message is then parsed and stored by Scripter. Both characters must have Scripter in order to review and deliver synchronization information.

Synchronization information consists of:
- Base character attributes
- Character skill information
- Character's worn items
- Active character quests
- Craft trait abilities

Note that synchronization messages are sent and received by a user's account name, but synchronization information is stored on a character name basis.

Synchronization is currently limited to users who are registered as a Friend or are part of a joined guild. Feel free to file a enhancement request if you feel this should be expanded to include additional users.

Scripter synchronization mail notifications must be read by the user in order to be processed. A mail will not be re-processed unless the [I]/sync /scan[/I] (see below) command is used. Synchronization mails may be automatically deleted by configuring said option in [I]/sconfig[/I]. Under no condition will an unread synchronization mail be deleted before it is read by a user. 

[U]Automatic Synchronization[/U]

Automatic synchronization is performed every twenty minutes. Information is propagated in a staged set of mails. Each mail will contain different information based on the priority of the information and when it was last sent. Base character attributes are always sent if no other category has priority. 

Additional users to synchronize with may be added via the [I]/sync <user>[/I] command.

[U]Manual Synchronization[/U]

A synchronization notification may manually be sent via the [I]/sync <user>[/I] command. Incoming synchronization mails are processed as soon as they are marked as read.

[U]Reviewing Information[/U]

The [I]/sync[/I] command will list all of the users who are registered for synchronization. The time displayed, when in automatic synchronization mode, is when the next synchronization notification will be sent to the specified account.

The [I]/sync /list[/I] command will list all of the users who you have synchronized with. The time displayed is when the sync was processed.

You can manually force Scripter to re-process email notifications with the [I]/sync /scan[/I] command.

The [I]/sync /list <user>[/I] command can be used to review all synchronized information delivered for a particular character name. You do not have to specify the full name, but the search is case sensitive. 

The [I]/stat <user>[/I], [I]/stat /skill <user>[/I], [I]/stat /craft <user>[/I], [I]/eq <user>[/I], and [I]/quest <user>[/I] commands will display categorized information related to a particular character name. No synchronization is required for a limited set of stats to be available via these commands providing they are a friend or guild member.
