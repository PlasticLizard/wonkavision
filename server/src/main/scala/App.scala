package com.hsihealth

import com.typesafe.play.mini._
import play.api.mvc._
import play.api.mvc.Results._

/**
 * this application is registered via Global
 */
object App extends Application { 
  def route = {
    case GET(Path("/coco")) & QueryString(qs) => Action{ request=>
      println(request.body)
      println(play.api.Play.current)
      val result = QueryString(qs,"foo").getOrElse("noh!")
      Ok(<h1>It works!, query String {result}</h1>).as("text/html")
    }
  }
}
