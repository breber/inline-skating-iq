using Toybox.Application as App;
using Toybox.Position as Position;

class InlineSkatingApp extends App.AppBase {

    var recordView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        recordView.stopRecording();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function onPosition(info) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        recordView = new InlineSkatingView();
        return [ recordView, new InlineSkatingDelegate() ];
    }
}
