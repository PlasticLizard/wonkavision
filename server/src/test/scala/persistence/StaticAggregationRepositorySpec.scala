package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

class StaticAggregationRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube  = new Cube("hi") {      
      dimension ( name = "d1", key = Attribute("k",Integer))
      dimension ( name = "d2", key = Attribute("k", Integer))
      dimension ( name = "d3", key = Attribute("k", Integer))
  }
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
	implicit val aggregation = new Aggregation("agg", Set("m1","m2")).combine("d1","d2","d3")

	val aggData : Map[Iterable[String],Iterable[Map[String,Any]]] = Map(
		List("d1","d2","d3") -> List(Map("d1"->1,"d2"->2,"d3"->3),Map("d1"->1,"d2"->3,"d3"->3))
	)	
	
	val repo = new StaticAggregationRepository(aggregation, aggData)

	before {}

  	describe("get") {
    	it ("should return a matching aggregate") {
    		val dims = List("d1","d2","d3")
    		val key = List(1,3,3)
    		repo.get(dims,key).get.key should equal (List(1,3,3))
    	}
    	it("should return None if no key matches") {
    		val dims = List("d1","d2","d3")
    		val key = List(1,3,5)
    		repo.get(dims,key) should equal (None)
    	}
    	it("should return None if no dim sets match") {
    		val dims = List("d1","d2","d4")
    		val key = List(1,3,3)
    		repo.get(dims,key) should equal (None)
    	}
  	}

  	describe("all") {
  		it ("should get all aggregates for a dim set") {
  			val all = repo.all(List("d1","d2","d3")).toSeq
  			all.size should equal (2)
  			all(0).key should equal (List(1,2,3))
  			all(1).key should equal (List(1,3,3))
  		}
  		it ("should return Nil if no dim set matches") {
  			repo.all(List("d1","d2")) should equal (Nil)
  		}
  	}



}
 