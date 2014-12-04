from src/app import App, init, run
import src/scene

type WindowScene = object of Scene

var window_scene = new(WindowScene)
var window_app = new(App)
window_app.init(window_scene, 200, 200, "Window Example")
window_app.run()
