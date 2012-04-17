package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import scala.collection.immutable.SortedSet
import org.wonkavision.core._
import org.wonkavision.core.measures._
import org.wonkavision.core.FactAction._

class CubeSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var cube : Cube = _

  before {
    cube = new Cube("mah cube") {
      
      dimension (
        name = "dimname",
        key = "dimkey",
        caption = "dimcap",
        sort = "dimsort"
      )

      dimension (
        name = "dimname2",
        key = "dimkey2",
        caption = "dimcap2",
        sort = "dimsort2"
      )

      sum ("awe_sum")
      sum ("paw_sum", "flot_sum")

      calc("a_calc", format = MeasureFormat.Money) {
        () => 1.0
      }

      aggregation (
        name = "a1",
        measures = List("awe_sum"),
        _.add("dimname")
         .combine("dimname2")
      )

      aggregation (
        name = "a2",
        measures = List("awe_sum", "flot_sum"),
        _.aggregateAll
      )

      accept (
        event = "an/event",
        action = Add,
        transformation = new MapTransformation {
          def map {
            string ("hi")
          }
        }
      )
     
    }
    
  }

  describe("Construction") {
    
    it ("should set the cube name") {
      cube.name should equal ("mah cube")
    }

    it( "should create specified dimensions") {
      
      cube dimensions "dimname" should equal (
        Dimension ("dimname","dimkey","dimcap","dimsort")
      )
      cube dimensions "dimname2" should equal (
        Dimension ("dimname2","dimkey2","dimcap2","dimsort2")
      )

    }
    
    //measures
    it ("should create a single sum measure") {
      cube.measures("awe_sum") should not be (null)
      cube.measures("awe_sum").name should equal ("awe_sum")
    } 
    
    it ("should create multiple sum measures") {
      cube.measures("paw_sum") should not be (null)
      cube.measures("paw_sum").name should equal ("paw_sum")

      cube.measures("flot_sum") should not be (null)
      cube.measures("flot_sum").name should equal ("flot_sum")
    }   

    it ("should create a calculated measure") {
      assert( cube.measures("a_calc").isInstanceOf[Calculation] )
      cube.measures("a_calc").name should equal ("a_calc")
      cube.measures("a_calc").asInstanceOf[Calculation].calcFunction() should equal (1.0)
    }

    //aggregations
    it ("should create and configure aggregations") {
      cube.aggregations("a1").name should equal ("a1")
      cube.aggregations("a1").aggregations should equal (Set(
        SortedSet("dimname"),
        SortedSet("dimname2")
      ))

      cube.aggregations("a2").name should equal ("a2")
      cube.aggregations("a2").aggregations should equal (Set(
        SortedSet("dimname"),
        SortedSet("dimname2"),
        SortedSet("dimname", "dimname2")
      ))
    }

    //accepters
    it ("should create and register an accepter") {
      cube.events.length should equal(1)
      cube.events.head match {
        case FactEventBinding(evt, action, owner, xform) =>  {
          evt should equal("an/event")
          action should equal (Add)
          owner should equal(cube)
          xform should not be(None)
        }

      }
    }
   
  }

}
