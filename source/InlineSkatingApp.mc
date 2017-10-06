using Toybox.Application as App;

class InlineSkatingApp extends App.AppBase {

    var recordView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        recordView.stopRecording();
    }

    // Return the initial view of your application here
    function getInitialView() {
        recordView = new InlineSkatingView();
        return [ recordView, new InlineSkatingDelegate() ];
    }
}
