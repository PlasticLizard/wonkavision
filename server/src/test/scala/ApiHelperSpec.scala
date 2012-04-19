package org.wonkavision.server

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.server.messages._
import org.wonkavision.server.test.cubes.TestCube


class ApiHelperSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var qs : String = _

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
    qs = "measures=me%7Cfa&filters=dimension%3A%3Ahi%3A%3Akey%3A%3Anin%3A%3A%5B%223%22%2C%20%222%22%2C%20%221%22%5D%7Cdimension%3A%3Aso%3A%3Akey%3A%3Ain%3A%3A%5B1%2C%202%2C%203%5D%7Cmeasure%3A%3Afa%3A%3Aattribute%3A%3Alt%3A%3A5&columns=hi%7Cho%7Chum&rows=do%7Cre"
    Cube.register(new TestCube())
  }

  describe("parseAxes") {
    it("extract dimension names from the specified axes") {
      val axes = ApiHelper.parseAxes(qs)
      axes should equal (List(
        List("hi","ho","hum"),
        List("do","re")        
      ))      
    }
    it("should discard dimension names from non-contiguous axes") {
      val axes = ApiHelper.parseAxes(qs + "&chapters=one%7Ctwo")
      axes should equal (List(
        List("hi","ho","hum"),
        List("do","re")        
      ))      
    }    
  }

  describe("parseList") {
    it("should parse a delimited list") {
      ApiHelper.parseList(qs, "columns") should equal (List("hi","ho","hum"))
    }
  }

  describe("param"){
    it("should return a list of values in the query string for a key") {
      ApiHelper.param(qs, "columns") should equal (List("hi|ho|hum"))
    }
    it("should return an empty list if no key is found"){
      ApiHelper.param(qs, "notheredude") should equal (List())
    }
  }

  describe("parseQuery"){
    it("should return a populated query from a query string") {
      val query = ApiHelper.parseQuery("cb","ag",qs)
      query should equal (CellsetQuery(
          cube = "cb",
          aggregation = "ag",
          axes = List(
            List("hi","ho","hum"),
            List("do","re")        
          ),
          measures = List("me","fa"),
          filters = List(
            "dimension::hi::key::nin::[\"3\", \"2\", \"1\"]",
            "dimension::so::key::in::[1, 2, 3]",
            "measure::fa::attribute::lt::5"

          )
        ))
    }
  }

  describe("validateQuery(query)") {
    it("should complain if the requested cube isn't found") {
      val query = ApiHelper.parseQuery("blah","An Aggregation","")
      ApiHelper.validateQuery(query) should equal (Some(ObjectNotFound("Cube", "blah")))
    }
    it ("should complain if the cube is OK but the aggreagation isn't found") {
      val query = ApiHelper.parseQuery("A Cube Of Testing", "blah", "")
      ApiHelper.validateQuery(query) should equal (Some(ObjectNotFound("Aggregation", "blah")))
    }
    it ("should complain if the cube and aggregation are OK but the dimensions aren't found"){
      val query = ApiHelper.parseQuery("A Cube Of Testing", "An Aggregation", "columns=a|team")
      ApiHelper.validateQuery(query) should equal(Some(ObjectNotFound("Dimension(s)","a")))
    }
    it ("should return None if the query is valid") {
      val query = ApiHelper.parseQuery("A Cube Of Testing", "An Aggregation", "columns=team&rows=status")
      ApiHelper.validateQuery(query) should equal (None)
    }
  }

}
