* NEWLINE
* Checks OS and compiler type to set newline
* Part of this function uses code posted by
* Gregory White <glwhite@netconnect.com.au>
* on the Snobol list in March 2003
* Guido Milanese <guido.milanese@unicatt.it>
#################################################################
# MIT License -  Copyright (c) 2003 Guido Milanese
# See file LICENSE in this package
#################################################################
	define('newline()compiler_type')	
-include "compiler.inc"
-include "systype.inc"
					:(newline_end)
newline					
* Compiler being used. If it is Snobol4+, that does not have
* the HOST() function, assumes that the newline is Dos type
snobol4	(compiler_type = compiler()) ? "SNOBOL4+"   	:f(other)	
	newline	= char(13) char(10)			:(return)
* otherwise finds through HOST the OS type and sets newline
* accordingly
other	newline = systype()  				:(return)
newline_end
