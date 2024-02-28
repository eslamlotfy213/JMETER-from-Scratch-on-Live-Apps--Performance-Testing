/* $Id: FormDateUpdate.java,v 1.1 2004-10-26 12:18:04 evgenyk Exp $ [MISCCSID] */
import java.awt.*;
import java.applet.*;
import netscape.javascript.*;

public class FormDateUpdate extends Applet implements CalSelect {
    
    public boolean inAnApplet = true;  // our caller tells us whether we're an Applet...

    // ........................ Parameter Name 
    String   CalTitle;       // [CalenderTitle] Calender Title
    String   HtmlFormIndex;  // [HtmlFormIndex]
    String   HtmlEditIndex;  // [HtmlEditIndex]
    String   BtnLabel;       // [Label]
    int      AutoClose;      // [AutoClose]
    int      XPos, YPos;

    Calendar Cal = null ;
    Button   Btn;

    public void init() {
        // Get Parameters.....................................................
        // --> CalenderTitle
        CalTitle = this.getParameter("CalenderTitle");
        // --> HtmlFormIndex
        HtmlFormIndex = this.getParameter("HtmlFormIndex");
        // --> HtmlEditIndex
        HtmlEditIndex = this.getParameter("HtmlEditIndex");
        // --> Label
        BtnLabel = this.getParameter("Label");
        if (BtnLabel == "") {
            BtnLabel = "...";
        }
        // --> AutoClose
        try {
            AutoClose = Integer.parseInt(this.getParameter("AutoClose"));
        } catch (Exception e) {
            AutoClose = 0;
        }
        // --> X
        try {
            XPos = Integer.parseInt(this.getParameter("X"));
        } catch (Exception e) {
            XPos = -1; // Center
        }
        // --> Y
        try {
            YPos = Integer.parseInt(this.getParameter("Y"));
        } catch (Exception e) {
            YPos = -1; // Center
        }

        
        // Create the Button on white background. 
        add("Center",Btn = new Button(BtnLabel));        
        setBackground(Color.white);
    }

    public void DateSelected(int year, int month, int date) {
        try {
           String   newDate;
           if (month > 9) {
              newDate = new String(month + "/" + date + "/" + year);
           } else {
              newDate = new String("0" + month + "/" + date + "/" + year);
           }

           String var = "document.forms[" + HtmlFormIndex + "]" +
                                           ".elements[" + HtmlEditIndex + "]";
           String cmd = var + ".value = '" + newDate + "';";
           System.err.println(cmd);

           JSObject win = (JSObject) JSObject.getWindow(this);
           win.eval(cmd);
//           JSObject HTMLInputText = (JSObject) win.eval(var ".value);
//           HTMLInputText.setMember("value", newDate);
        } catch (Exception e) {
           System.err.println("Failed to update form's field!");
           System.err.println("   " + e.toString());
        }

        if (AutoClose != 0) {
            try {
                Cal.dispose();       
            } catch (Exception e) {
            }
            Btn.enable();
            Cal = null;
        }
    }

    public void ShutDown() {
        Btn.enable();
        Cal = null;
    }

    public boolean action(Event evt, Object arg) {
        if (evt.target == Btn) {
           if (Cal == null) {
               Cal = new Calendar(this, CalTitle,XPos, YPos) ;
               Btn.disable();
           }
        }
	return false;
    }
    
}

