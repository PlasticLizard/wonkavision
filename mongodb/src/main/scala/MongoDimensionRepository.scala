package org.wonkavision.mongodb

import org.wonkavision.core.{Dimension, DimensionMember}
import org.wonkavision.server.persistence._

import akka.actor.ActorSystem

import org.wonkavision.server.messages._
import org.wonkavision.core.filtering.MemberFilterExpression
import org.wonkavision.core.filtering.FilterOperator

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObjectBuilder

class MongoDimensionRepository(dim : Dimension, system : ActorSystem)
	extends DimensionRepository
	with DimensionReader
	with DimensionWriter {

	implicit val dimension = dim
	
	private val mongodb = new MongoDb(system)
	def collection = mongodb.collection(dimension.fullname)

	def select(query : DimensionMemberQuery) : Iterable[DimensionMember] = {
		if (query.hasFilter) {
			val q = createQuery()
			for (f <- query.filters) {
				q ++= toMongo(f)
			}
			collection.find(q).map{fromMongo(_)}.toList
		} else {
			all()
		}
	}

	def get(key : Any) : Option[DimensionMember] = {
		val query = createQuery(key)
		collection.findOne(query).map{ fromMongo(_) }
	}

	def getMany(keys : Iterable[Any]) : Iterable[DimensionMember] = {
		keys.map{ get(_) }.flatten
	}

	def all() : Iterable[DimensionMember] = {
		collection.find(createQuery()).map{ fromMongo(_) }.toList
	}

	def put(member : DimensionMember) = {
		val query = createQuery(member)
		val update = toMongo(member)

		collection.update(query, update, true, false)
		true
	}

	def put(members : Iterable[DimensionMember]) = {
		collection.insert( members.map(toMongo(_)).toList )
		true
	}

	def delete(key : Any) = {
		val query = createQuery(key)
		collection.remove(query)
		true
	}

	def purge() = {
		collection.remove(createQuery())
		true
	}	

	private def createQuery() = {
		MongoDBObject()
	}

	private def createQuery(member : DimensionMember) : MongoDBObject = createQuery(member.key)

	private def createQuery(key : Any) : MongoDBObject = {
		MongoDBObject("_key" -> key)
	}

	private def toMongo(member : DimensionMember) : MongoDBObject = {
		val dbobj = createQuery(member)
		for (i <- member.dimension.attributes.indices)
			dbobj += (member.dimension.attributes(i).name -> member.at(i).get.asInstanceOf[AnyRef])
		dbobj
	}

	private def toMongo(filter : MemberFilterExpression) : MongoDBObject = {
		val fobj = MongoDBObject()
		val attr = dimension.getAttribute(filter.attributeName)
		val values = filter.values.map(attr.ensure(_))
		val value = if (filter.operator == FilterOperator.Eq) {
			values.head
		}  else if (filter.operator == FilterOperator.In || filter.operator == FilterOperator.Nin)
			MongoDBObject("$" + filter.operator.toString().toLowerCase() -> values)
		else
			MongoDBObject("$" + filter.operator.toString().toLowerCase() -> values.head)
		
		fobj += (attr.name -> value.asInstanceOf[AnyRef])
		fobj
	}

	private def fromMongo(dbobj : MongoDBObject)(implicit dim : Dimension) : DimensionMember = {
		val data = dbobj - "_key"
		new DimensionMember(Map(data.iterator.toSeq:_*))(dim)
	}
}