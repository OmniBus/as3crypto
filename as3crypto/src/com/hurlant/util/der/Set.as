package com.hurlant.util.der
{
	public dynamic class Set extends Sequence implements IAsn1Type
	{
		public function Set(type:uint, length:uint) {
			super(type, length);
		}


		public override function toString():String {
			var s:String = DER.indent;
			DER.indent += "    ";
			var t:String = join("\n");
			DER.indent= s;
			return DER.indent+"Set["+type+"]["+len+"][\n"+t+"\n"+s+"]";
		}
		
	}
}