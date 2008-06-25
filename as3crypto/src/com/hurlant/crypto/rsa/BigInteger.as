/**
 * BigInteger
 * 
 * An ActionScript 3 implementation of BigInteger (light version)
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
	import com.hurlant.util.Hex;
	import com.hurlant.util.Memory;
	
	import flash.utils.ByteArray;
	use namespace bi_internal;

	public class BigInteger
	{
		public static const DB:int = 30; // number of significant bits per chunk
		public static const DV:int = (1<<DB);
		public static const DM:int = (DV-1); // Max value in a chunk
		
		public static const BI_FP:int = 52;
		public static const FV:Number = Math.pow(2, BI_FP);
		public static const F1:int = BI_FP - DB;
		public static const F2:int = 2*DB - BI_FP;
		
		public static const ZERO:BigInteger = nbv(0);
		public static const ONE:BigInteger  = nbv(1);
		
		bi_internal var t:int; // number of chunks.
		bi_internal var s:int; // sign
		bi_internal var a:Array; // chunks
		
		public function BigInteger(value:* = null, radix:int = 0) {
			a = new Array;
			if (value is String) {
				value = Hex.toArray(value);
				radix=0;
			}
			if (value is ByteArray) {
				var array:ByteArray = value as ByteArray;
				var length:int = radix || (array.length - array.position);
				fromArray(array, length);
			}
		}
		public function dispose():void {
			var r:Random = new Random;
			for (var i:uint=0;i<a.length;i++) {
				a[i] = r.nextByte();
				delete a[i];
			}
			a=null;
			t=0;
			s=0;
			Memory.gc();
		}
		
		public function toString(radix:Number=16):String {
			if (s<0) return "-"+negate().toString(radix);
			var k:int;
			switch (radix) {
				case 2:   k=1; break;
				case 4:   k=2; break;
				case 8:   k=3; break;
				case 16:  k=4; break;
				case 32:  k=5; break;
				default:
//					return toRadix(radix);
			}
			var km:int = (1<<k)-1;
			var d:int = 0;
			var m:Boolean = false;
			var r:String = "";
			var i:int = t;
			var p:int = DB-(i*DB)%k;
			if (i-->0) {
				if (p<DB && (d=a[i]>>p)>0) {
					m = true;
					r = d.toString(36);
				}
				while (i >= 0) {
					if (p<k) {
						d = (a[i]&((1<<p)-1))<<(k-p);
						d|= a[--i]>>(p+=DB-k);
					} else {
						d = (a[i]>>(p-=k))&km;
						if (p<=0) {
							p += DB;
							--i;
						}
					}
					if (d>0) {
						m = true;
					}
					if (m) {
						r += d.toString(36);
					}
				}
			}
			return m?r:"0";
		}
		public function toArray(array:ByteArray):uint {
			const k:int = 8;
			const km:int = (1<<8)-1;
			var d:int = 0;
			var i:int = t;
			var p:int = DB-(i*DB)%k;
			var m:Boolean = false;
			var c:int = 0;
			if (i-->0) {
				if (p<DB && (d=a[i]>>p)>0) {
					m = true;
					array.writeByte(d);
					c++;
				}
				while (i >= 0) {
					if (p<k) {
						d = (a[i]&((1<<p)-1))<<(k-p);
						d|= a[--i]>>(p+=DB-k);
					} else {
						d = (a[i]>>(p-=k))&km;
						if (p<=0) {
							p += DB;
							--i;
						}
					}
					if (d>0) {
						m = true;
					}
					if (m) {
						array.writeByte(d);
						c++;
					}
				}
			}
			return c;
		}
		/**
		 * best-effort attempt to fit into a Number.
		 * precision can be lost if it just can't fit.
		 */
		public function valueOf():Number {
			var coef:Number = 1;
			var value:Number = 0;
			for (var i:uint=0;i<t;i++) {
				value += a[i]*coef;
				coef *= DV;
			}
			return value;
		}
		/**
		 * -this
		 */
		public function negate():BigInteger {
			var r:BigInteger = new BigInteger;
			ZERO.subTo(this, r);
			return r;
		}
		/**
		 * |this|
		 */
		public function abs():BigInteger {
			return (s<0)?negate():this;
		}
		/**
		 * return + if this > v, - if this < v, 0 if equal
		 */
		public function compareTo(v:BigInteger):int {
			var r:int = s - v.s;
			if (r!=0) return r;
			var i:int = t;
			r = i-v.t;
			if (r!=0) return r;
			while (--i >=0) {
				if ((r=a[i]-v.a[i]) != 0) return r;
			}
			return 0;
		}
		/**
		 * returns bit length of the integer x
		 */
		bi_internal function nbits(x:int):int {
			var r:int = 1;
			var t:int;
			if ((t=x>>>16) != 0) { x = t; r += 16; }
			if ((t=x>>8) != 0) { x = t; r += 8; }
			if ((t=x>>4) != 0) { x = t; r += 4; }
			if ((t=x>>2) != 0) { x = t; r += 2; }
			if ((t=x>>1) != 0) { x = t; r += 1; }
			return r;
		}
		/**
		 * returns the number of bits in this
		 */
		public function bitLength():int {
			if (t<=0) return 0;
			return DB*(t-1)+nbits(a[t-1]^(s&DM));
		}
		/**
		 * this % v 
		 */
		public function mod(v:BigInteger):BigInteger {
			var r:BigInteger = new BigInteger;
			abs().divRemTo(v,null,r);
			if (s<0 && r.compareTo(ZERO)>0) {
				v.subTo(r,r);
			}
			return r;
		}
		/**
		 * this^e % m, 0 <= e < 2^32
		 */
		public function modPowInt(e:int, m:BigInteger):BigInteger {
			var z:IReduction;
			if (e<256 || m.isEven()) {
				z = new Classic(m);
			} else {
				z = new Montgomery(m);
			}
			return exp(e, z);
		}

		/**
		 * copy this to r
		 */
		bi_internal function copyTo(r:BigInteger):void {
			for (var i:int = t-1; i>=0; --i) {
				r.a[i] = a[i];
			}
			r.t = t;
			r.s = s;
		}
		/**
		 * set from integer value "value", -DV <= value < DV
		 */
		bi_internal function fromInt(value:int):void {
			t = 1;
			s = (value<0)?-1:0;
			if (value>0) {
				a[0] = value;
			} else if (value<-1) {
				a[0] = value+DV;
			} else {
				t = 0;
			}
		}
		/**
		 * set from ByteArray and length,
		 * starting a current position
		 * If length goes beyond the array, pad with zeroes.
		 */
		bi_internal function fromArray(value:ByteArray, length:int):void {
			var p:int = value.position;
			var i:int = p+length;
			var sh:int = 0;
			const k:int = 8;
			t = 0;
			s = 0;
			while (--i >= p) {
				var x:int = i<value.length?value[i]:0;
				if (sh == 0) {
					a[t++] = x;
				} else if (sh+k > DB) {
					a[t-1] |= (x&((1<<(DB-sh))-1))<<sh;
					a[t++] = x>>(DB-sh);
				} else {
					a[t-1] |= x<<sh;
				}
				sh += k;
				if (sh >= DB) sh -= DB;
			}
			clamp();
			value.position = Math.min(p+length,value.length);
		}
		/**
		 * clamp off excess high words
		 */
		bi_internal function clamp():void {
			var c:int = s&DM;
			while (t>0 && a[t-1]==c) {
				--t;
			}
		}
		/**
		 * r = this << n*DB
		 */
		bi_internal function dlShiftTo(n:int, r:BigInteger):void {
			var i:int;
			for (i=t-1; i>=0; --i) {
				r.a[i+n] = a[i];
			}
			for (i=n-1; i>=0; --i) {
				r.a[i] = 0;
			}
			r.t = t+n;
			r.s = s;
		}
		/**
		 * r = this >> n*DB
		 */
		bi_internal function drShiftTo(n:int, r:BigInteger):void {
			var i:int;
			for (i=n; i<t; ++i) {
				r.a[i-n] = a[i];
			}
			r.t = Math.max(t-n,0);
			r.s = s;
		}
		/**
		 * r = this << n
		 */
		bi_internal function lShiftTo(n:int, r:BigInteger):void {
			var bs:int = n%DB;
			var cbs:int = DB-bs;
			var bm:int = (1<<cbs)-1;
			var ds:int = n/DB;
			var c:int = (s<<bs)&DM;
			var i:int;
			for (i=t-1; i>=0; --i) {
				r.a[i+ds+1] = (a[i]>>cbs)|c;
				c = (a[i]&bm)<<bs;
			}
			for (i=ds-1; i>=0; --i) {
				r.a[i] = 0;
			}
			r.a[ds] = c;
			r.t = t+ds+1;
			r.s = s;
			r.clamp();
		}
		/**
		 * r = this >> n
		 */
		bi_internal function rShiftTo(n:int, r:BigInteger):void {
			r.s = s;
			var ds:int = n/DB;
			if (ds >= t) {
				r.t = 0;
				return;
			}
			var bs:int = n%DB;
			var cbs:int = DB-bs;
			var bm:int = (1<<bs)-1;
			r.a[0] = a[ds]>>bs;
			var i:int;
			for (i=ds+1; i<t; ++i) {
				r.a[i-ds-1] |= (a[i]&bm)<<cbs;
				r.a[i-ds] = a[i]>>bs;
			}
			if (bs>0) {
				r.a[t-ds-1] |= (s&bm)<<cbs;
			}
			r.t = t-ds;
			r.clamp();
		}
		/**
		 * r = this - v
		 */
		bi_internal function subTo(v:BigInteger, r:BigInteger):void {
			var i:int = 0;
			var c:int = 0;
			var m:int = Math.min(v.t, t);
			while (i<m) {
				c += a[i] - v.a[i];
				r.a[i++] = c & DM;
				c >>= DB;
			}
			if (v.t < t) {
				c -= v.s;
				while (i< t) {
					c+= a[i];
					r.a[i++] = c&DM;
					c >>= DB;
				}
				c += s;
			} else {
				c += s;
				while (i < v.t) {
					c -= v.a[i];
					r.a[i++] = c&DM;
					c >>= DB;
				}
				c -= v.s;
			}
			r.s = (c<0)?-1:0;
			if (c<-1) {
				r.a[i++] = DV+c;
			} else if (c>0) {
				r.a[i++] = c;
			}
			r.t = i;
			r.clamp();
		}
		/**
		 * am: Compute w_j += (x*this_i), propagates carries,
		 * c is initial carry, returns final carry.
		 * c < 3*dvalue, x < 2*dvalue, this_i < dvalue
		 */
		bi_internal function am(i:int,x:int,w:BigInteger,j:int,c:int,n:int):int {
			var xl:int = x&0x7fff;
			var xh:int = x>>15;
			while(--n >= 0) {
				var l:int = a[i]&0x7fff;
				var h:int = a[i++]>>15;
				var m:int = xh*l + h*xl;
				l = xl*l + ((m&0x7fff)<<15)+w.a[j]+(c&0x3fffffff);
				c = (l>>>30)+(m>>>15)+xh*h+(c>>>30);
				w.a[j++] = l&0x3fffffff;
			}
			return c;
		}
		/**
		 * r = this * v, r != this,a (HAC 14.12)
		 * "this" should be the larger one if appropriate
		 */
		bi_internal function multiplyTo(v:BigInteger, r:BigInteger):void {
			var x:BigInteger = abs();
			var y:BigInteger = v.abs();
			var i:int = x.t;
			r.t = i+y.t;
			while (--i >= 0) {
				r.a[i] = 0;
			}
			for (i=0; i<y.t; ++i) {
				r.a[i+x.t] = x.am(0, y.a[i], r, i, 0, x.t);
			}
			r.s = 0;
			r.clamp();
			if (s!=v.s) {
				ZERO.subTo(r, r);
			}
		}
		/**
		 * r = this^2, r != this (HAC 14.16)
		 */
		bi_internal function squareTo(r:BigInteger):void {
			var x:BigInteger = abs();
			var i:int = r.t = 2*x.t;
			while (--i>=0) r.a[i] = 0;
			for (i=0; i<x.t-1; ++i) {
				var c:int = x.am(i, x.a[i], r, 2*i, 0, 1);
				if ((r.a[i+x.t] += x.am(i+1, 2*x.a[i], r, 2*i+1, c, x.t-i-1)) >= DV) {
					r.a[i+x.t] -= DV;
					r.a[i+x.t+1] = 1;
				}
			}
			if (r.t>0) {
				r.a[r.t-1] += x.am(i, x.a[i], r, 2*i, 0, 1);
			}
			r.s = 0;
			r.clamp();
		}
		/**
		 * divide this by m, quotient and remainder to q, r (HAC 14.20)
		 * r != q, this != m. q or r may be null.
		 */
		bi_internal function divRemTo(m:BigInteger, q:BigInteger = null, r:BigInteger = null):void {
			var pm:BigInteger = m.abs();
			if (pm.t <= 0) return;
			var pt:BigInteger = abs();
			if (pt.t < pm.t) {
				if (q!=null) q.fromInt(0);
				if (r!=null) copyTo(r);
				return;
			}
			if (r==null) r = new BigInteger;
			var y:BigInteger = new BigInteger;
			var ts:int = s;
			var ms:int = m.s;
			var nsh:int = DB-nbits(pm.a[pm.t-1]); // normalize modulus
			if (nsh>0) {
				pm.lShiftTo(nsh, y);
				pt.lShiftTo(nsh, r);
			} else {
				pm.copyTo(y);
				pt.copyTo(r);
			}
			var ys:int = y.t;
			var y0:int = y.a[ys-1];
			if (y0==0) return;
			var yt:Number = y0*(1<<F1)+((ys>1)?y.a[ys-2]>>F2:0);
			var d1:Number = FV/yt;
			var d2:Number = (1<<F1)/yt;
			var e:Number = 1<<F2;
			var i:int = r.t;
			var j:int = i-ys;
			var t:BigInteger = (q==null)?new BigInteger:q;
			y.dlShiftTo(j,t);
			if (r.compareTo(t)>=0) {
				r.a[r.t++] = 1;
				r.subTo(t,r);
			}
			ONE.dlShiftTo(ys,t);
			t.subTo(y,y); // "negative" y so we can replace sub with am later.
			while(y.t<ys) y.(y.t++, 0);
			while(--j >= 0) {
				// Estimate quotient digit
				var qd:int = (r.a[--i]==y0)?DM:Number(r.a[i])*d1+(Number(r.a[i-1])+e)*d2;
				if ((r.a[i]+= y.am(0, qd, r, j, 0, ys))<qd) { // Try it out
					y.dlShiftTo(j, t);
					r.subTo(t,r);
					while (r.a[i]<--qd) {
						r.subTo(t,r);
					}
				}
			}
			if (q!=null) {
				r.drShiftTo(ys,q);
				if (ts!=ms) {
					ZERO.subTo(q,q);
				}
			}
			r.t = ys;
			r.clamp();
			if (nsh>0) {
				r.rShiftTo(nsh, r); // Denormalize remainder
			}
			if (ts<0) {
				ZERO.subTo(r,r);
			}
		}
		/**
		 * return "-1/this % 2^DB"; useful for Mont. reduction
		 * justification:
		 *         xy == 1 (mod n)
		 *         xy =  1+km
		 * 	 xy(2-xy) = (1+km)(1-km)
		 * x[y(2-xy)] =  1-k^2.m^2
		 * x[y(2-xy)] == 1 (mod m^2)
		 * if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
		 * should reduce x and y(2-xy) by m^2 at each step to keep size bounded
		 * [XXX unit test the living shit out of this.]
		 */
		bi_internal function invDigit():int {
			if (t<1) return 0;
			var x:int = a[0];
			if ((x&1)==0) return 0;
			var y:int = x&3; 							// y == 1/x mod 2^2
			y = (y*(2-(x&0xf )*y))             &0xf;	// y == 1/x mod 2^4
			y = (y*(2-(x&0xff)*y))             &0xff;	// y == 1/x mod 2^8
			y = (y*(2-(((x&0xffff)*y)&0xffff)))&0xffff;	// y == 1/x mod 2^16
			// last step - calculate inverse mod DV directly;
			// assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
			// XXX 48 bit ints? Whaaaa? is there an implicit float conversion in here?
			y = (y*(2-x*y%DV))%DV;	// y == 1/x mod 2^dbits
			// we really want the negative inverse, and -DV < y < DV
			return (y>0)?DV-y:-y;
		}
		/**
		 * true iff this is even
		 */
		bi_internal function isEven():Boolean {
			return ((t>0)?(a[0]&1):s) == 0;
		}
		/**
		 * this^e, e < 2^32, doing sqr and mul with "r" (HAC 14.79)
		 */
		bi_internal function exp(e:int, z:IReduction):BigInteger {
			if (e > 0xffffffff || e < 1) return ONE;
			var r:BigInteger = new BigInteger;
			var r2:BigInteger = new BigInteger;
			var g:BigInteger = z.convert(this);
			var i:int = nbits(e)-1;
			g.copyTo(r);
			while(--i>=0) {
				z.sqrTo(r, r2);
				if ((e&(1<<i))>0) {
					z.mulTo(r2,g,r);
				} else {
					var t:BigInteger = r;
					r = r2;
					r2 = t;
				}
				
			}
			return z.revert(r);
		}
		bi_internal function intAt(str:String, index:int):int {
			return parseInt(str.charAt(index), 36);
		}

		/**
		 * return bigint initialized to value
		 */
		private static function nbv(value:int):BigInteger {
			var bn:BigInteger = new BigInteger;
			bn.fromInt(value);
			return bn;
		}
		
	}
}
import com.hurlant.crypto.rsa.BigInteger;
import com.hurlant.crypto.rsa.bi_internal;
use namespace bi_internal;
interface IReduction {
	function convert(x:BigInteger):BigInteger;
	function revert(x:BigInteger):BigInteger;
	function reduce(x:BigInteger):void;
	function mulTo(x:BigInteger, y:BigInteger, r:BigInteger):void;
	function sqrTo(x:BigInteger, r:BigInteger):void;
}
/**
 * Modular reduction using "classic" algorithm
 */
class Classic implements IReduction {
	private var m:BigInteger;
	public function Classic(m:BigInteger) {
		this.m = m;
	}
	public function convert(x:BigInteger):BigInteger {
		if (x.s<0 || x.compareTo(m)>=0) {
			return x.mod(m);
		}
		return x;
	}
	public function revert(x:BigInteger):BigInteger {
		return x;
	}
	public function reduce(x:BigInteger):void {
		x.divRemTo(m, null,x);
	}
	public function mulTo(x:BigInteger, y:BigInteger, r:BigInteger):void {
		x.multiplyTo(y,r);
		reduce(r);
	}
	public function sqrTo(x:BigInteger, r:BigInteger):void {
		x.squareTo(r);
		reduce(r);
	}
}
/**
 * Montgomery reduction
 */
class Montgomery implements IReduction {
	private var m:BigInteger;
	private var mp:int;
	private var mpl:int;
	private var mph:int;
	private var um:int;
	private var mt2:int;
	public function Montgomery(m:BigInteger) {
		this.m = m;
		mp = m.invDigit();
		mpl = mp & 0x7fff;
		mph = mp>>15;
		um = (1<<(BigInteger.DB-15))-1;
		mt2 = 2*m.t;
	}
	/**
	 * xR mod m
	 */
	public function convert(x:BigInteger):BigInteger {
		var r:BigInteger = new BigInteger;
	 	x.abs().dlShiftTo(m.t, r);
	 	r.divRemTo(m, null, r);
	 	if (x.s<0 && r.compareTo(BigInteger.ZERO)>0) {
	 		m.subTo(r,r);
	 	}
	 	return r;
	}
	/**
	 * x/R mod m
	 */
	public function revert(x:BigInteger):BigInteger {
		var r:BigInteger = new BigInteger;
		x.copyTo(r);
		reduce(r);
		return r;
	}
	/**
	 * x = x/R mod m (HAC 14.32)
	 */
	public function reduce(x:BigInteger):void {
		while (x.t<=mt2) {		// pad x so am has enough room later
			x.a[x.t++] = 0;
		}
		for (var i:int=0; i<m.t; ++i) {
			// faster way of calculating u0 = x[i]*mp mod DV
			var j:int = x.a[i]&0x7fff;
			var u0:int = (j*mpl+(((j*mph+(x.a[i]>>15)*mpl)&um)<<15))&BigInteger.DM;
			// use am to combine the multiply-shift-add into one call
			j = i+m.t;
			x.a[j] += m.am(0, u0, x, i, 0, m.t);
			// propagate carry
			while (x.a[j]>=BigInteger.DV) {
				x.a[j] -= BigInteger.DV;
				x.a[++j]++;
			}
		}
 		x.clamp();
	 	x.drShiftTo(m.t, x);
 		if (x.compareTo(m)>=0) {
 			x.subTo(m,x);
 		}
	}
	/**
	 * r = "x^2/R mod m"; x != r
	 */
	public function sqrTo(x:BigInteger, r:BigInteger):void {
		x.squareTo(r);
		reduce(r);
	}
	/**
	 * r = "xy/R mod m"; x,y != r
	 */
	public function mulTo(x:BigInteger, y:BigInteger, r:BigInteger):void {
		x.multiplyTo(y,r);
		reduce(r);
	}
}