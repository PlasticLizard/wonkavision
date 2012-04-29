package org.wonkavision.core.filtering

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import FilterOperator._
import org.scala_tools.time.Imports._
import Ordering.Implicits._
import org.wonkavision.core.MemberType
import org.wonkavision.core.MemberType._
import org.wonkavision.core.Convert

class MemberFilterExpressionSpec extends Spec with BeforeAndAfter with ShouldMatchers {
  
  before {
  }
 
  describe("parse") {

    it ("should parse a simple filter expression") {
      val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1")
      f.getClass should equal (classOf[MemberFilterExpression])
    }

    it ("should detect a Dimension") {
      val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1")
      f.memberType should equal (MemberType.Dimension)
    }
    it ("should detect a Measure") {
      val f = MemberFilterExpression.parse("measure::dim::attr::gt::1")
      f.memberType should equal (MemberType.Measure)
    }
    it ("should parse the member name") {
      val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1")
      f.memberName should equal ("dim")
    }
    it ("should parse the attribute name") {
      val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1")
      f.attributeName should equal ("attr")
    }
    it ("should parse the operator") {
      val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1")
      f.operator should equal (FilterOperator.Gt)
    }
    describe ("value parser") {
      it ("should parse a delimited string") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::'1'")
        f.values should equal (List("1"))
      }
      it ("should parse a non delimited string") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1one1")
        f.values should equal (List("1one1"))       
      }
      it ("should parse an int value") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::001234")
        f.values should equal (List("001234"))
      }
      it ("should parse a long") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::1234567891011121314")
        f.values should equal (List("1234567891011121314"))
      }
      it ("should parse a decimal value") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::.234")
        f.values should equal (List(".234"))
        val f2 = MemberFilterExpression.parse("dimension::dim::attr::gt::1.234")
        f2.values should equal (List("1.234"))
      }
      it ("should parse a date") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::time(2010-01-01)")
        f.values should equal (List("2010-01-01"))
      }
      it ("should parse a list of integers") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::[1,2,3]")
        f.values should equal (List("1","2","3"))
      }
      it ("should parse a list of decimals") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::[1.0,2.0,3.0]")
        f.values should equal (List("1.0","2.0","3.0"))
      }
      it ("should parse a list of strings") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::['1.0','2.0','3.0']")
        f.values should equal (List("1.0","2.0","3.0"))
      }
      it ("should parse a list of dates") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::[time(2010-01-01),time(2010-01-02)]")
        f.values should equal (List("2010-01-01", "2010-01-02"))
      }
      it ("should parse expressions that work") {
        val f = MemberFilterExpression.parse("dimension::dim::attr::gt::99")
        f.matches(98) should equal (false)
        f.matches(99) should equal (false)
        f.matches(100) should equal (true)
      }
    }

  } 

}
