package lime.graphics;


import lime.app.Application;
import lime.app.Event;
import lime.graphics.opengl.GL;
import lime.graphics.GLRenderContext;
import lime.system.System;
import lime.ui.Window;

#if js
import js.html.webgl.RenderingContext;
#elseif flash
import flash.Lib;
#end


@:access(lime.graphics.opengl.GL) @:access(lime.app.Application) @:allow(lime.app.Application)
class Renderer {
	
	
	public static var onRender = new Event<RenderContext->Void> ();
	
	private static var eventInfo = new RenderEventInfo ();
	private static var registered:Bool;
	
	public var context:RenderContext;
	public var handle:Dynamic;
	
	private var window:Window;
	
	
	public function new (window:Window) {
		
		this.window = window;
		this.window.currentRenderer = this;
		
		if (!registered) {
			
			registered = true;
			
			#if (cpp || neko)
			lime_render_event_manager_register (dispatch, eventInfo);
			#end
			
		}
		
	}
	
	
	public function create ():Void {
		
		#if js
		
		if (window.div != null) {
			
			context = DOM (window.div);
			
		} else if (window.canvas != null) {
			
			#if canvas
			
			var webgl = null;
			
			#else
			
			var webgl:RenderingContext = cast window.canvas.getContext ("webgl");
			
			if (webgl == null) {
				
				webgl = cast window.canvas.getContext ("experimental-webgl");
				
			}
			
			#end
			
			if (webgl == null) {
				
				context = CANVAS (cast window.canvas.getContext ("2d"));
				
			} else {
				
				#if debug
				webgl = untyped WebGLDebugUtils.makeDebugContext (webgl);
				#end
				
				GL.context = webgl;
				#if js
				context = OPENGL (cast GL.context);
				#else
				context = OPENGL (new GLRenderContext ());
				#end
				
			}
			
		}
		
		#elseif (cpp || neko)
		
		handle = lime_renderer_create (window.handle);
		context = OPENGL (new GLRenderContext ());
		
		#elseif flash
		
		context = FLASH (Lib.current);
		
		#end
		
	}
	
	
	private static function dispatch ():Void {
		
		for (window in Application.instance.windows) {
			
			if (window.currentRenderer != null) {
				
				var context = window.currentRenderer.context;
				
				Application.instance.render (context);
				onRender.dispatch (context);
				
				window.currentRenderer.flip ();
				
			}
			
		}
		
		#if (js && stats)
		Application.instance.windows[0].stats.end ();
		#end
		
	}
	
	
	public function flip ():Void {
		
		#if (cpp || neko)
		lime_renderer_flip (handle);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	#end
	
	
}


private class RenderEventInfo {
	
	
	public var context:RenderContext;
	public var type:RenderEventType;
	
	
	public function new (type:RenderEventType = null, context:RenderContext = null) {
		
		this.type = type;
		this.context = context;
		
	}
	
	
	public function clone ():RenderEventInfo {
		
		return new RenderEventInfo (type, context);
		
	}
	
	
}


@:enum private abstract RenderEventType(Int) {
	
	var RENDER = 0;
	
}