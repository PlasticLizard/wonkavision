package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

class DimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))

	val memberData : Map[Any,DimensionMember] = Map(
		1 -> new DimensionMember(Map("k" -> 1, "c" -> "a")),
		2 -> new DimensionMember(Map("k" -> 2, "c" -> "b")),
		3 -> new DimensionMember(Map("k" -> 3, "c" -> "c"))
	)

	object KvReader extends KeyValueDimensionReader {
		def get(key : Any) = {
			memberData.get(Convert.toInt(key).get)
		}
		def all = memberData.values
	}

	val filters = List(
		MemberFilterExpression.parse("dimension::dim::key::in::[1,2]"),
		MemberFilterExpression.parse("dimension::dim::caption::gte::b")
	)


	before {}

	describe("reader") {
	  	describe("select") {
	    	it("should return the selected subset of members") {
	    		val found = KvReader.select(new DimensionMemberQuery("dim", filters))
	    		found.size should equal (1)
	    		found.head.key should equal (2)
	    	}  
	    	it("should select members without a key filter") {
	    		val found = KvReader.select(new DimensionMemberQuery("dim",filters.tail))
	    		found.size should equal (2)
	    		found.head.key should equal(2)
	    		found.last.key should equal(3)
	    	}  
	  	}
  	}

  	object KvWriter extends KeyValueDimensionWriter {
		val data : scala.collection.mutable.Map[Any, DimensionMember] = scala.collection.mutable.Map()
		def put(key : Any, member : DimensionMember) {
			data(key) = member
		}
		def delete(key : Any) {
			data.remove(key)
		}
		def purge() { data.clear() }
	}

	describe ("writer"){
		describe("put") {
			it("should add each member in the provided map") {
				KvWriter.put(memberData)
				KvWriter.data should equal (memberData)
			}
			it("should append the values to the existing data") {
				KvWriter.put(memberData)
				KvWriter.put(memberData.map(e => (e._1+"b",e._2)))
				KvWriter.data.size should equal(6)
			}			
		}
		describe("load") {
			it("should replace data with the incoming data"){
				KvWriter.put(memberData)
				KvWriter.put(memberData.map(e => (e._1+"b",e._2)))
				KvWriter.data.size should equal(6)
				KvWriter.load(memberData)
				KvWriter.data should equal (memberData)
			}
		}
	}

}
 