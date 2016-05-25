This software has been released under the MIT license:

  Copyright (c) 2009 Jonas Krogsboell and Lewis R Cunningham

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

Installation:

1.  To install, extract the files to a directory
2.  change to the directory where the files exist
3.  run the install.sql file 
4.  To test the implementation, run the /testsuite/testall.sql file
5.  To learn the API, look at the files in /examples

General information about JSON is available at http://www.json.org


PLJSON is certified to work for Oracle 10 and above.
(it can work with Oracle 8,9 with some minor changes only)

Recently and for Oracle 12c and later there has been a change in naming
of types and pakages so that there is no confusion with existing or future
Oracle objects starting with 'json_'. All project public objects are now
named with prefix 'pljson_'.
For compatibility with older releases of Oracle the installation
creates synonyms with names starting with 'json_' which can still be used
with Oracle 12c but since there is no guarantee that this will be possible
in future Oracle versions the user is warned to use only names starting
with 'pljson_' in his code.
(the necessary naming changes have been made in the /testsuite files
but the /examples and /doc files contain the old names and again
the user is warned to use the new names)


