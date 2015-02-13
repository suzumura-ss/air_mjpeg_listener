package info.smoche
{
	/**
	 * ...
	 * @author suzumura_ss
	 */
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	public class MJPEGLoader
	{
		protected var _socket:Socket = null;
		protected var _onFrame:Function = null;
		protected var _onError:Function = null;
		protected var _onClose:Function = null;
		protected var _chunk:ByteArray = new ByteArray();
		protected var _header:ByteArray = new ByteArray();
		protected var _lastByte:uint = 0;
		protected var _timer:Timer = null;
		
		public function MJPEGLoader(socket:Socket, onFrame_:Function, onClose_:Function, onError_:Function)
		{
			_socket = socket;
			_onFrame = onFrame_;
			_onClose = onClose_;
			_onError = onError_;
			
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onData);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			
			_timer = new Timer(1000, 0);
			_timer.addEventListener(TimerEvent.TIMER, function(e:Event):void {
				if (!_socket.connected) {
					onClose(e);
				}
			});
			_timer.start();
		}
		
		protected function onError(e:Event):void
		{
			_onError(this, e);
			_socket.close();
			onClose(e);
		}
		
		protected function onClose(e:Event):void
		{
			_timer.stop();
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onData);
			_socket.removeEventListener(Event.CLOSE, onClose);
			_onClose(this);
		}
		
		protected function onData(e:ProgressEvent):void
		{
			var pos:Number = _chunk.length;
			_socket.readBytes(_chunk, _chunk.length, 0);
			_chunk.position = pos;
			
			var splitData:Function = function(offset:int):ByteArray
			{
				var d:ByteArray = new ByteArray();
				d.writeBytes(_chunk, 0, _chunk.position - offset);
				d.position = 0;
				var x:ByteArray = new ByteArray();
				x.writeBytes(_chunk, _chunk.position - offset);
				_chunk.clear();
				_chunk.writeBytes(x);
				_chunk.position = 0;
				return d;
			}
			
			while (_chunk.position < _chunk.length)
			{
				var b:uint = _chunk.readUnsignedByte();
				if (_lastByte == 0xff && b == 0xd8 /* SOI */ && _chunk.position > 2) {
					_header = splitData(2);
					_lastByte = 0;
				} else if (_lastByte == 0xff && b == 0xd9 /* EOI */) {
					var img:ByteArray = splitData(0);
					_onFrame(_header, img);
					_header.clear(); 
					_lastByte = 0;
				} else {
					_lastByte = b;
				}
			}
		}
	}
}
