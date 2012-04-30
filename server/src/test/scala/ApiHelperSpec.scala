package org.wonkavision.server

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering.MemberFilterExpression
import org.wonkavision.server.test.cubes.TestCube


class ApiHelperSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var qs : String = _
  implicit var params : Map[String,List[String]] = _

  before {
    /*FROM:
    columns hi, ho, hum
    rows do, re
    measures me, fa
    where
      dimensions.hi.nin => ["3","2","1"]
      dimensions.so.in => [1,2,3]
      measures.fa.attribute.lt => 5}
    */
    params = Map(
      "measures" -> List("me|fa"),
      "filters" -> List("dimension::hi::key::nin::[3,2,1]|dimension::so::key::in::[1,2,3]|measure::fa::attribute::lt::5"),
      "columns" -> List("hi|ho|hum"),
      "rows" -> List("do|re")
    )
    Cube.register(new TestCube())
  }

  describe("parseAxes") {
    it("extract dimension names from the specified axes") {
      val axes = ApiHelper.parseAxes()
      axes should equal (List(
        List("hi","ho","hum"),
        List("do","re")        
      ))      
    }  
  }

  describe("parseList") {
    it("should parse a delimited list") {
      ApiHelper.parseList("columns") should equal (List("hi","ho","hum"))
    }
  }

  describe("parseQuery"){
    it("should return a populated query from a query string") {
      val query = ApiHelper.parseQuery("cb","ag",params)
      query should equal (CellsetQuery(
          cubeName = "cb",
          aggregationName = "ag",
          axes = List(
            List("hi","ho","hum"),
            List("do","re")        
          ),
          measures = List("me","fa"),
          filters = List(
            "dimension::hi::key::nin::[3,2,1]",
            "dimension::so::key::in::[1,2,3]",
            "measure::fa::attribute::lt::5"

          ).map(fs => MemberFilterExpression.parse(fs))
        ))
    }
  }

  describe("validateQuery(query)") {
    it("should complain if the requested cube isn't found") {
      val query = ApiHelper.parseQuery("blah","testaggregation",Map())
      ApiHelper.validateQuery(query) should equal (Some(ObjectNotFound("Cube", "blah")))
    }
    it ("should complain if the cube is OK but the aggreagation isn't found") {
      val query = ApiHelper.parseQuery("testcube", "blah", Map())
      ApiHelper.validateQuery(query) should equal (Some(ObjectNotFound("Aggregation", "blah")))
    }
    it ("should complain if the cube and aggregation are OK but the dimensions aren't found"){
      val query = ApiHelper.parseQuery("testcube", "testaggregation", Map("columns"->List("a|team")))
      ApiHelper.validateQuery(query) should equal(Some(ObjectNotFound("Dimension(s)","a")))
    }
    it ("should return None if the query is valid") {
      val query = ApiHelper.parseQuery("testcube", "testaggregation", Map("columns"->List("team"),"rows"->List("status")))
      ApiHelper.validateQuery(query) should equal (None)
    }
  }

}
