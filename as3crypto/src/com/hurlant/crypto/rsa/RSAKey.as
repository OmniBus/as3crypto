/**
 * RSAKey
 * 
 * An ActionScript 3 implementation of RSA + PKCS#1 (light version)
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 		The jsbn library, Copyright (c) 2003-2005 Tom Wu
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.rsa
{
	import com.hurlant.crypto.prng.Random;
	import com.hurlant.util.Memory;
	
	import flash.utils.ByteArray;
	
	/**
	 * Current limitations:
	 * exponent must be smaller than 2^32.
	 * (fairly easy to fix. port jsbn2.js over.)
	 */
	public class RSAKey
	{
		private var exponent:BigInteger;
		private var modulus:BigInteger;
		
		public function RSAKey(exponent:BigInteger, modulus:BigInteger) {
			this.exponent = exponent;
			this.modulus = modulus;
		}
		
		public static function parseKey(E:String, M:String):RSAKey {
			return new RSAKey(new BigInteger(E,16), new BigInteger(M, 16));
		}
		
		public function encrypt(src:ByteArray, dst:ByteArray, length:uint):void {
			doRSA(src, dst, length, pkcs1pad);
		}
		public function decrypt(src:ByteArray, dst:ByteArray, length:uint):void {
			doRSA(src, dst, length, rawpad); // XXX fix me.
		}
		public function getBlockSize():uint {
			return modulus.bitLength()/8;
		}
		public function dispose():void {
			exponent.dispose();
			modulus.dispose();
			exponent = null;
			modulus = null;
			Memory.gc();
		}
		protected function doRSA(src:ByteArray, dst:ByteArray, length:uint, pad:Function):void {
			// convert src to BigInteger
			if (src.position >= src.length) {
				src.position = 0;
			}
			var bl:uint = getBlockSize();
			var end:int = src.position + length;
			while (src.position<end) {
				var block:BigInteger = new BigInteger(pad(src, end, bl), bl);
				if (exponent.bitLength()<=32) {
					var chunk:BigInteger = block.modPowInt(exponent.valueOf(), modulus);
					chunk.toArray(dst);
				} else {
					throw new Error("exponents wider than 32 bits are not supported. :(");
				}
			}
		}
		/**
		 * PKCS#1 pad. type 2, random.
		 * puts as much data from src into it, leaves what doesn't fit alone.
		 */
		private function pkcs1pad(src:ByteArray, end:int, n:uint):ByteArray {
			var out:ByteArray = new ByteArray;
			var p:uint = src.position;
			end = Math.min(end, src.length, p+n-11);
			src.position = end;
			var i:int = end-1;
			while (i>=p && n>11) {
				out[--n] = src[i--];
			}
			out[--n] = 0;
			var rng:Random = new Random;
			while (n>2) {
				var x:int = 0;
				while (x==0) x = rng.nextByte();
				out[--n] = x;
			}
			out[--n] = 2;
			out[--n] = 0;
			return out;
		}
		/**
		 * Raw pad.
		 */
		private function rawpad(src:ByteArray, end:int, n:uint):ByteArray {
			return src;
		}
		
		public function toString():String {
			return "rsa";
		}
	}
}