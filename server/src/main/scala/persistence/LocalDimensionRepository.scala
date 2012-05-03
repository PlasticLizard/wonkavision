package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Dimension

import akka.dispatch.{Future,Promise,ExecutionContext}

class LocalDimensionRepository(
	dim : Dimension,
	data : Iterable[Map[String,Any]] = List()
)(implicit val executionContext : ExecutionContext)
	 extends DimensionRepository
	 with KeyValueDimensionReader
     with KeyValueDimensionWriter {
	
	implicit val dimension = dim
	
	def get(rawKey : Any) = {
		val key = dimension.key.ensure(rawKey)
		Promise.successful( members.get(key) )
	}	

	def getMany(keys : Iterable[Any]) = {
		val futures = keys.map{key => get(key).map(_.getOrElse(null))}
		Future.sequence(futures).map(_.filter(dim => dim != null))
	}

	def all() = {
		Promise.successful ( members.values ) 
	}

	def put(member : DimensionMember) = {
		members = members + (member.key -> member)
		Promise.successful()
	}

	def put(members : Iterable[DimensionMember]) = {
		members.foreach(put(_))
		Promise.successful()
	}

	def delete(rawKey : Any) = {
		val key = dimension.key.ensure(rawKey)
		members = members - key
		Promise.successful()
	}

	def purge() = {
		members = Map()
		Promise.successful()
	}

	private var members : Map[Any,DimensionMember] = {
		val tuples = data.map { mdata =>
			val member = new DimensionMember(mdata)
			(member.key -> member)
		}.toSeq
		Map(tuples:_*)
	}

}