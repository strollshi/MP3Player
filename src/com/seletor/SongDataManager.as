package com.seletor
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	public class SongDataManager extends EventDispatcher
	{
		private static var _Instance:SongDataManager;
		public static function get instance():SongDataManager {
			if(!_Instance){
				_Instance = new SongDataManager();
			}
			return _Instance;
		}
		
		public function SongDataManager(target:IEventDispatcher=null)
		{
			super(target);
			init();
		}
		
		private var files:Array = [];
		private var _track:Array = [];
		private static var _TotalNum:int;
		
		public function get track():Array {
			return _track;
		}
		
		private function init():void {
			var targetFile:File = new File("app:/resource/");
			var track:Array = targetFile.getDirectoryListing();
			_TotalNum = track.length;
			for each(var file:File in track){
				files.push(file);
			}
			if(_TotalNum>0)LoadMP3(track[0]);
		}
		
		private function setSongInfo(snd:Sound):void {
			var info:SongData = new SongData();
			info.songName = snd.id3.songName;
			info.desc = snd.id3.comment
			info.time = snd.id3.year;
			info.data = snd;
			info.id = snd.id3.genre
			_track.push(info);
		}
		
		
		/********************
		 * mp3加载
		 * *****************/
		
		private var _targetSnd:Sound;
		private var _sndChannel:SoundChannel;
		private var _curIndex:int;
		private var _errorCounter:int=0;
		public function LoadMP3(index:int):void {
			_curIndex = index;
			_targetSnd = new Sound();
			var targetFile:File = files[index];
			var req:URLRequest = new URLRequest(targetFile.url);
			_targetSnd.addEventListener(Event.COMPLETE,onLoadSndComplete);
			_targetSnd.addEventListener(IOErrorEvent.IO_ERROR , onLoadSndFail);
			_targetSnd.load(req);
		}
		
		protected function onLoadSndFail(event:IOErrorEvent):void
		{
			// TODO Auto-generated method stub
			_errorCounter++;
			if(_errorCounter<3){
				LoadMP3(_curIndex);
			}else{
				_errorCounter = 0;
				trace("load fail =========== ");
				this.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
				LoadMP3(_curIndex+1);
			}
		}
		
		protected function onLoadSndComplete(event:Event):void
		{
			// TODO Auto-generated method stub
			trace("load success")
			if(_curIndex<_TotalNum-1){
				setSongInfo(_targetSnd);
				LoadMP3(_curIndex+1);
			}else{
				_curIndex = 0;
				_targetSnd = _track[_curIndex].data;
				playMusic(0);
				
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		
		
		
		/*****************
		 * 控制器调用的API
		 * **************/
		
		private var _pos:Number;
		private var _vol:Number = 1;
		
		public function setVol(vol:Number):void {
			_vol = vol;
			var sndTrans:SoundTransform = new SoundTransform(_vol);
			_sndChannel.soundTransform = sndTrans;
		}
		
		public function pause():void {
			_sndChannel.stop();
			_pos = _sndChannel.position;
		}
		
		public function stop():void {
			_sndChannel.stop();
			_targetSnd.close();
			_sndChannel = null;
			_targetSnd = null;
		}
		
		public function play():void {
			if(_sndChannel&&_targetSnd){
				playMusic(_pos);
			}
		}
		
		public function playNext():void {
			var num:int = _TotalNum-1
			if(_curIndex==num){
				_curIndex=0;
			}else{
				_curIndex++;
			}
			_targetSnd = _track[_curIndex].data;
			playMusic(0);
		}
		public function playLast():void {
			var num:int = _TotalNum-1
			if(_curIndex==0){
				_curIndex=_track.length-1;
			}else{
				_curIndex--;
			}
			_targetSnd = _track[_curIndex].data;
			playMusic(0);
		}
		
		private function playMusic(pos:Number):void {
			_pos = pos;
			if(_sndChannel){
				_sndChannel.stop();
			}
			_sndChannel = _targetSnd.play(_pos,0,new SoundTransform(_vol,0));
			_sndChannel.addEventListener(Event.SOUND_COMPLETE,onCompleteSnd);
		}
		protected function onCompleteSnd(event:Event):void
		{
			// TODO Auto-generated method stub
			_sndChannel.removeEventListener(Event.SOUND_COMPLETE,onCompleteSnd);
			playNext();
		}
	}
}