#PassDrop FAQ

##Q: How do I add an existing database?

From the root database screen, click the "Edit" button in the upper right corner, then click the "Add Database" entry that shows up at the bottom of the list. You can then navigate through your DropBox folders and find and click the .kdb file you wish to add.

##Q: How do I add a database with a different file extension?

Files without a .kdb extension appear greyed out when browsing your DropBox files, but you can still select them to add them to PassDrop. Just keep in mind that if the file is not a true KeePass 1.x database, you will always get an error when trying to open it. You cannot create new databases from PassDrop without the .kdb extension, but you could create one, rename it in DropBox on your desktop, and then re-add the renamed file to PassDrop.

##Q: How do I add a new database?

From the root database screen, click the "Edit" button in the upper right corner, then click the "Add Database" entry that shows up at the bottom of the list. Navigate through your DropBox account to the directory where you want to add the new database, and then click the "Add" button in the upper right corner.

##Q: Can I rename databases?

You can't rename the file on DropBox from within PassDrop, but you can change the database's name that's displayed in the PassDrop database list. To do this, click the "Edit" button in the upper right corner of the database list screen, then click the database you wish to rename. The screen that follows allows you to change the name of the database.

##Q: Can I change a database's master password?

Yes. From the database list screen, tap the "Edit" button in the upper right corner, then tap the database you want to change the password for. On the screen that follows you can enter a new password, but you must also enter your old password before you can save it.

##Q: When I go to add my database from DropBox, why doesn't it show up in the file list?

Try scrolling the DropBox directory contents where your database should be down beyond the top of the screen. A reload indicator should appear and the directory listing will be refreshed. If your password database still doesn't show up, double-check that it is where you think it is, and that it has successfully synced to DropBox from your desktop computer (i.e., it is visible from other computers and devices that you use to access DropBox).

##Q: Why is my database on DropBox greyed out with a question mark icon?

PassDrop only works with KeePass version 1.x (classic) files, which have a .kdb extension. If your database has a .kdbx extension, it means you are using KeePass version 2.x (professional). You have a few options: use KeePass 2.x to export your database as a KeePass 1.x database and use that in PassDrop (but then you lose two-way syncing and have to re-export every time you make changes on the desktop), switch over to KeePass 1.x or KeePassX on your desktop, or use one of the competing iPhone apps available on the app store which support KeePass 2.x databases instead of PassDrop.

##Q: How can I search my entries in PassDrop?

When viewing the groups in the root of your database, you can use the "Search" field at the top to search through all of the entries in your database (you may need to scroll the groups down to see the field on your iPhone). Entries in a group named "Backup" will not show up in the results by default, but you can disable this behavior in PassDrop's settings. Using the "Search" field at the top of any other group besides your database's root will only search entries within that group and its subgroups.

##Q: How do I add, move, or edit groups and entries?

The first thing you have to do is make sure that you are opening your database in writable mode. By default, PassDrop opens them in read-only mode (to reduce the overhead required when creating and removing lock files). You can change this behavior by clicking the "Settings" button in the upper left hand corner of the root database list screen, and changing the "Open Databases" option to either "Writable" or "Always Ask."

Once your database is open in writable mode, navigate into the group whose contents you wish to edit, and click the "Edit" button in the upper right hand corner. Once the screen is in edit mode, tapping on existing items will let you edit and move them, "Add New" items will appear in the group and entry lists, item handles can be dragged to rearrange them, and items can be deleted by tapping the red "-" icons next to them.

After you've made changes and exit edit mode, you will notice a new "Sync" button appears in the lower right corner of the group view screen—clicking this button will allow you to either revert the changes you have made, or save and upload them to DropBox.

##Q: How do I use my keyfile instead of a password to unlock my database?

Unfortunately, PassDrop does not support keyfile authentication. You will need to use KeePass or KeePassX to change your database to use password authentication instead before you can open it in PassDrop.
