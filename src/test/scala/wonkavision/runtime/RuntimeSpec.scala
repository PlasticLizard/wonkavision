package org.wonkavision.runtime

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source

import org.wonkavision.core.Environment._

class RuntimeSpec extends Spec with BeforeAndAfter with ShouldMatchers {

	var runtime : Runtime = _

  before {
		runtime = new Runtime(Production)  
	}

  describe("instantiation") {
    it ("should be able to exist in the world") {
    	runtime should not equal (null)
    }
  }

  describe ("singleton") {
  	it ("should manage a singleton") {
  		Runtime.initialize(Development)
  		Runtime.current.environment should equal (Development)
  	}
  }

}
