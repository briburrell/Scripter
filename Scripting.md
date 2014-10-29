
Scripter API Global Variables:

s_args
    A string of all the user arguments.

s_arg
    A string array of user arguments.


Scripter API Core Functions:

s_db_get(<name>)
    Obtain a stored value from the databank.

s_db_set(<name>, <value>)
    Set a value to be stored in the databank.

s_call(<func>[, <args>])
    Call another Scripter function with optional arguments.

s_loc()
    The current location of the character.
    Note: Use s_pr_loc() and s_pr_cord() to print location information.

s_time()
    A timestamp representing the current date and time.
    Note: Use s_pr_time() and s_pr_date() to print time information.

s_print(<text>)
    Print text to the chat window.

s_pr_clr(<text>)
    Set the text color.

s_pr_time([<time>])
    Print the time of a timestamp.

s_pr_date([<time>])
    Print the date and time of a timestamp.

s_pr_cord([<loc>])
    Print the grid X and Y coordinates in meters.
    Note: If no location is specified then the current location is used.

s_pr_loc([<loc>])
    Print information about the zone, sub-zone, and coordinates.
    Note: If no location is specified then the current location is used.


Scripter Data Storage:

The Scripter API provides persistent storage for data variables. Any type of value can be stored. 

The "s_set(<name>, <value>)" will store the <value> into the Scripter DataBlock object with the token <name>. The value will remain until it is overwritten or the value is set to "nil". 

The "s_get(<name>)" will retrieve a value from the Scripter DataBlock object with the token <name>. If no token exists then a blank string will be returned.

The LibDataBlock ESO addon library is included to allow external addon access to the data stored. This provides access to utilize data stored by Scripter functions from an external addon, and like-wise a mechanism for other addons to store data that can be retrieved in a Scripter function.

The Scripter DataBlock Object can be directly referenced from the LibDataBlock library by calling "LibDataBlock:GetDataObjectByName('Scripter')".



