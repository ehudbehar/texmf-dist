******************************************
* 	DELETE
*	Deletes String in Text
******************************************
#################################################################
# MIT License -  Copyright (c) 2009 Guido Milanese
# See file LICENSE in this package
#################################################################
* Guido Milanese 2004
* removed error message, 2009
* <guido.milanese@unicatt.it>
* Example:
* String = delete(String,";,:.") ;* deletes any char listed in "..."
        define('delete(String,Txt)')          	:(delete_end)
delete	
	~(String ? any(Txt))  :s(freturn)
delete_loop
	String ? any(Txt) = ''      		:s(delete_loop)f(delete_return)	
delete_return	delete = String		      	:(return)			
delete_end

