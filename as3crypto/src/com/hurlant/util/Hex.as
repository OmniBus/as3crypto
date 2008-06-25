/**
 * Hex
 * 
 * Utility class to convert Hex strings to ByteArray or String types.
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.util
{
	import flash.utils.ByteArray;
	
	public class Hex
	{
		public static function toArray(hex:String):ByteArray {
			var a:ByteArray = new ByteArray;
			if (hex.length&1==1) hex="0"+hex;
			for (var i:uint=0;i<hex.length;i+=2) {
				a[i/2] = parseInt(hex.substr(i,2),16);
			}
			return a;
		}
		
		public static function fromArray(array:ByteArray):String {
			var s:String = "";
			for (var i:uint=0;i<array.length;i++) {
				s+=("0"+array[i].toString(16)).substr(-2,2);
			}
			return s;
		}
		/**
		 * Not UTF compliant, so not terribly useful beyond simple test vectors.
		 */
		public static function toString(hex:String):String {
			var s:String = "";
			if (hex.length&1==1) hex="0"+hex;
			for (var i:uint=0;i<hex.length;i+=2) {
				s+=String.fromCharCode(parseInt(hex.substr(i,2),16));
			}
			return s;
		}
		public static function fromString(str:String):String {
			var s:String = "";
			for (var i:uint=0;i<str.length;i++) {
				s+=("0"+str.charCodeAt(i).toString(16)).substr(-2,2);
			}
			return s;
		}
	}
}