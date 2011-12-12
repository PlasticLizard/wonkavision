package org.wonkavision.runtime.aggregation

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source

import org.wonkavision.runtime.Runtime
import org.wonkavision.core.Environment._
import org.wonkavision.core.Cube

import akka.testkit.TestActorRef

class AggregationServiceSpec extends Spec with BeforeAndAfter with ShouldMatchers {

	var svc : AggregationService = _
	var ref : TestActorRef[AggregationService] = _
  implicit val runtime = new Runtime(Test)

  before {
  	ref = TestActorRef(new AggregationService(testCubes) )
  	svc = ref.underlyingActor
  }

  describe("instantiation") {
    it ("should be able to exist in the world") {
    	svc should not equal (null)
    }
    it ("should take on the correct id") {
    	ref.id should equal (runtime.aggregationServiceKey)
    }
  }

  def testCubes = {
    List(
      new Cube("c1"),
      new Cube("c2")
    )
  }

}
