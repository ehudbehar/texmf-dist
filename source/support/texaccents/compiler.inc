* Compiler.inc
* Gregory White <glwhite@netconnect.com.au>
* Posted to the Snobol list (March 2003)
* and adapted as a function

	DEFINE('COMPILER()')			:(COMPILER_END)
compiler
IDprocessor    :($('COMPILER' SIZE(DATE())))
COMPILER17 compiler 	= 'SPITBOL' 	:(return)
COMPILER19 compiler	= 'CSNOBOL4'	:(return)
COMPILER20 compiler	= 'SNOBOL4+'  	:(return)
compiler_end
* Uses the different size of DATE() to detect the compiler used

