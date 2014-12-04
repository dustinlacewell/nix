import sdl

from src/controller import Controller

type
  Scene* = object of RootObj
    ctl*: ref Controller
    manager*: ref SceneManager

  SceneManager* = object of RootObj
    ctl*: ref Controller
    scene*: ref Scene

method enter*(self: ref Scene) = 
  discard

method leave*(self: ref Scene) = 
  discard

method key_down*(self: ref Scene, key: TKey, mods: TMod) = 
  discard

method mouse_down*(self: ref Scene, event: PMouseButtonEvent) =
  discard

method mouse_motion*(self: ref Scene, event: PMouseMotionEvent) =
  discard

method update*(self: ref Scene) = 
  discard

method draw*(self: ref Scene) = 
  discard

method set_scene*(self: ref SceneManager, scene: ref Scene) =
  self.scene.leave()
  self.scene = scene
  self.scene.manager = self
  self.scene.ctl = self.ctl
  scene.enter()

proc newSceneManager*(ctl: ref Controller, first_scene: ref Scene): ref SceneManager =
  result = new(SceneManager)
  result.ctl = ctl
  result.set_scene(first_scene)
