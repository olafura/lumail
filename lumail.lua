--
-- When lumail launches it will look for two configuration files, and
-- load them both in turn if they exist:
--
--   /etc/lumail.lua
--   ~/.lumail/config.lua
--
-- If you wish to load an additional configuration file you may do so
-- via the --rcfile argument:
--
--   $ lumail --rcfile ./lumail.lua
--
--
--
-- The configuration file is responsible for determining which keystrokes
-- are recognized, and what they will do.  The configuration file can
-- contain functions you define yourself, as this one does, and also make
-- use of the Lua primitives that lumail implements internally.
--
-- The lumail primitives are documented online here:
--
--   http://lumail.org/lua/
--
-- Steve
-- --
--



--
-- This setting is used to specify the prefix for your maildir hierarchy.
--
-- (The directory specified will be processed recursively.)
--
maildir_prefix( os.getenv( "HOME" ) .. "/Maildir" );

--
-- There is only one folder which is special, and that is the one where
-- lumail will record copies of outgoing mail(s).
--
-- The sent-mail folder may be specified here:
--
sent_mail( maildir_prefix() .. "/sent-mail" );


--
-- Set the from address for yourself, which is used for
-- composing/replying.
--
-- This can be changed in one of the available hooks.
--
-- In this configuration file we use the `on_select_folder()` function later.
--
default_email = "Steve Kemp <steve@steve.org.uk>";
from( default_email );


--
-- Show all folders by default
--
-- When called wiht no arguments this function will return the current
-- setting, otherwise it will update it.  This is a common pattern for lumail,
-- each of the functions which can get or set a value works in the same way.
--
-- The maildir limit can be set to three values:
--
--    all  -> Show all maildir folders.
--    new  -> Show all maildir folders which contain unread messages.
--   "str" -> Show all maildir folders which match the substring "str".
--
-- See "all_folders" , "new_folders", and "livejournal_folders" functions for
-- example of use.
--
maildir_limit( "all" );


--
-- When opening folders we'll show all messages.
--
-- Valid options are:
--
--        all  -> Show all message.
--        new  -> Show all unread messages.
--       "str" -> Show all messages which match the substring "str".
--
index_limit( "all" );



date_formats = {"%a %b %d %T %Y",  "%a, %b %d %T %Y"}
--
-- The index format controls how messages are displayed inside folder lists.
--
-- Valid options are currently limited to:
--
--   $DAY, $MONTH, $YEAR
--   $DATE
--   $FLAGS
--   $FROM
--   $SUBJECT
--   $TO
--
--
index_format( "[$FLAGS] $DAY/$MONTH/$YEAR $FROM - $SUBJECT" );


--
-- The headers we show when displaying a mail.
--
-- (The headers listed are shown in the order they are specified here.)
--
headers = { "$TO", "$FROM", "$DATE", "$SUBJECT" }


--
-- This function is called when the client is launched.
--
-- You might consider something useful like this:
--
--    os.execute( "imapsync ..." );
--
function on_start()
   msg("lumail v" .. VERSION .. " http://lumail.org/" );
end


--
-- This function is called when a folder is selected.
--
-- It is where you can run per-folder hooks.
--
-- Remember: More than one folder might be selected.
--
function on_select_folder( folder )

   --
   -- Change the email address we use depending on our folder.
   --
   if ( string.find( folder, "debian-administration", 1, true )  ) then
      from ("Steve <steve@debian-administration.org>");
   elseif ( string.find( folder, "debian" , 1, true )  ) then
      from("Steve <skx@debian.org>");
   else
      from( default_email );
   end

   msg( "There are " .. count_messages() .. " messages" );
end


--
-- Jump to the end of the list of messages/maildirs.
--
function jump_to_end()

   mode = global_mode()
   mode = string.lower( mode );

   if ( string.find( mode, "maildir" ) ) then
      jump_maildir_to( count_maildirs() - 1 );
   elseif (string.find(mode, "index" ) ) then
      jump_index_to( count_messages() - 1 );
   else
      msg( "jump_to_end not implemented for mode:" .. mode );
   end
end


--
-- This function is called when a message is displayed.
--
-- The argument is the path to the message on-disk.
--
-- Here we use the "is_new()" and "mark_read()" functions with that
-- path.
--
-- (If the path were omitted then the current-message would be implicit.)
--
-- We mark any new message(s) read when we read them here.
--
function on_read_message( path )
   if ( is_new() == 1 ) then
      mark_read();
   end
end


--
-- Show the version of this client.
--
function show_version()
   msg("This is lumail version " .. VERSION );
end


--
-- This function is called when the client exits.
--
-- It could also be used to run an imap-sync, or similar hook at exit-time.
--
function on_exit()
   print("print: on_exit");
   io.write( "io.write: on_exit\n")
   io.write("The global mode was: '" .. global_mode() .. "'.\n");
   io.write("The maildir_limit setting was '" .. maildir_limit() .. "'\n" );
end


--
-- This function is called when the client is idle.
--
-- You might run something like:
--
--   if the current-time is a multiple of five-minutes
--     os.execute("imapsync ..")
--
-- (Of course you may prefer to call fetchmail, or similar.)
--
function on_idle()
   m = global_mode()
   m = string.lower( m );

   str = ""

   if ( string.find( m, "maildir" ) ) then
      str = "mode:" .. m ..  " limit:" .. maildir_limit();
   else
      str = "mode:" .. m ;
   end

   msg( str .. " time:" .. os.date("%X" ) );
end


--
-- Switch to the index-view mode.
--
-- This will display the messages contained in all currently-selected folders.
--
-- (Selected folders will be displayed with a "[x]" next to them in maildir-mode.)
--
function index()
   global_mode( "index" );
   clear();
end


--
-- Switch to the maildir-mode.
--
function maildir()
   global_mode( "maildir" );
   clear();
end


--
-- Move to message-mode with the currently selected message.
--
function view_message()
   global_mode( "message");
   clear();
end


--
-- When in maildir-mode show all folders.
--
function all_folders()
   maildir_limit( "all" );
   clear();
end


--
-- When in maildir-mode show all folders which contain unread messages.
--
function new_folders()
   maildir_limit( "new" );
   clear();
end


--
-- When in maildir-mode show all folders which have a path matching the given pattern.
--
function livejournal_folders()
   maildir_limit( "livejournal.2" );
   clear();
end


--
-- Navigation functions for maildir-mode
--
function maildir_down()
   scroll_maildir_down( 1 );
end
function maildir_page_down()
   -- The minus-two is to account for the status-area
   scroll_maildir_down( screen_height() - 2  );
end
function maildir_up()
   scroll_maildir_up(1);
end
function maildir_page_up()
   -- The minus-two is to account for the status-area
   scroll_maildir_up( screen_height() -2 );
end



--
-- Navigation functions for index-mode
--
function message_down()
   scroll_index_down( 1 );
end
function message_page_down()
   -- The minus-two is to account for the status-area
   scroll_index_down( screen_height() - 2 );
end
function message_up()
   scroll_index_up(1);
end
function message_page_up()
   -- The minus-two is to account for the status-area
   scroll_index_up( screen_height() - 2 );
end


--
-- Search for the next folder/message which matches the entered pattern.
--
function search_next()
   x = prompt("/:" );
   m = global_mode();

   if ( string.find( m, "maildir" ) ) then
      scroll_maildir_to( x );
   elseif (string.find(m, "index" ) ) then
      scroll_index_to( x );
   else
      msg( "search_next() not implemented for mode:" .. m );
   end
end


--
-- Open a folder exclusively.
--
-- This behaves like the traditional "open folder" function in our favourite
-- client.  I like to open multiple folders at once, because that's how I roll.
--
function open_folder()
   clear_selected_folders();
   add_selected_folder()
   global_mode( "index" );
   clear();
end



--
-- Open my most important folders.
--
function faves()
   global_mode( "index" );

   -- ensure all folders are available
   maildir_limit( "all" );

   -- clear the currently selected folders.
   clear_selected_folders();

   -- The folders we care about
   interesting = { "/.steve.org.uk", "/.people.kirsi",  "/.edinburgh-portraits.com" };

   -- For each one we're going to open
   for index,name in ipairs( interesting ) do

      -- Jump to first folder.
      jump_maildir_to( 0 )

      -- Scroll forward until we find the matching folder
      scroll_maildir_to( name );

      --
      -- TODO:
      -- "current_maildir" will return the value we've found.
      -- We should check if it matches.
      -- In this case I know it always will.  Probably.
      --

      -- Add it to the selected set.
      add_selected_folder()

   end

   -- Now we've selected our folders, open them.
   global_mode( "index" );
   clear();
end


--
-- Mark all messages in the current folder as read.
--
function mark_all_read()
   count = count_messages()
   i = 0

   while( i < count ) do
      jump_index_to( i )
      mark_read()
      i = i + 1
   end

end


--
-- Now setup keymaps for the different modes.
--
-- The same keypress might do different things in different modes,
-- which is one of the advantages of a modal-client.
--
-- However to avoid duplication there is a global keymap.
--
--   For example this works in all modes:
--      kemymap['global']['Q'] = 'exit()';
--
keymap = {}
keymap['global']  = {}
keymap['index']   = {}
keymap['message'] = {}
keymap['maildir'] = {}


--
-- Global Bindings
--
-- Debug message.
keymap['global']['G'] = 'msg("Global-Steve");';
-- Quit
keymap['global']['Q'] = "exit()"
-- Compose a new message.
keymap['global']['c'] = "compose()"
-- repl-mode
keymap['global'][':'] = "loadstring(prompt(\":\"))();";
-- Execute-shell
keymap['global']['!'] = "exec(prompt(\"Shell command:\"));";
-- Move to Maildir-mode
keymap['global']['M']   = 'maildir()';
-- Move to Index-mode
keymap['global']['I'] = 'index()';
-- Show the client version
keymap['global']['v'] = 'show_version()'
-- Jump to end
keymap['global']['*'] = 'jump_to_end()'
-- Refresh display
keymap['global']['^R'] = 'refresh_display()'
keymap['global']['^L'] = 'refresh_display()'


--
-- Quitting means different things in different modes.
--
--  If viewing a message quit means return to the index.
keymap['message']['q'] = "index()"
--  If viewing a folder quit means return to the maildir list.
keymap['index']['q'] = "maildir()"
-- If viewing a maildir list then q means exit.
keymap['maildir']['q'] = "exit();"


--
-- Toggle display of folders
--
keymap['maildir']['a'] = 'all_folders()'
keymap['maildir']['n'] = 'new_folders()'
keymap['maildir']['l'] = 'livejournal_folders()'

--
-- Scroll up/down & find folders
--
keymap['maildir']['j'] = 'maildir_down()'
keymap['maildir']['J'] = 'maildir_page_down()'
keymap['maildir']['k'] = 'maildir_up()'
keymap['maildir']['K'] = 'maildir_page_up()'
keymap['maildir']['/'] = 'search_next()'
keymap['maildir']['f'] = 'faves()'


--
-- Scroll up/down the message index
--
keymap['index']['j'] = 'message_down()'
keymap['index']['J'] = 'message_page_down()'
keymap['index']['k'] = 'message_up()'
keymap['index']['K'] = 'message_page_up()'
keymap['index']['/'] = 'search_next()'

keymap['index']['Space'] = 'view_message()'
keymap['index']['Enter'] = 'view_message()'
keymap['index']['r'] = 'reply()'

--
-- View all/new messages only.
--
keymap['index']['a'] = 'index_limit("all");'
keymap['index']['n'] = 'index_limit("new");'

--
-- Selection bindings.
--
--  "space" will toggle the current folder as selected.
--  "return" will open the selected folder exclusively.
--
keymap['maildir']['Space'] = 'toggle_selected_folder()'
keymap['maildir']['Enter'] = 'open_folder()'



--
-- Message-scrolling.
--
keymap['message']['j'] = 'message_down()'
keymap['message']['k'] = 'message_up()'
keymap['message']['/'] = 'search_next()'
keymap['message']['r'] = 'reply()'

-----
-----
---
--  Here be dragons.
---
-----
-----

--
-- Debug Code ; test getting the selected folders works.
--
function debugy()
   sels = selected_folders();

   ff = io.open( "/tmp/log.lua", "a");

   for i,v in ipairs( sels ) do
      ff:write( "Value " .. i .. " is " .. v .. "\n" );
   end
   ff:close();
end
keymap['maildir']['D'] = 'debugy()';


--
-- Test our sleep primitive.
--
function sleepy()
   clear()
   sleep( 1 );
   msg( "1/2: Cleared" )
   clear();
   sleep( 1 );
   msg( "2/2: OK" );
end
keymap['global']['S'] = 'sleepy()';




--
-- Dump a list of all folders with unread messages, along with the
-- count of unread messages.
--
function dump_unread()

   -- get the current state
   mode  = global_mode()
   limit = maildir_limit();

   -- set the mode appropriately.
   maildir_limit( "new" );
   global_mode( "maildir" );

   -- get all visible folders - i.e. with unread mails.
   dirs = current_maildirs();

   offset = 0;

   -- where we log
   ff = io.open( "/tmp/unread.log", "a");

   -- Now for each one we'll open them.
   while( offset <= (count_maildirs() - 1) ) do

      -- jump to folder.
      jump_maildir_to( offset )

      -- we want to know the current folder name.
      current = current_maildir();
      ff:write( "Selected folder " .. current .. "\n" );

      global_mode( "index" );
      index_limit( "new" );
      count = count_messages()
      ff:write("\tFolder has " .. count .. " unread messages\n" );

      global_mode( "maildir" );
      offset = offset + 1;
   end

   ff:close();

   -- restore
   global_mode( mode );
   maildir_limit( limit );
end



--
-- Dump all variables we know about.
--
function dump_vars()

   -- where we log
   ff = io.open( "/tmp/vars.log", "w");

   vars = get_variables();

   for i,v in pairs( vars ) do
      ff:write( "Setting " .. i .. " has value " .. v .. "\n" );
   end
   ff:write("End\n");
   ff:close();

end


--
-- By default the keyboard handling will lookup a function to
-- execute in the keymaps we've defined above.
--
-- But it is possible to override that here, if you wish.
--
-- Returning 1 will stop further processing.  Returning 0 will
-- allow the normal handling to continue.
--
function on_key( v )
   if ( v == "x" ) then
      msg("Steve pressed :" .. v );
      return 1;
   else
      return 0;
   end
end

--
--  Steve has configured his mailserver to record the remote IP
-- of a mail submitter to the header "X-Remote-IP".
--
--  If we find such an IP in the current message then we'll blacklist
-- it from future mail attempts.
--
function mark_spam_ip()
   mode = global_mode()
   mode = string.lower( mode );
   val  = ""

   if ( string.find( mode, "message" ) ) then
      val = header( "X-Remote-IP" )
   elseif (string.find(mode, "index" ) ) then
      val = header( "X-Remote-IP" )
   else
      msg( "mark_spam_ip() not present for mode:" .. mode );
   end

   if ( val == "" ) then
      msg( "IP address not found in message." );
   else
      ff = io.open( "/etc/blacklist.d/" .. val , "a");
      ff:write( "\n" )
      ff:close();
      msg( "blacklisted IP: " .. val );
   end
end
keymap['global']['F'] = 'mark_spam_ip()'
