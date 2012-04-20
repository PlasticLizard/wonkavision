package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import scala.collection.immutable.SortedSet

class AggregationSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var cube : Cube = new Cube("c") {
    dimension ( name = "d1" )
    dimension ( name = "d2" )
    dimension ( name = "d3" )
    sum ("m1", "m2")
  }

  var agg : Aggregation = _

 
  before {
    agg = new Aggregation("a", Set("m1", "m2"), cube)
  }
 
  describe("Construction") {
   

    it ("should set the aggregation name") {
      agg.name should equal ("a")
    }

    it( "should set the measures") {
      
      agg.measures should equal (Set("m1", "m2"))

    }
       
  }

  describe ("Aggregations") {
    
    it ("should accept individual aggregations") {
      agg add ("d1", "d2")
      agg.aggregations should equal (Set(SortedSet("d1", "d2")))
    }

    it ("should aggregate all combinations of provided dimensions") {
      agg combine ("d1", "d2")
      agg.aggregations should equal (Set(
          SortedSet("d1"),
          SortedSet("d2"),
          SortedSet("d1", "d2")
        ))
    }

    it ("should aggregate all combinations possible") {
      agg.aggregateAll
      agg.aggregations should equal (Set(
          SortedSet("d1"), SortedSet("d2"), SortedSet("d3"),
          SortedSet("d1", "d2"), SortedSet("d1", "d3"), SortedSet("d2", "d3"),
          SortedSet("d1", "d2", "d3")
        ))
    }

    it ("should maintain a union of aggreagtion operations") {
      agg.combine("d1", "d2").add("d1").add("d1", "d3")
      agg.aggregations should equal (Set(
          SortedSet("d1"), SortedSet("d2"), SortedSet("d1","d2"),
          SortedSet("d1", "d3")
        ))
    }

    it ("should aggregate by a list of dimension sets") {
      agg add List(
          Set("d1"),
          Set("d2"),
          Set("d2", "d3")
        )
      agg.aggregations should equal (Set(
          SortedSet("d1"),
          SortedSet("d2"),
          SortedSet("d2", "d3")
        ))
    }

  }

}
