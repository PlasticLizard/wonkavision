package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.matchers.ShouldMatchers
import org.scalatest.BeforeAndAfter
import org.scala_tools.time.Imports._
import org.joda.time.format.ISODateTimeFormat
import org.wonkavision.core._


class ConvertSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var cube : Cube = _

  describe("Convert") {

    describe("toString") {
      it("should convert null to None") {
        Convert.toString(null) should equal(None)
      }

      it("should convert values to strings") {
        val sources = List(1,1L,1.0,"hi",List(1)).map(Convert.toString)
        val expected = List("1","1","1.0","hi","List(1)")
        sources should equal(expected.map(Some(_)))
      }      
    }

    describe ("toInt") {
      it("should convert values to ints") {
        val sources = List(1,1L,1.5,"1.5","1",Int.box(1))
          .map(Convert.toInt)
        val expected = List(1, 1, 2, 2, 1, 1)
        sources should equal(expected.map(Some(_)))
      }
    }

    describe("toLong") {
      it("should convert values to longs") {
        val sources = List(1, 1L, 1.4, "1.4", "1", Long.box(1))
          .map(Convert.toLong)
        val expected = List(1, 1, 1, 1, 1, 1)
        sources should equal (expected.map(Some(_)))
      }
    }

    describe("toDouble") {
      it("should convert values to doubles") {
        val sources = List(1, 1L, 1.4, "1.4", "1", Double.box(1.4))
          .map(Convert.toDouble)
        val expected = List(1.0, 1.0, 1.4, 1.4, 1.0, 1.4)
        sources should equal (expected.map(Some(_)))
      }
    }

    describe("toDate") {
      it("Should convert values to dates") {
        val now = DateTime.now
        val sources = List("2011-10-27T22:46:06Z", now)
          .map(Convert.toDate)
        
        sources(0) should equal (Some(ISODateTimeFormat.dateTimeParser().parseDateTime("2011-10-27T22:46:06Z")))
        sources(1) should equal (Some(now))
      }
    }

    describe("toBool") {
      it("Should convert values to booleans") {
        val sources = List(true,false,"true","false")
          .map(Convert.toBool)

        val expected = List(true,false,true,false)
        sources should equal (expected.map(Some(_)))
      }
    }

  }

}
