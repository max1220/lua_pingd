lua-pingd
---------

## what is this?

This is a program that reads the output of the ping command, parses it, and provides multiple output options.

It actually uses the ping commands as it's "event loop", requiring very little CPU usage.



## installation

just clone the git repository or download & unpack the .zip.



## usage

To start the program, run `./pingd`(Does not fork to the background itself).
By default, all output formats are enabled, so you could already use the JSONs
or view the .svg graphs.

To view the HTML page, you'll need a HTTP server that supports the correct mime-type for .svg files.
The busybox httpd does not do this by default, but can be configured to do so.
The included `./start_httpd.sh` starts the busybox httpd with such a config.

For local testing you can open `html/index.html` in a browser



## configuration
See the commented default configuration.



## screenshot

This screenshot is of the rendered page.

![rendered HTML page screenshot](https://raw.githubusercontent.com/max1220/lua_pingd/master/screenshot.png)



This is just an example generated SVG graph:
![example SVG graph](https://raw.githubusercontent.com/max1220/lua_pingd/master/example_svg.svg?sanitize=true)
