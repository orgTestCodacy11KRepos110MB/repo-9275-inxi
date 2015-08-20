# Inxi Usage #
inxi -`<`color`>` -`<`[option](http://code.google.com/p/inxi/wiki/inxi)`>`

  * ie ` inxi -c4 -I`
    * this will change to color option 4 and give inxi Information

See inxi [option](http://code.google.com/p/inxi/wiki/inxi) list for full list and explanation of available options. Always refer to an actual current inxi for latest options since these wiki pages only get updated now and then.

---

**IRC client usage**

---

Konversation:
For native internal command call:
  * first link or move inxi into [Konversation's script folder](http://code.google.com/p/inxi/wiki/Installation)
  * then run:
    * /inxi -`<`[option](http://code.google.com/p/inxi/wiki/inxi)`>`
For normal external script call, in Konversation session:
  * type:
    * /cmd inxi -`<`[option](http://code.google.com/p/inxi/wiki/inxi)`>`
    * example: /cmd inxi -d
and you'll see the expected output.

---

Quassel:
inxi ships as a built in script with Quassel, so you should just be able to run the standard builtin command to run an internal script.

---

### XChat ###

  * /exec -o inxi -`<`[option](http://code.google.com/p/inxi/wiki/inxi)`>`
    * the -o option show output to the channel.  Without it, only the user will see the output.

---

### WeeChat ###

For Debian users, installing weechat also installs the weechat-plugins.
Check with your distro for similar package before attempting below please.

For weechat to run external scripts like inxi, you have to install shell.py, if you don't already have it. To read how to install click
[here](http://code.google.com/p/inxi/wiki/WeeChat)

Then to run inxi, you would enter a command like this:
```
/shell -o inxi -bx
```
If you leave off the -o, only you will see the output on your local weechat.

weechat users may also like to check out the weeget.py


---

irssi and most other clients
  * /exec -o inxi -`<`[option](http://code.google.com/p/inxi/wiki/inxi)`>`
  * example:
```
/exec -o inxi -dn
```


---

To go to wiki list try clicking
[here](http://code.google.com/p/inxi/w/list)