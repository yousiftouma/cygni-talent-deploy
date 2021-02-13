# Set up server

We will assume a clean ubuntu server install with access to root login via ssh. From this starting point, we need to set up our server to run our application.

- Create a user without root privileges.
- Set up firewall, allow ssh and http traffic
- Install any dependencies

It can be advantageous to script these steps if we ever need to redo this. When scripting, we should try to make the script idempotent, meaning we can run the script repeatedly without changing the end result.
