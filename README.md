DSS is a small screen scraping utility used to pull data from a World Community Grid
member's "Device Statistics History" page.  It uses a series of regular expressions to 
locate and save the data from the table in the HTML page to a pipe '|' seperated file. 

It uses Bash v 5.0 for its support of extended regular expressions.  It does not currently
support authenticating to the WCG site.  You will have to login to the site and access
your Device Statistics History page manually and then use the browser save function to
save the page as HTML.  This script can then process that page and extract the data. 

Eventually this script will be fully automatic and will support logging into the WCG
page. This is a work in progress.
