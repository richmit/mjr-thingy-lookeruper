# mjr-thingy-lookeruper

The mjr-thingy-lookeruper Emacs package provides an extensible way to
identify and lookup things in a buffer.  For example, if the cursor is
near an ISBN number then mjr-thingy-lookeruper can recognize the ISBN
number and look the book up.

The primary entry point is the function `mjr-thingy-lookeruper' which
I bind the function `mjr-thingy-lookeruper' to "C-c l" -- i.e. "l" for
"Lookup":

     (keymap-global-set "C-c l" 'mjr-thingy-lookeruper)

Several example lookup methods are provided in variable
`mjr-thingy-lookeruper-built-in-methods':

 - UNIX man pages
 - Operating group IDs, group names, user IDs, user names
 - DNS queries
 - Dictionary words
 - Data about files
 - URLs
 - Internet search queries (google, bing, & ebay)
 - Symbols in several languages (Emacs lisp, Common Lisp, R, 
   Perl, Python, Ruby, Julia, C, C++, Matlab, CMake)
 - C & C++ header files
 - ST Micro STM32 parts
 - Books via ISBN

The methods for looking things up are defined in the variable
`mjr-thingy-lookeruper-methods'.  By default this variable is set to
the contents of `mjr-thingy-lookeruper-built-in-methods'.  The
variable may be customizing `mjr-thingy-lookeruper-methods'.

Some utilities related to the variables mentioned above:
 - `mjr-thingy-lookeruper-get-built-in'
 - `mjr-thingy-lookeruper-get-method'
 - `mjr-thingy-lookeruper-delete-method'
 - `mjr-thingy-lookeruper-add-method'
     
The easiest way to install mjr-thingy-lookeruper is to pull it directly
from github:

     (package-vc-install (list 'mjr-thingy-lookeruper
                          :url "https://github.com/richmit/mjr-thingy-lookeruper"
                          :rev 'newest))
                        
Be sure to install and load any packages  required by any of the methods
included on `mjr-thingy-lookeruper-methods'.  For example several of the
built in methods require things like: `thingatpt' & `browse-url'.

