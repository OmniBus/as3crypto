package com.hurlant.util.der
{
	public dynamic class Sequence extends Array implements IAsn1Type
	{
		protected var type:uint;
		protected var len:uint;
		
		public function Sequence(type:uint, length:uint) {
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
		
		public function toString():String {
			var s:String = DER.indent;
			DER.indent += "    ";
			var t:String = join("\n");
			DER.indent= s;
			return DER.indent+"Sequence["+type+"]["+len+"][\n"+t+"\n"+s+"]";
		}
		
		/////////
		
		public function findAttributeValue(oid:String):IAsn1Type {
			for each (var set:* in this) {
				if (set is Set) {
					var child:* = set[0];
					if (child is Sequence) {
						var tmp:* = child[0];
						if (tmp is ObjectIdentifier) {
							var id:ObjectIdentifier = tmp as ObjectIdentifier;
							if (id.toString()==oid) {
								return child[1] as IAsn1Type;
							}
						}
					}
				}
			}
			return null;
		}
		
	}
}