package com.hurlant.util.der
{
	import flash.utils.ByteArray;
	import com.hurlant.util.Hex;

	public class ByteString extends ByteArray implements IAsn1Type
	{
		private var type:uint;
		private var len:uint;
		
		public function ByteString(type:uint, length:uint) {
			this.type = type;
			this.len = length;
		}
		
		public function getLength():uint
		{
			return len;
		}
		
		public function getType():uint
		{
			return type;
		}
		
		override public function toString():String {
			return DER.indent+"ByteString["+type+"]["+len+"]["+Hex.fromArray(this)+"]";
		}
		
	}
}