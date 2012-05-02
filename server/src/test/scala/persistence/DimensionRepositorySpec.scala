package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

import akka.dispatch.{Await, Promise, Future}
import akka.util.duration._
import akka.actor.ActorSystem

class DimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
	implicit val executionContext = ActorSystem("test").dispatcher

	val memberData : Map[Any,DimensionMember] = Map(
		1 -> new DimensionMember(Map("k" -> 1, "c" -> "a")),
		2 -> new DimensionMember(Map("k" -> 2, "c" -> "b")),
		3 -> new DimensionMember(Map("k" -> 3, "c" -> "c"))
	)

	object KvReader extends KeyValueDimensionReader {
		def get(key : Any) = {
			Promise.successful(memberData.get(Convert.toInt(key).get))
		}

		def getMany(keys : Iterable[Any]) = {
			val futures = keys.map{key => get(key).map(_.getOrElse(null))}
			Future.sequence(futures).map(_.filter(dim => dim != null))
		}

		def all = Promise.successful(memberData.values)
	}

	val filters = List(
		MemberFilterExpression.parse("dimension::dim::key::in::[1,2]"),
		MemberFilterExpression.parse("dimension::dim::caption::gte::b")
	)

	before {}

	describe("reader") {
	  	describe("select") {
	    	it("should return the selected subset of members") {
	    		val found = Await.result(KvReader.select(new DimensionMemberQuery("hi", "dim", filters)), 1 second)
	    		found.size should equal (1)
	    		found.head.key should equal (2)
	    	}  
	    	it("should select members without a key filter") {
	    		val found = Await.result(KvReader.select(new DimensionMemberQuery("hi", "dim",filters.tail)), 1 second)
	    		found.size should equal (2)
	    		found.head.key should equal(2)
	    		found.last.key should equal(3)
	    	}  
	  	}
  	}

  	object KvWriter extends KeyValueDimensionWriter {
		val data : scala.collection.mutable.Map[Any, DimensionMember] = scala.collection.mutable.Map()
		def put(member : DimensionMember) {
			data(member.key) = member
		}
		def delete(key : Any) {
			data.remove(key)
		}
		def purge() { data.clear() }
	}

	describe ("writer"){
		describe("put") {
			it("should add each member in the provided map") {
				KvWriter.put(memberData.values)
				KvWriter.data should equal (memberData)
			}
			it("should append the values to the existing data") {
				KvWriter.put(memberData.values)
				KvWriter.put(List(
					new DimensionMember(Map("k" -> 4, "c" -> "a")),
					new DimensionMember(Map("k" -> 5, "c" -> "b")),
					new DimensionMember(Map("k" -> 6, "c" -> "c"))
				))
				KvWriter.data.size should equal(6)
			}			
		}		
	}

}
 