package com.hurlant.crypto.tests
{
	public interface ITestHarness
	{
		function beginTestCase(name:String):void;
		function endTestCase():void;
		
		function beginTest(name:String):void;
		function passTest():void;
		function failTest(msg:String):void;
	}
}