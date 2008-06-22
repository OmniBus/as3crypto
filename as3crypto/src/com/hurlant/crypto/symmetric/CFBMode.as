/**
 * CFBMode
 * 
 * An ActionScript 3 implementation of the CFB confidentiality mode
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */
package com.hurlant.crypto.symmetric
{
	import flash.utils.ByteArray;

	/**
	 * This is the "full" CFB.
	 * CFB1 and CFB8 are hiding somewhere else.
	 */
	public class CFBMode extends IVMode implements IMode
	{
		
		public function CFBMode(key:ISymmetricKey, padding:IPad = null) {
			super(key,padding);
		}

		public function encrypt(src:ByteArray):void
		{
			padding.pad(src);
			var vector:ByteArray = getIV4e();
			for (var i:uint=0;i<src.length;i+=blockSize) {
				key.encrypt(vector);
				for (var j:uint=0;j<blockSize;j++) {
					src[i+j] ^= vector[j];
				}
				vector.position=0;
				vector.writeBytes(src, i, blockSize);
			}
		}
		
		public function decrypt(src:ByteArray):void
		{
			var vector:ByteArray = getIV4d();
			var tmp:ByteArray = new ByteArray;
			for (var i:uint=0;i<src.length;i+=blockSize) {
				key.encrypt(vector);
				tmp.position=0;
				tmp.writeBytes(src, i, blockSize);
				for (var j:uint=0;j<blockSize;j++) {
					src[i+j] ^= vector[j];
				}
				vector.position=0;
				vector.writeBytes(tmp);
			}
			padding.unpad(src);
		}
		
		public function toString():String {
			return key.toString()+"-cfb";
		}

	}
}