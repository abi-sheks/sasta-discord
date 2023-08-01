## Register a user
Use the command `register username password` to register a new user on the platform.
## Login
Use `login username password` to login as an existing user. Note that only one user can be logged in during a session.
## Logout
Use `logout username password` to logout of the session.
## Creating a server
Use `create-server server_name username` to create a server. `username` gains admin privileges to the server.
## Adding channels to a server
Use `add-channel channel_name channel_type server_name user_name` to add a new channel to a server. The channel type can be general or announcement.
## Joining a server
Use `join-server user_name server_name` to join a server, (or essentially add `user_name` to `server_name`).
## Sending a message
Use `send-message sender_name server_name channel_name message` to send a message in the `channel_name` channel of `server_name`.
## Showing messages in a channel
Use `show-message server_name` to display all the messages in `server_name`.
## DMing another user
Use `dm-message sender_name recipient_name message` to send a message from `sender_name` to `recipient_name`.
## Displaying DMs
Use `show-dms sender_name recipient_name` to show the message history between the two parties.