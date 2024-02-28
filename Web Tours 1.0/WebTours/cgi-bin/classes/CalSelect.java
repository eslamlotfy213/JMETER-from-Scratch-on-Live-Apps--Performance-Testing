/* $Id: CalSelect.java,v 1.1 2004-10-26 12:18:03 evgenyk Exp $ [MISCCSID] */
//  The calendar selection interface.
//  Kent Fitch, ITS, CSIRO  Australia (kent.fitch@its.csiro.au)  feb 96
//  You are free to use, but please retain acknowledgement

//  This interface defines how the Calendar selection frame should pass
//  the date selected.

interface CalSelect {
	public void DateSelected(int year, int month, int date) ;
	public void ShutDown() ;
}
