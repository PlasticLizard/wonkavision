package org.wonkavision.redis.serialization

import org.wonkavision.core.{Dimension, DimensionMember, Aggregate, Aggregation}

abstract trait Serializer {
	def write(member : DimensionMember) : Array[Byte]
	def readDimensionMember(bytes : Option[Array[Byte]])(implicit dim : Dimension) : Option[DimensionMember]

	def write(aggregate : Aggregate) : Array[Byte]
	def readAggregate(dimensionNames : Iterable[String], bytes : Option[Array[Byte]])(implicit agg : Aggregation) : Option[Aggregate]
}

class MessagePackSerializer extends Serializer{

	def write(member : DimensionMember) : Array[Byte] = {
		val elements = for (i <- member.dimension.attributes.indices)
			yield (member.dimension.attributes(i).name -> member.at(i).getOrElse("").toString)
		MessagePack.writeMap(Map(elements:_*))
	}

	def write(aggregate : Aggregate) : Array[Byte] = {
		val keys = aggregate.key.toSeq
		val measures = aggregate.measures.filter(e => !e._2.isEmpty)
			.map{ element =>
				(element._1 -> element._2.get.toString)
			}.toList
		val dims = for(i <- aggregate.dimensions.indices)
			yield (aggregate.dimensions(i) -> keys(i).toString)
		MessagePack.writeMap(Map(measures ++ dims:_*))
	}	

	def readDimensionMember(bytes : Option[Array[Byte]])(implicit dim : Dimension) : Option[DimensionMember] = {
		bytes.map { b => 
			val data : Map[String,String] = MessagePack.readMap(b)
			new DimensionMember(data)(dim)
		}	
	}

	def readAggregate(dimensions : Iterable[String], bytes : Option[Array[Byte]])(implicit agg : Aggregation) : Option[Aggregate] = {
		bytes.map { b =>
			val data : Map[String,String] = MessagePack.readMap(b)
			new Aggregate(dimensions, data)(agg)
		}
	}
}