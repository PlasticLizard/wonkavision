package org.wonkavision.server.messages

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.core.filtering.MemberFilterExpression

class MessagesSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  describe ("CellsetQuery") {
    val query = CellsetQuery(
      cube = "c",
      aggregation = "a",
      axes = List(List("d1","d2"),List("d3","d4")),
      measures = List("m1","m2"),
      filters = List(MemberFilterExpression.parse("dimension::d1::key::gt::1"))
    )
    before {
      
    }
    it ("#dimensions should flatten axes into a single list of dimensions") {
      query.dimensions should equal (List("d1","d2","d3","d4"))
    }
    it ("#dimensionFiltersFor should return selected filters") {
      query.dimensionFiltersFor("d1") should equal (query.filters)
    }
  }

}
