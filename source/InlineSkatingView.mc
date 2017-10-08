using Toybox.Activity as Activity;
using Toybox.ActivityRecording as Record;
using Toybox.Attention as Attention;
using Toybox.Graphics as Gfx;
using Toybox.Position as Position;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;

var session = null;

class InlineSkatingDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent) {
        if (keyEvent.getKey() == Ui.KEY_ENTER) {
            if (Toybox has :ActivityRecording) {
                if (session == null) {
                    session = Record.createSession({:name=>"Inline Skate", :sport=>30});
                }

                if (session != null) {
                    if (!session.isRecording()) {
                        session.start();
                    } else if (session.isRecording()) {
                        session.stop();
                    }

                    // Vibrate indicating the session has started/stopped
                    if (Attention has :vibrate) {
                        Attention.vibrate([
                            new Attention.VibeProfile(50, 2000) // On for two seconds
                        ]);
                    }
                }

                Ui.requestUpdate();
            }
        }
        return true;
    }

    // Only allow back when there isn't a session recording
    function onBack() {
        if (session == null || !session.isRecording()) {
            return BehaviorDelegate.onBack();
        }

        return true;
    }
}

class InlineSkatingView extends Ui.View {
    var mTimer;
    var mLastLap = 0;

    function initialize() {
        View.initialize();
        mTimer = new Timer.Timer();
    }

    //! Stop the recording if necessary
    function stopRecording() {
        if (Toybox has :ActivityRecording) {
            if (session != null) {
                session.stop();
                session.save();
                session = null;
                Ui.requestUpdate();
            }
        }
    }

    //! Load your resources here
    function onLayout(dc) {
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
        mTimer.start(method(:timerCallback), 1000, true);
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! Callback for triggering UI updates
    function timerCallback() {
        Ui.requestUpdate();
    }

    //! Format the time into hour minute second
    function formatTime(time) {
        var second = (time / 1000) % 60;
        var minute = (time / (1000 * 60)) % 60;
        var hour = (time / (1000 * 60 * 60)) % 24;

        var secondStr = second.format("%02d");
        if (hour != 0) {
            var minuteStr = minute.format("%02d");
            return Lang.format("$1$:$2$:$3$", [hour, minuteStr, secondStr]);
        } else {
            return Lang.format("$1$:$2$", [minute, secondStr]);
        }
    }

    //! Convert distance from meters to either km or miles
    function convertDistance(dist) {
        var settings = Sys.getDeviceSettings();
        if (Sys.UNIT_METRIC == settings.distanceUnits) {
            return dist / 1000.0;
        } else {
            return dist * 0.00062137;
        }
    }

    //! Convert speed (m/s) to pace in either minutes / km or minutes / miles
    function convertPace(speed) {
        var settings = Sys.getDeviceSettings();
        var baseUnit = 0;
        if (Sys.UNIT_METRIC == settings.paceUnits) {
            baseUnit = 16.6666667;
        } else {
            baseUnit = 26.8224;
        }

        var minutesPerMile = baseUnit / speed;
        var fullSeconds = (minutesPerMile - minutesPerMile.toNumber()) * 60;
        return [minutesPerMile.toNumber(), fullSeconds.toNumber().format("%02d")];
    }

    //! Update the view
    function onUpdate(dc) {
        // Set background color
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_LT_GRAY);
        dc.clear();

        var timer = "0:00";
        var distance = "0.00";
        var pace = "-:--";
        var heartRate = "   ---";

        var activity = Activity.getActivityInfo();
        var hasActivity = activity != null && session != null;

        // TODO: if paused - show paused, time, distance, done
        // TODO: if done - show save/discard

        if (hasActivity) {
            timer = formatTime(activity.timerTime);
            if (activity.elapsedDistance != null) {
                distance = convertDistance(activity.elapsedDistance).format("%0.2f");
            }
            if (activity.currentSpeed != null && activity.currentSpeed != 0) {
                pace = Lang.format("$1$:$2$", convertPace(activity.currentSpeed));
            }
            if (activity.currentHeartRate != null) {
                heartRate = "   " + activity.currentHeartRate.format("%d");
            }
        } else {
            // Show a HR even if we aren't in an activity
            var hrSample = ActivityMonitor.getHeartRateHistory(1, false).next();
            if (null != hrSample && ActivityMonitor.INVALID_HR_SAMPLE != hrSample.heartRate) {
                heartRate = "   " + hrSample.heartRate.format("%d");
            }
        }

        var TOP_BOTTOM_FONT = Gfx.FONT_SYSTEM_NUMBER_MEDIUM;
        var TOP_BOTTOM_FONT_SIZE = dc.getFontHeight(TOP_BOTTOM_FONT);

        var LABEL_FONT = Gfx.FONT_SYSTEM_XTINY;
        var LABEL_FONT_SIZE = dc.getFontHeight(LABEL_FONT);

        var VALUE_FONT = Gfx.FONT_SYSTEM_NUMBER_HOT;

        // timer
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), TOP_BOTTOM_FONT_SIZE);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, 0, TOP_BOTTOM_FONT, timer, Gfx.TEXT_JUSTIFY_CENTER);

        // distance
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, TOP_BOTTOM_FONT_SIZE, LABEL_FONT, "Distance", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, TOP_BOTTOM_FONT_SIZE, VALUE_FONT, distance, Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.drawLine(0, dc.getHeight() / 2, dc.getWidth(), dc.getHeight() / 2);

        // pace
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, LABEL_FONT, "Pace", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, VALUE_FONT, pace, Gfx.TEXT_JUSTIFY_CENTER);

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

        // If we don't have an activity, draw the GPS status circle
        if (!hasActivity) {
            var pos = Position.getInfo();
            var color = Gfx.COLOR_RED;
            if (pos.accuracy == Position.QUALITY_POOR) {
                color = Gfx.COLOR_YELLOW;
            } else if (pos.accuracy == Position.QUALITY_GOOD ||
                       pos.accuracy == Position.QUALITY_USABLE) {
                color = Gfx.COLOR_GREEN;
            }

            dc.setColor(color, color);
            dc.setPenWidth(10);
            dc.drawCircle(dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2);
            dc.setPenWidth(1);
        }
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
        mTimer.stop();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    //! Handle position events - add laps to fit file
    function onPosition(info) {
        var activity = Activity.getActivityInfo();
        if (activity != null && activity.elapsedDistance != null) {
            var distance = Math.floor(convertDistance(activity.elapsedDistance));
            if (distance != mLastLap) {
                session.addLap();

                // Vibrate indicating a lap has been completed
                if (Attention has :vibrate) {
                    Attention.vibrate([
                        new Attention.VibeProfile(50, 1000)
                    ]);
                }

                mLastLap = distance;
            }
        }
    }
}
