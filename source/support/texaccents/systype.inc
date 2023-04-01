* SYSTYPE 
* Sets new_line value according to OS
* Guido Milanese <guido.milanese@unicatt.it>
* March 2003
#################################################################
# MIT License -  Copyright (c) 2003 Guido Milanese
# See file LICENSE in this package
#################################################################
	DEFINE('SYSTYPE()os')		:(SYSTYPE_END)
SYSTYPE os = replace(host(),&UCASE,&LCASE)
UNIX	os ? ('nix' | 'nux')		:f(DOS)
	systype = char(10)		:(return)		
DOS	systype = char(13) char(10)	:s(return)
					:(freturn)	
SYSTYPE_END
* 'os' is the string returned by host(). 
* The function does not work under snobol4+, requires Spitbol or CSnobol4.
