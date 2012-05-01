package org.wonkavision.redis.serialization

import scala.collection.JavaConversions._
import org.msgpack.{MessagePack => MP}
import org.msgpack.unpacker.Converter
import org.msgpack.template.Templates._

object MessagePack {
	def writeMap(map : Map[String,String]) : Array[Byte] = {
		val jmap : java.util.Map[String,String] = map
		new MP().write(jmap)		
	}

	def readMap(bytes : Array[Byte]) : Map[String, String] = {
		val jmap : java.util.Map[String,String] = new MP().read(bytes, tMap(TString,TString))
		jmap.toMap[String,String]
	}

}