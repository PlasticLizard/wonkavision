package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
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
		def getMany(keys : Iterable[Any]) = {
			keys.map(get(_)).flatten
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
	    		val found = KvReader.select(new DimensionMemberQuery("hi", "dim", filters))
	    		found.size should equal (1)
	    		found.head.key should equal (2)
	    	}  
	    	it("should select members without a key filter") {
	    		val found = KvReader.select(new DimensionMemberQuery("hi", "dim",filters.tail))
	    		found.size should equal (2)
	    		found.head.key should equal(2)
	    		found.last.key should equal(3)
	    	}  
	  	}
  	}

}
 