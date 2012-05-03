package org.wonkavision.redis

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._
import org.wonkavision.core.Aggregate


import akka.actor.ActorSystem

class RedisAggregationRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube  = new Cube("hi") {      
      dimension ( name = "d1", key = Attribute("k",Integer))
      dimension ( name = "d2", key = Attribute("k", Integer))
      dimension ( name = "d3", key = Attribute("k", Integer))
  }
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
	implicit val aggregation = new Aggregation("agg", Set("m1","m2")).combine("d1","d2","d3")
  val system = ActorSystem("wonkavision")
  val redis = new Redis(system)
	
  var aggData : List[Aggregate] = _
	
	var repo : RedisAggregationRepository = _

  before {

    aggData = List(
      aggregation.createAggregate(List("d1","d2","d3"),Map("d1"->1,"d2"->2,"d3"->3)),
      aggregation.createAggregate(List("d1","d2","d3"),Map("d1"->1,"d2"->3,"d3"->3))

    )
    repo = new RedisAggregationRepository(aggregation, system, redis)
    repo.put(List("d1","d2","d3"),aggData)
  }

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

  describe("writing"){
    describe("put"){
      it("should put an aggregate into the correct dimset"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.get(List("d1","d2","d3"),List(1,2,3)).get.key should equal (List(1,2,3))
      }
      it("should append to the dimset"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        repo.all(List("d1","d2","d3")).size should equal (2)
      }
      it("should put into different dimsets"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        repo.all(List("d1","d2","d3")).size should equal (1)
        repo.all(List("d1","d2")).size should equal(1)
      }
    }

    describe("purge"){
      it("should only clear the specified dimset"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        repo.purge(List("d1","d2","d3"))
        repo.all(List("d1","d2","d3")).size should equal (0)
        repo.all(List("d1","d2")).size should equal(1)
      }
    }

    describe("purgeAll"){
      it("should clear all dimsets"){
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        repo.purgeAll()
        repo.all(List("d1","d2","d3")).size should equal (0)
        repo.all(List("d1","d2")).size should equal(0)
      }
    }

    describe("delete"){
      it("should remove the specified key from the specified dimset"){
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.delete(List("d1","d2","d3"),List(1,2,3))
        repo.get(List("d1","d2","d3"),List(1,2,3)) should equal (None)
      }
    }
  }
}
 