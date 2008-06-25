package com.hurlant.util.der
{
	public class Type
	{
		public static const CERTIFICATE:Array = [
			{name:"tbsCertificate", value:[
				{name:"tag0", value:[
					{name:"version"}
				]},
				{name:"serialNumber"},
				{name:"signature"},
				{name:"issuer", value:[
					{name:"type"},
					{name:"value"}
				]},
				{name:"validity", value:[
					{name:"notBefore"},
					{name:"notAfter"}
				]},
				{name:"subject"},
				{name:"subjectPublicKeyInfo", value:[
					{name:"algorithm"},
					{name:"subjectPublicKey"}
				]},
				{name:"issuerUniqueID"},
				{name:"subjectUniqueID"},
				{name:"extensions"}
			]},
			{name:"signatureAlgorithm"},
			{name:"signatureValue"}
		];
		public static const RSA_PUBLIC_KEY:Array = [
			{name:"modulus"},
			{name:"publicExponent"}
		];
		
		
	}
}