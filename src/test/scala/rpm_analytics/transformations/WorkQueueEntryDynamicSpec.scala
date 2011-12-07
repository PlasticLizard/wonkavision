package rpm.analytics.transformations

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import scala.collection.mutable.HashMap
import net.liftweb.json._
import net.liftweb.json.ext.JodaTimeSerializers
import org.scala_tools.time.Imports._
import org.joda.time.format.ISODateTimeFormat
import scala.util.matching.Regex
import org.wonkavision.core._

import rpm.analytics.transformations._

class WorkQueueEntryDynamicSpec extends Spec with BeforeAndAfter with ShouldMatchers {
  
  implicit val formats = net.liftweb.json.DefaultFormats ++ JodaTimeSerializers.all

	var source : Map[String,Any] = _
	var result : HashMap[String, Any] = _
  var ctxTime : DateTime = _

  before {
	  result = new WorkQueueEntryDynamic(ctxTime).execute(getTestMessage)
    ctxTime = ISODateTimeFormat.dateTimeParser().parseDateTime("2010-07-06T22:00:00Z")
  }

  describe("Executing the transformation") {
    
    it ("should map the id") {
      result("is_active") should equal (false)
    }

    it ("should map available") {
      result("available") should equal (null)
    }

    it ("should map expiring_today") {
      result("expiring_today") should equal (null)
    }

    it ("should map incoming") {
      result("incoming") should equal (1)
    }

    it ("should map outgoing") {
      result("outgoing") should equal (1)
    }

    it ("should map completed") {
      result("completed") should equal (1)
    }

    it ("should map cancelled") {
      result("cancelled") should equal (null)
    }

    it ("should map overdue") {
      result("overdue") should equal (null)
    }

    it ("should map status") {
      result("status") should equal (
        Map(
          "status" -> "completed",
          "sort" -> 3
        )
      )
    }
  }

  def getTestMessage = {
  	val source = scala.io.Source.fromFile("src/test/resources/test_work_queue_entry_message.json")
		val json = source .mkString
		source.close ()
		parse(json).values.asInstanceOf[Map[String,Any]]
  }

}

