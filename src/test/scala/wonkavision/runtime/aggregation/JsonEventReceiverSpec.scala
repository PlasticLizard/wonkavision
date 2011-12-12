package org.wonkavision.runtime.aggregation

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import scala.io.Source

import akka.testkit.TestActorRef

import org.wonkavision.runtime.Runtime


class JsonEventReceiverSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var rawData : Array[Byte] = _
  var rcv : JsonEventReceiver = _
  
  before {
    rawData = getTestMessage
    rcv = TestActorRef(new JsonEventReceiver()).underlyingActor
  }
  
  describe("parseJson") {
    it ("should transform an array of bytes into a map") {
      val map = rcv.parseJson(new String(getTestMessage))
      assert( map.isInstanceOf[Map[String,Any]] )
      map("id") should equal ("4d9cd519ce47d0407100000b")
    }
  }

  def getTestMessage = {
    val source = scala.io.Source.fromFile("src/test/resources/test_work_queue_entry_message.json")
    val result = source.map(_.toByte).toArray
    source.close ()
    result
  }

}
