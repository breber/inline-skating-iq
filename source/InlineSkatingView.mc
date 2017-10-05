using Toybox.Activity as Activity;
using Toybox.ActivityRecording as Record;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

var session = null;

class InlineSkatingDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        if (Toybox has :ActivityRecording) {
            if (session == null || !session.isRecording()) {
                session = Record.createSession({:name=>"Inline Skate", :sport=>30});
                session.start();
                Ui.requestUpdate();
            } else if (session != null && session.isRecording()) {
                session.stop();
                session.save();
                session = null;
                Ui.requestUpdate();
            }
        }
        return true;
    }
}

class InlineSkatingView extends Ui.View {
    var mTimer;

    function initialize() {
        View.initialize();
        mTimer = new Timer.Timer();
    }

    //! Stop the recording if necessary
    function stopRecording() {
        if (Toybox has :ActivityRecording) {
            if (session != null && session.isRecording()) {
                session.stop();
                session.save();
                session = null;
                Ui.requestUpdate();
            }
        }
    }

    // Load your resources here
    function onLayout(dc) {
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        mTimer.start(method(:timerCallback), 1000, true);
    }

	function timerCallback() {
	    Ui.requestUpdate();
	}

    // Update the view
    function onUpdate(dc) {
        var timer = "0:00";
        var distance = "0.00";
        var speed = "0.0";
        var heartRate = "   ---";

        var activity = Activity.getActivityInfo();
        if (activity != null) {
            timer = activity.timerTime; // TODO: ms to minute
            if (activity.elapsedDistance != null) {
                distance = (activity.elapsedDistance * 0.00062137).format("%0.2f");
            }
            
            speed = (activity.currentSpeed * 2.23694).format("%0.1f"); // TODO: mps to mph
            if (activity.currentHeartRate != null) {
                heartRate = "   " + activity.currentHeartRate.format("%d");
            }
            
            Sys.println("\nUpdate:");
            Sys.println(activity);
            Sys.println(activity.timerTime);
            Sys.println(activity.elapsedDistance);
            Sys.println(activity.currentSpeed);
            Sys.println(activity.currentHeartRate);
        }
        
        var TOP_BOTTOM_FONT = Gfx.FONT_SYSTEM_NUMBER_MEDIUM;
        var TOP_BOTTOM_FONT_SIZE = dc.getFontHeight(TOP_BOTTOM_FONT);
        
        var LABEL_FONT = Gfx.FONT_SYSTEM_XTINY;
        var LABEL_FONT_SIZE = dc.getFontHeight(LABEL_FONT);
        
        var VALUE_FONT = Gfx.FONT_SYSTEM_NUMBER_HOT;
    
        // Set background color
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_LT_GRAY);
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), TOP_BOTTOM_FONT_SIZE);
        
        // timer
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, 0, TOP_BOTTOM_FONT, timer, Gfx.TEXT_JUSTIFY_CENTER);
        
        // distance
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, TOP_BOTTOM_FONT_SIZE, LABEL_FONT, "Distance", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, TOP_BOTTOM_FONT_SIZE, VALUE_FONT, distance, Gfx.TEXT_JUSTIFY_CENTER);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.drawLine(0, dc.getHeight() / 2, dc.getWidth(), dc.getHeight() / 2);
        
        // speed
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, LABEL_FONT, "Speed", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, VALUE_FONT, speed, Gfx.TEXT_JUSTIFY_CENTER);

        // hr
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, dc.getHeight() - TOP_BOTTOM_FONT_SIZE, dc.getWidth(), dc.getHeight());
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() - 1.15 * TOP_BOTTOM_FONT_SIZE, TOP_BOTTOM_FONT, heartRate, Gfx.TEXT_JUSTIFY_CENTER);
        
        var width = dc.getTextWidthInPixels("    ", TOP_BOTTOM_FONT);
        var radius = 5;
        var heartCenter = [dc.getWidth() / 2 - width, 7 * dc.getHeight() / 8];
        var pts = [
            [heartCenter[0] - 2 * radius, heartCenter[1]], 
            [heartCenter[0] + 2 * radius, heartCenter[1]],
            [heartCenter[0], heartCenter[1] + 2.5 * radius]];
        
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
        dc.fillCircle(heartCenter[0] - radius, heartCenter[1], radius);
        dc.fillCircle(heartCenter[0] + radius, heartCenter[1], radius);
        dc.fillPolygon(pts);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        mTimer.stop();
    }
}
