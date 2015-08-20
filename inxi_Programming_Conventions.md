# Programming Conventions #
If you would like to submit patches for inxi, read and understand these conventions.  Patches not following these rules will be ignored.  (While these are the rules, some old code still remains in inxi which breaks these rules.  Those will be dealt with in time.)

As with all 'rules' there are exceptions, these are noted where used.


---

## Basic Formatting and Structural Rules ##
  * Indentation: TABS
  * Do not use ```....``` (back quotes; outdated bash style), those are totally non-reabable, use $(....) (parens; new bash style).
    * Back quotes start a new shell.
    * Parenthesis run in current shell.
  * Do not use one liner flow controls. Readability is more important.
  * The ONLY time you should use ';' (semi-colon) is in this single case:` if [[ condition ]];then`.
  * Never use compound 'if': ie, `if [[ condition ]] && statement`.
  * Note: `[[ -n $something ]]` - double brackets does not require quotes for variables: ie, "$something".
  * Always use quotes, double or single, for all string values.
  * All new code/methods must be in a function.
  * For all boolean tests, use 'true' / 'false'.
    * !! Do NOT use 0 or 1 unless it's a function return.
  * Avoid complicated tests in the if condition itself.
  * To 'return' a value in a function, use 'echo <var>'.<br>
<ul><li>For gawk: use always <code>if ( num_of_cores &gt; 1 ) { hanging { starter </code>for all blocks<br>
<ul><li>This method lets us use one method for all gawk structures, including BEGIN/END, if, for, etc<br>
<h2>Variables and Function Naming:</h2>
</li></ul></li><li>All functions should follow standard naming--verb adjective noun.<br>
<ul><li>ie, get_cpu_data<br>
</li></ul></li><li>All variables MUST be initialized / declared explicitly.<br>
</li><li>All variables should clearly explain what they are, except counters like i, j.<br>
</li><li>Each word of variable or function must be separated by <code>'_'</code> (underscore) (camel form).<br>
<ul><li>use_this_style<br>
</li></ul></li><li>Global variables are 'UPPER CASE', at top of script.<br>
<ul><li>ie, SOME_VARIABLE=''<br>
</li></ul></li><li>Local variables are 'lower case' and declared at the top of the function.<br>
<ul><li>ie, some_variable=''<br>
</li></ul></li><li>Locals that will be inherited by child functions have first char capitalized (so you know they are inherited).<br>
<ul><li>ie, Some_Variable<br>
</li></ul></li><li>Booleans should start with '<code>b_</code>' (local) or '<code>B_</code>' (global) and state clearly what is being tested.<br>
</li><li>Arrays should start with '<code>a_</code>' (local) or '<code>A_</code>' (global).<br>
<hr />
<h2>Special Notes:</h2>
</li><li>The color variable ${C2} must always be followed by a space unless you know what character is going to be next for certain. Otherwise irc color codes can be accidentally activated or altered.<br>
</li><li>For native script konversation support (check distro for correct konvi scripts path):<br>
<ul><li>'KDE3' ln -s <path to inxi> /usr/share/apps/konversation/scripts/inxi<br>
</li><li>'KDE4' ln -s <path to inxi> /usr/share/kde4/apps/konversation/scripts/inxi<br>
</li></ul></li><li>DCOP doesn't like \n, so avoid using it for most output unless required, as in error messages.</li></ul>

<hr />
To go to wiki list  try clicking<br>
<a href='http://code.google.com/p/inxi/w/list'>here</a>