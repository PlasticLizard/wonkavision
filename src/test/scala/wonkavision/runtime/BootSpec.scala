package org.wonkavision.runtime

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source

class BootSpec extends Spec with BeforeAndAfter with ShouldMatchers {

	var boot : Boot = _

  before {
		boot = new Boot  
	}

  describe("instantiation") {
    it ("should be able to exist in the world") {
    	boot should not be (null)
    }
  }

}
