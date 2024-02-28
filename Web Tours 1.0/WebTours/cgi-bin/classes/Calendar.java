/* $Id: Calendar.java,v 1.1 2004-10-26 12:18:04 evgenyk Exp $ [MISCCSID] */

//  Basic calendar selection frame.
//  Kent Fitch, ITS, CSIRO  Australia (kent.fitch@its.csiro.au)  feb 96
//  You are free to use, but please retain acknowledgement

//  This frame is loaded by something which implements the CalSelect interface.
//  It is to this interface that selected dates are passed.

import java.lang.* ;
import java.util.* ;
import java.awt.*;

public class Calendar extends Frame {

    private int year, month ;
    private DayPanel dp ;
    private CalSelect owner = null ;  	// the object we callback to report date selection
					// and shutdown

    private int x,y;

    // the 'full' contructor, passed with default year/month to start showing

    public Calendar(int inyear, int inmonth, int minyear, int maxyear,  CalSelect inowner,
    		    String mytitle, int XPos, int YPos) {

	owner = inowner ;
        year = inyear + 1900;
        x = XPos;
        y = YPos;
        
        setTitle(mytitle) ;
        setLayout(new BorderLayout(10,10));
        add("North", new YearMonthPanel(this,inmonth,year,minyear + 1900,maxyear + 1900));
       	add("Center", dp = new DayPanel(this)) ;

       	SetMonth(inmonth) ;
    }

    // constructor without default year/month - we set default to current year/month

    public Calendar(CalSelect inowner, String mytitle) {

	this((new Date()).getYear(), (new Date()).getMonth()+1, (new Date()).getYear()-3,
		(new Date()).getYear()+2, inowner, mytitle, 
                -1, -1) ;
    }

    public Calendar(CalSelect inowner, String mytitle, int XPos, int YPos) {

	this((new Date()).getYear(), (new Date()).getMonth()+1, (new Date()).getYear()-3,
		(new Date()).getYear()+2, inowner, mytitle, XPos, YPos) ;
    }

    
    public void SetMonth(int inmonth) {

	month = inmonth ;
	AddDays() ;
    }

    public void SetYear(int inyear) {

	year = inyear ;
	AddDays() ;
    }

    public void AddDays() {				// draw the days for the year/month

	Button focus = dp.DrawDays(year - 1900 , month) ;
	pack() ;
        resize(preferredSize());
        if (x == -1) {
            x = Toolkit.getDefaultToolkit().getScreenSize().width/2 - size().width/2;
        } 
        if (y == -1) {
            y = Toolkit.getDefaultToolkit().getScreenSize().height/2 - size().height/2;
        } 
        move(x,y);
	show();
        toFront();

	// the DrawDays method may return a button to be given the focus - if it does, then
	// we seem to need to set the focus to that button *after* the pack/resize/show sequence
	// to reliable cause the focus to be visible to the user

	if (focus != null)  focus.requestFocus() ;

    }

    public void DateSelect(int day) {			// notify the date selected
	if (owner != null) owner.DateSelected(year, month, day) ;
	else System.out.println("No one to notify...") ;
    }
    

    public boolean action(Event e, Object arg) {
	if (e.target instanceof Button) {
		try {
			int date = Integer.parseInt((String)
				((Button) e.target).getLabel()) ;
                        DateSelect(date) ;
		}
		catch (Exception ex) { return false ; } ;

	}
        return false;
    }

    public boolean handleEvent(Event e) {
	if (e.id == Event.WINDOW_DESTROY) {
                if (owner != null) owner.ShutDown() ;  // tell them we are gone...
                dispose();
	        return true;
        }
	
	return false;
    }

}


// The DateInfo class is just used as a 'placeholder' for some nice day and month name constants
// This could be done externally to this source file by making DateInfo an interface which
// we could then implement.  (Possibly a neater, more maintained approach!)

class DateInfo {

    public static final String dayname [] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"} ;
    public static final String monthname [] = {"January", "February", "March", "April", "May",
			"June", "July", "August", "September", "October",
			"November", "December" } ;

}


// The DayPanel class represents the days in a particular month.  It builds a grid with a button
// for each day in the month.

class DayPanel extends Panel {

    int year, month ;

    private Panel DayTable = null ;
    private Label MonthLabel = null ;
    private Calendar CalPtr  = null ;

    public DayPanel() {
        this(null);
    }

    
    public DayPanel(Calendar cal) {
        CalPtr = cal;
  	Panel DayHeaders = new Panel() ;

	// In this constructor, we just add the day names to the new panel.  The actual
	// buttons get added by the Drawdays method.

        DayHeaders.setLayout(new GridLayout(0,7));
        
   	for (int i=0;i<7;i++) 
		DayHeaders.add (MakeDaynameHeaderLabel(i)) ;
    
	setLayout(new BorderLayout()) ;
	add("North", DayHeaders) ;
    }

   private Label MakeDaynameHeaderLabel(int day) {

	Label l =  new Label(DateInfo.dayname[day], Label.CENTER)   ;
	l.setFont(new Font("Courier", Font.BOLD, 12)) ;
	return (l) ;
    
    }

    // DrawDays adds a button for each day in the chosen month.  We return the button
    // to be given focus (the current day if the year/month is the current year/month).

    public Button DrawDays(int year, int month) {
	
	if (DayTable != null) remove(DayTable) ;
	if (MonthLabel != null) remove(MonthLabel) ;

	DayTable = new Panel() ;
        DayTable.setLayout(new GridLayout(0,7));
        
   	Date d = new Date(year, month - 1, 1) ; // first day of month
	add("South", MonthLabel = new Label(DateInfo.monthname[month-1] + " " + (year+1900), Label.CENTER)) ;
 
	int day = d.getDay() ;
	d = new Date() ;
	int matchday ;
	if ((d.getYear() == year) && (d.getMonth() == (month - 1)))  matchday = d.getDate() ;
	else matchday = -1 ;
	
	// fill with blanks up to the first day of the month

	for (int i=0; i<day;i++)  DayTable.add(new Label(" ")) ;

	// work out when the month actually ends...

	int nyear, nmonth ;
	if (month == 12) {		// jump year
		nyear = year + 1 ; nmonth = 0 ;
	}
	else {
		nyear = year ; nmonth = month ;
	}
       	Date limitdate = new Date(nyear, nmonth, 1) ;

        // now do all the days of the month...
	
	Button FocusButton = null ;
	Button b ;

	for (int i=1;i<32;i++) {
		d = new Date(year, month - 1, i) ;
		if (! d.before(limitdate)) break ;
		DayTable.add(b = new Button(Integer.toString(i))) ; //, Label.RIGHT)) ;
		if (i == matchday) FocusButton = b ;
	}

	add("Center", DayTable) ;

	return FocusButton ;
    }


    public boolean action(Event e, Object arg) {
	if (e.target instanceof Button) {
                if (CalPtr != null)
		try {
			int date = Integer.parseInt((String)
				((Button) e.target).getLabel()) ;
                        CalPtr.DateSelect(date) ;
		}
		catch (Exception ex) { return false ; } ;

	}
        return false;
    }

  
}


class YearMonthPanel extends Panel {
    
    Calendar calendar;
    
    public YearMonthPanel(Calendar caller, int mymonth, int myyear, int minyear, int maxyear) {

	// we need to remember the panel who called us, because they coordinate updating the
	// year and month and redrawing the days in the month when the user selects a new
	// year or month

	calendar = caller;

	setLayout(new FlowLayout()) ;

	// create a YearPanel - this will hold the Year label and the year choice list

	Panel YearPanel = new Panel() ;
	YearPanel.setLayout(new BorderLayout(5,5)) ;

	// add the years to a choice list

	Choice y = new Choice() ;

	for (int i=minyear;i<=maxyear;i++)
		y.addItem("" + i) ;

	y.select("" + myyear) ;		// default to the required year
	
	YearPanel.add("Center", y) ;
	YearPanel.add("West", new Label("Year: ")) ;
	add(YearPanel) ;

	// create a MonthPanel - this will hold the Month label and the month choice list

	Panel MonthPanel = new Panel() ;
	MonthPanel.setLayout(new BorderLayout(5,5)) ;
	
	// add the months to a choice list

	Choice m = new Choice() ;
	for (int i=0;i<12;i++)
		m.addItem(DateInfo.monthname[i]) ;

	m.select(mymonth-1) ;		// default to the required month

	MonthPanel.add("Center",m) ;
	MonthPanel.add("West", new Label("Month: ")) ;

	add(MonthPanel) ;

    }

    public boolean action(Event e, Object arg) {
 
	if (e.target instanceof Choice) {

		// they either selected a month or a year - fortuneately, there is no
		// ambiguity...

		for (int i=0;i<12;i++) {
			if (DateInfo.monthname[i].equals(e.arg)) {
				calendar.SetMonth(i+1) ;
				return true ;
			}
		}

		// wasnt a month - try a year...

		int year = 0 ;
		try {
			year = Integer.parseInt((String) e.arg) ;
		}
		catch (Exception ex) { return false ; } ;
		calendar.SetYear(year) ;
	}
	else { /*System.out.println("target="  + e.target) ; */ }
	
        return false;

    }
}

