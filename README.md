DSS is a small screen scraping utility used to pull data from a World Community Grid
member's "Device Statistics History" page.  It uses a series of regular expressions to 
locate and save the data from the table in the HTML page to a pipe '|' seperated file. 

It uses Bash v 5.0 for its support of extended regular expressions.  It supports 
authenticating to the WCG site via the utility 'wget' based on information posted in 
the WCG forums. The specific post is listed in the code comments. 

The script requires you to set up a file with your WCG credentials that are sourced
at runtime. The script then logs into the WCG and retrieves the "Device Statistics
History" page, and runs it through a series of tests and regular expression matches
to pull the relevant data out of the page. 

