/**
 * Random
 * 
 * An ActionScript 3 implementation of a Random Number Generator
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The jsbn library, Copyright (c) 2003-2005 Tom Wu
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.prng
{
	import flash.utils.ByteArray;
	import com.hurlant.util.Memory;
	
	public class Random
	{
		private var state:IPRNG;
		private var ready:Boolean = false;
		private var pool:ByteArray;
		private var psize:int;
		private var pptr:int;
		
		public function Random(prng:Class = null) {
			if (prng==null) prng = ARC4;
			state = new prng as IPRNG;
			psize= state.getPoolSize();
			pool = new ByteArray;
			pptr = 0;
			while (pptr <psize) {
				var t:uint = 65536*Math.random();
				pool[pptr++] = t >>> 8;
				pool[pptr++] = t&255;
			}
			pptr=0;
			seed();
		}
		
		public function seed(x:int = 0):void {
			if (x==0) {
				x = new Date().getTime();
			}
			pool[pptr++] ^= x & 255;
			pool[pptr++] ^= (x>>8)&255;
			pool[pptr++] ^= (x>>16)&255;
			pool[pptr++] ^= (x>>24)&255;
			pptr %= psize;
		}
		
		public function nextBytes(buffer:ByteArray, length:int):void {
			while (length--) {
				buffer.writeByte(nextByte());
			}
		}
		public function nextByte():int {
			if (!ready) {
				seed();
				state.init(pool);
				pool.length = 0;
				pptr = 0;
				ready = true;
			}
			return state.next();
		}
		public function dispose():void {
			for (var i:uint=0;i<pool.length;i++) {
				pool[i] = Math.random()*256;
			}
			pool.length=0;
			pool = null;
			state.dispose();
			state = null;
			psize = 0;
			pptr = 0;
			Memory.gc();
		}
		public function toString():String {
			return "random-"+state.toString();
		}
	}
}
