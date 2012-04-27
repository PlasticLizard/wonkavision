package org.wonkavision.server

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._

class CubeLoaderSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var loader : CubeLoader = _

  before {
    loader = new CubeLoader("org.wonkavision.server.test.cubes")
  }

  describe("cubes") {
    it("should return a set of cubes in the configured namespace") {
      val cubes = loader.cubes
      cubes.size should equal (1)
      cubes.head.name should equal ("testcube")
    }    
  }

}
