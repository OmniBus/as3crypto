package com.hurlant.util.der
{
	import flash.utils.ByteArray;
	
	public class ObjectIdentifier implements IAsn1Type
	{
		private var type:uint;
		private var len:uint;
		private var oid:Array;
		
		public function ObjectIdentifier(type:uint, length:uint, b:ByteArray) {
			this.type = type;
			this.len = length;
			parse(b);
		}
		
		private function parse(b:ByteArray):void {
			// parse stuff
			// first byte = 40*value1 + value2
			var o:uint = b.readUnsignedByte();
			var a:Array = []
			a.push(uint(o/40));
			a.push(uint(o%40));
			var v:uint = 0;
			while (b.bytesAvailable>0) {
				o = b.readUnsignedByte();
				var last:Boolean = (o&0x80)==0;
				o &= 0x7f;
				v = v*128 + o;
				if (last) {
					a.push(v);
					v = 0;
				}
			}
			oid = a;
		}
		
		public function getLength():uint
		{
			return len;
		}
		
		public function getType():uint
		{
			return type;
		}

		public function toString():String {
			return DER.indent+oid.join(".");
		}
		
		public function dump():String {
			return "OID["+type+"]["+len+"]["+toString()+"]";
		}
		
	}
}