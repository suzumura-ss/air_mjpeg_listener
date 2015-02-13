package info.smoche
{
	/**
	 * ...
	 * @author suzumura_ss
	 */
	import flash.events.Event;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	
	public class MJPEGLoaderServer
	{
		protected var _bindAddress:String = null;
		protected var _port:uint;
		protected var _onConnect:Function = null;
		protected var _onFrame:Function = null;
		protected var _onError:Function = null;
		protected var _onClose:Function = null;
		protected var _serverSocket:ServerSocket;
		protected var _clients:Vector.<MJPEGLoader> = new Vector.<MJPEGLoader>;
		
		public function MJPEGLoaderServer(bindAddress:String, port:uint, onConnect_:Function, onFrame_:Function, onClose_:Function, onError_:Function)
		{
			_bindAddress = bindAddress;
			_port = port;
			_onConnect = onConnect_;
			_onFrame = onFrame_;
			_onClose = onClose_;
			_onError = onError_;
		}
		
		public function start():void
		{
			_serverSocket = new ServerSocket();
			_serverSocket.bind(_port, _bindAddress);
			_serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
			_serverSocket.addEventListener(Event.CLOSE, onClose);
			_serverSocket.listen();
		}
		
		protected function onConnect(e:ServerSocketConnectEvent):void
		{
			var socket:Socket = e.socket;
			var loader:MJPEGLoader = new MJPEGLoader(socket, _onFrame, onClientClose, onClientError);
			_clients.push(loader);
			if (_onConnect != null) {
				_onConnect(loader);
			}
		}
		
		protected function onClose(e:Event):void
		{
			trace("onClose", e);
		}
		
		protected function onClientClose(loader:MJPEGLoader):void
		{
			var i:Number = _clients.indexOf(loader);
			if (i >= 0) {
				_clients.splice(i, 1);
				if (_onClose != null) {
					_onClose(loader);
				}
			}
		}
		
		protected function onClientError(loader:MJPEGLoader, e:Event):void
		{
			trace(loader, e);
			if (_onError != null) {
				_onError(loader, e);
			}
		}
	}
}
