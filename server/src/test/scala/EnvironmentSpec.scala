package org.wonkavision.server

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source


import Environment._

class EnvironmentSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var env  = new Environment {
    var state : String = _

    override def configure = {
      case Development => 
        state = "Dev"
        
      case Production =>
        state = "Prod"

      case _ =>
        state = "Something Else"
    }
  }

  before {
    
  }

  describe("initialize") {
    it ("should set the current env") {
      env.initialize(Development)
      env.environment should equal (Development)
    }

    it("should match and exec the provided env") {
      env.initialize(Production)
      env.state should equal ("Prod")
    }    

    it ("should match the default") {
      env.initialize(Staging)
      env.state should equal ("Something Else")
    }
  }

}
