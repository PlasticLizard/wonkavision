package org.wonkavision.server

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._

class AppLoaderSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var loader : AppLoader = _

  before {
    loader = new AppLoader("org.wonkavision.server.test.cubes")
  }

  describe("cubes") {
    it("should return a set of cubes in the configured namespace") {
      val cubes = loader.cubes
      cubes.size should equal (1)
      cubes.head.name should equal ("testcube")
    }    
  }

  describe("environments") {
    it("should return a set of environments in the configured namespace"){
      val envs = loader.environments
      envs.size should equal (1)
    }
  }

}
