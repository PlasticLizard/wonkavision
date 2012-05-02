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

import akka.dispatch.{Await, ExecutionContext}
import akka.util.duration._
import akka.actor.ActorSystem

class LocalAggregationRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube  = new Cube("hi") {      
      dimension ( name = "d1", key = Attribute("k",Integer))
      dimension ( name = "d2", key = Attribute("k", Integer))
      dimension ( name = "d3", key = Attribute("k", Integer))
  }
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
	implicit val aggregation = new Aggregation("agg", Set("m1","m2")).combine("d1","d2","d3")
  implicit val executionContext : ExecutionContext = ActorSystem("test").dispatcher

	var aggData : Map[Iterable[String],Iterable[Map[String,Any]]] = _
	
	var repo : LocalAggregationRepository = _

	
  before {
    aggData = Map(
      List("d1","d2","d3") -> List(Map("d1"->1,"d2"->2,"d3"->3),Map("d1"->1,"d2"->3,"d3"->3))
    ) 
    repo = new LocalAggregationRepository(aggregation, aggData)
  }

	describe("get") {
  	it ("should return a matching aggregate") {
  		val dims = List("d1","d2","d3")
  		val key = List(1,3,3)
  		Await.result(repo.get(dims,key), 1 second).get.key should equal (List(1,3,3))
  	}
  	it("should return None if no key matches") {
  		val dims = List("d1","d2","d3")
  		val key = List(1,3,5)
  		Await.result(repo.get(dims,key), 1 second) should equal (None)
  	}
  	it("should return None if no dim sets match") {
  		val dims = List("d1","d2","d4")
  		val key = List(1,3,3)
  		Await.result(repo.get(dims,key), 1 second) should equal (None)
  	}
	}

	describe("all") {
		it ("should get all aggregates for a dim set") {
			val all = Await.result(repo.all(List("d1","d2","d3")), 1 second).toSeq
			all.size should equal (2)
			all(0).key should equal (List(1,2,3))
			all(1).key should equal (List(1,3,3))
		}
		it ("should return Nil if no dim set matches") {
			Await.result(repo.all(List("d1","d2")), 1 second) should equal (Nil)
		}
	}

  describe("writing"){
    describe("put"){
      it("should put an aggregate into the correct dimset"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        Await.result(repo.get(List("d1","d2","d3"),List(1,2,3)), 1 second).get.key should equal (List(1,2,3))
      }
      it("should append to the dimset"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        Await.result(repo.all(List("d1","d2","d3")), 1 second).size should equal (2)
      }
      it("should put into different dimsets"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        Await.result(repo.all(List("d1","d2","d3")), 1 second).size should equal (1)
        Await.result(repo.all(List("d1","d2")), 1 second).size should equal(1)
      }
    }

    describe("purge"){
      it("should only clear the specified dimset"){
        repo.purgeAll()
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        repo.purge(List("d1","d2","d3"))
        Await.result(repo.all(List("d1","d2","d3")), 1 second).size should equal (0)
        Await.result(repo.all(List("d1","d2")), 1 second).size should equal(1)
      }
    }

    describe("purgeAll"){
      it("should clear all dimsets"){
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 3, "d3" -> 3)))
        repo.purgeAll()
        Await.result(repo.all(List("d1","d2","d3")), 1 second).size should equal (0)
        Await.result(repo.all(List("d1","d2")), 1 second).size should equal(0)
      }
    }

    describe("delete"){
      it("should remove the specified key from the specified dimset"){
        repo.put(new Aggregate(List("d1","d2","d3"), Map("d1" -> 1, "d2" -> 2, "d3" -> 3)))
        repo.delete(List("d1","d2","d3"),List(1,2,3))
        Await.result(repo.get(List("d1","d2","d3"),List(1,2,3)), 1 second) should equal (None)
      }
    }
  }
}
 