package org.wonkavision.core

import org.wonkavision.core._
import AttributeType._

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

class AggregateSpec extends Spec with BeforeAndAfter with ShouldMatchers {
 
 	implicit val cube  = new Cube("hi") {      
      dimension ( name = "d1", key = Attribute("k",Integer))
      dimension ( name = "d2", key = Attribute("k", Integer))
  	}

 	implicit val aggregation = new Aggregation("agg", Set("m1","m2"))

 	val aggregate = new Aggregate(
 			dims = List("d1","d2"),
 			data = Map("d1" -> "1", "d2" -> "2", "m1" -> 100)
 	)(aggregation)

	before {

	}

	describe("construction") {
		it("should parse the key from the incoming data") {
			aggregate.key should equal(List(1,2))
		}    
		it ("should parse measure values") {
			aggregate.measures("m1") should equal (Some(100.0))
		}
		it ("should parse None for valid measures missing values") {
			aggregate.measures("m2") should equal (None)
		}
	}

}
