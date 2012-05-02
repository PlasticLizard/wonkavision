package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._
import org.wonkavision.core.Aggregate

import akka.dispatch.{Await, Promise, Future}
import akka.util.duration._
import akka.actor.ActorSystem

class AggregationRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube  = new Cube("hi") {      
      dimension ( name = "d1", key = Attribute("k",Integer))
      dimension ( name = "d2", key = Attribute("k", Integer))
      dimension ( name = "d3", key = Attribute("k", Integer))
  	}
	implicit val aggregation = new Aggregation("agg", Set("m1","m2")).combine("d1","d2","d3")
	implicit val executionContext = ActorSystem("test").dispatcher

	val d1 = Dimension("d1", Attribute("k", Integer))
	val d2 = Dimension("d2", Attribute("k", Integer))
	val d3 = Dimension("d3", Attribute("k", Integer))
	

	val aggData : Map[String, Aggregate] = Map(
		"1:2:3" -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)),
		"1:3:3" -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)),
		"1:4:3" -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 4, "d3" -> 3))
	)
	
	object KvReader extends KeyValueAggregationReader {
		def get(dimensions : Iterable[String], key : Iterable[Any]) = {
			Promise.successful( aggData.get(key.mkString(":")) )
		}

		def getMany(dimensions : Iterable[String], keys : Iterable[Iterable[Any]]) = {
			val futures = keys.map{ key => get(dimensions, key).map(_.getOrElse(null))}
			Future.sequence(futures).map{_.filter{agg => agg != null}}
		}

		def all(dimensionNames : Iterable[String]) = Promise.successful( aggData.values.toList )
	}

	def createQuery(filtered : Boolean) = {
		AggregateQuery(
			cubeName = "hi",
			aggregationName = "agg",
			dimensions = List(
				DimensionMembers(
					dimension = d1,
					members = List(new DimensionMember(Map("k" -> 1))(d1)),
					hasFilter = false
				),
				DimensionMembers(
					dimension = d2,
					members = List(
						new DimensionMember(Map("k"->2))(d2),
						new DimensionMember(Map("k"->4))(d2)
					),
					hasFilter = filtered

				),
				DimensionMembers(
					dimension = d3,
					members = List(
						new DimensionMember(Map("k"->3))(d3)
					),
					hasFilter = false
				)
			)
		)
	}



	before {}
	describe("reader"){
	  	describe("select") {
	    	it("should return the selected subset of aggregates") {
	    		Await.result(KvReader.select(createQuery(true)), 1 second) should equal (List(
	    			aggData("1:2:3"), aggData("1:4:3")
	    		))
	    	} 
	    	it ("should return all records when not filtered") {
	    		Await.result(KvReader.select(createQuery(false)), 1 second) should equal (aggData.values.toList)
	    	}
	    	
	 	}
	 }

  	object KvWriter extends KeyValueAggregationWriter {
		val data : scala.collection.mutable.Map[String,Aggregate] = scala.collection.mutable.Map()

		def put(agg : Aggregate) {
			data(agg.dimensions.mkString(":") + agg.key.mkString(":")) = agg
		}
		def purge(dimensions : Iterable[String]) {
			data.clear()
		}
		def purgeAll() {}
		def delete(dimensions : Iterable[String], key : Iterable[Any]) {}
	}

	describe("writer"){
		describe("put"){
			it("should add all aggregations to the repo"){
				val newData = List(
					new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)),
					new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3))
				)
				KvWriter.put(List("d1","d2","d3"),newData)
				KvWriter.data.size should equal(2)
				KvWriter.data("d1:d2:d31:2:3").key should equal(List(1,2,3))
				KvWriter.data("d1:d2:d31:3:3").key should equal(List(1,3,3))
			}
			it("should append aggregations to the repo"){
				val newData1 = List(
					new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)),
					new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3))
				)
				val newData2 = List(
					new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 4, "d3" -> 3)),
					new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 5, "d3" -> 3))
				)
				KvWriter.put(List("d1","d2","d3"),newData1)
				KvWriter.put(List("d1","d2","d3"),newData2)
				KvWriter.data.size should equal(4)
			}
		}
	}

}
 