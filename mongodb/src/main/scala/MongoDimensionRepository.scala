package org.wonkavision.mongodb

import org.wonkavision.core.{Dimension, DimensionMember, Attribute}
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
			appendFilters(q, query.filters.toSeq)
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
		collection.drop()
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

	private def fromMongo(dbobj : MongoDBObject)(implicit dim : Dimension) : DimensionMember = {
		val data = dbobj - "_key"
		new DimensionMember(Map(data.iterator.toSeq:_*))(dim)
	}

	private def appendFilters(query : MongoDBObject, filters : Seq[MemberFilterExpression]) = {
		val grouped = filters.groupBy(f => f.attributeName)
		for (attrEl <- grouped) {
			val (attrName, attrFilters) = attrEl
			val attr = dimension.getAttribute(attrName)
			if (attrFilters.length == 1 && attrFilters.head.operator == FilterOperator.Eq) 
				query += (attr.name -> attr.ensure(attrFilters.head.values.head).asInstanceOf[AnyRef])
			else if (attrFilters.length == 1)
				query += (attr.name -> filterValue(attr, attrFilters.head))
			else
				query += (attr.name -> filterValues(attr, attrFilters))
		}
	}

	private def filterValues(attr : Attribute, filters : Seq[MemberFilterExpression]) : MongoDBObject = {
		val vals = MongoDBObject.newBuilder
		filters.foreach { f =>
			if (f.operator == FilterOperator.Eq)
				throw new Exception("The operator $eq cannot be used in conjuction with any other operator for the same dimension attribute")
			vals ++= filterValue(attr, f)
		}
		vals.result
	}

	private def filterValue(attr : Attribute, filter : MemberFilterExpression) : MongoDBObject = {
		val values = filter.values.map(attr.ensure(_))
		if (filter.operator == FilterOperator.In || filter.operator == FilterOperator.Nin)
			MongoDBObject("$" + filter.operator.toString().toLowerCase() -> values)
		else
			MongoDBObject("$" + filter.operator.toString().toLowerCase() -> values.head.asInstanceOf[AnyRef])
		
	}

}