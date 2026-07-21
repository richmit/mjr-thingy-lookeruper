# mjr-thingy-lookeruper

The mjr-thingy-lookeruper Emacs package provides an extensible way to
identify and lookup things in a buffer.  For example, if the cursor is
near an ISBN number then mjr-thingy-lookeruper can recognize the ISBN
number and look the book up.

The primary entry point is the function `mjr-thingy-lookeruper'.

Methods for looking things up are defined in `mjr-thingy-lookeruper-methods'
This variable may be customized allowing the user to add new methods to look up things.

Several example methods are provided in `mjr-thingy-lookeruper-built-in-methods'.
 - UNIX man pages
 - Operating group IDs, group names, user IDs, user names
 - DNS queries
 - Dictionary words
 - Data about files
 - URLs
 - Internet search queries (google, bing, & ebay)
 - Symbols in several languages (Emacs lisp, Common Lisp, R, Perl, Python, Ruby, Julia, C, C++, Matlab, CMake)
 - & & C++ header files
 - ST Micro STM32 parts
 - Books via ISBN

Some utilities related to the variables mentioned above:
 - `mjr-thingy-lookeruper-get-built-in'
 - `mjr-thingy-lookeruper-get-method'
 - `mjr-thingy-lookeruper-delete-method'
 - `mjr-thingy-lookeruper-add-method'

I bind the function `mjr-thingy-lookeruper' to "C-c l" -- i.e. "l" for "Lookup":

     (keymap-global-set "C-c l" 'mjr-thingy-lookeruper)
     
The easiest way to install mjr-thingy-lookeruper is to pull it directly
from github:

     (package-vc-install (list 'mjr-thingy-lookeruper
                          :url "https://github.com/richmit/mjr-thingy-lookeruper"
                          :rev 'newest))
                        
