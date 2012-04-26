package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._
import org.wonkavision.server.Aggregate

class AggregationRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube  = new Cube("hi") {      
      dimension ( name = "d1", key = Attribute("k",Integer))
      dimension ( name = "d2", key = Attribute("k", Integer))
      dimension ( name = "d3", key = Attribute("k", Integer))
  	}
	implicit val aggregation = new Aggregation("agg", Set("m1","m2")).combine("d1","d2","d3")

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
			aggData.get(key.mkString(":"))
		}
		def all(dimensionNames : Iterable[String]) = aggData.values.toList
	}

	def createQuery(filtered : Boolean) = {
		AggregationQuery(
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
	    		KvReader.select(createQuery(true)) should equal (List(
	    			aggData("1:2:3"), aggData("1:4:3")
	    		))
	    	} 
	    	it ("should return all records when not filtered") {
	    		KvReader.select(createQuery(false)) should equal (aggData.values.toList)
	    	}
	    	
	 	}
	 }

  	object KvWriter extends KeyValueAggregationWriter {
		val data : scala.collection.mutable.Map[String,Aggregate] = scala.collection.mutable.Map()

		def put(dimensions : Iterable[String], key : Iterable[Any], agg : Aggregate) {
			data(dimensions.mkString(":") + key.mkString(":")) = agg
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
				val newData = Map(
					List(1,2,3) -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)),
					List(1,3,3) -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3))
				)
				KvWriter.put(List("d1","d2","d3"), newData)
				KvWriter.data.size should equal(2)
				KvWriter.data("d1:d2:d31:2:3").key should equal(List(1,2,3))
				KvWriter.data("d1:d2:d31:3:3").key should equal(List(1,3,3))
			}
			it("should append aggregations to the repo"){
				val newData1 = Map(
					List(1,2,3) -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)),
					List(1,3,3) -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3))
				)
				val newData2 = Map(
					List(1,4,3) -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 4, "d3" -> 3)),
					List(1,5,3) -> new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 5, "d3" -> 3))
				)
				KvWriter.put(List("d1","d2","d3"),newData1)
				KvWriter.put(List("d1","d2","d3"),newData2)
				KvWriter.data.size should equal(4)
			}
		}
	}

}
 