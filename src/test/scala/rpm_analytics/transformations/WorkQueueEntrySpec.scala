package rpm.analytics.transformations

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import scala.collection.mutable.HashMap
import net.liftweb.json._
import net.liftweb.json.ext.JodaTimeSerializers
import org.wonkavision.core._

import rpm.analytics.transformations._

class WorkQueueEntrySpec extends Spec with BeforeAndAfter with ShouldMatchers {
  
  implicit val formats = net.liftweb.json.DefaultFormats ++ JodaTimeSerializers.all

	var source : Map[String,Any] = _
	var result : HashMap[String, Any] = _

  before {
	  result = new WorkQueueEntry().execute(getTestMessage)
  }

  describe("Executing the transformation") {
    
    it ("should map the id") {
      result("id") should equal ("4d9cd519ce47d0407100000b")
    }

    it ("should map the team") {
      result("team") should equal (
        Map(
          "id" -> "4d9cd519ce47d04071000001",
          "name" -> "a-team"
        )
      )
    }

    it ("should map assigned_to") {
      result("assigned_to") should equal (
        Map(
          "id" -> "4d9cd519ce47d04071000007",
          "name" -> "wow, j"
        )
      )
    }

    it ("should map work_queue_priority") {
      result("work_queue_priority") should equal (
        Map(
          "priority" -> 1, 
          "name" -> "Priority 1",
          "key" -> "1"
        )
      )
    }

    it ("should map work_queue") {
      result("work_queue") should equal (
        Map(
          "id" -> "4d9cd519ce47d0407100000c",
          "name" -> "a",
          "priority" -> 1
        )
      )
    }

    it ("should  execute WorkQueueEntryDynamic") {
      result("is_active") should equal (false)
    }
  }

  def getTestMessage = {
  	val source = scala.io.Source.fromFile("src/test/resources/test_work_queue_entry_message.json")
		val json = source .mkString
		source.close ()
		parse(json).values.asInstanceOf[Map[String,Any]]
  }

}

