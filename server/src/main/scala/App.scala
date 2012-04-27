package org.wonkavision.server

import com.typesafe.play.mini._
import play.api.mvc._
import play.api.mvc.Results._
import play.api.libs.concurrent._

import akka.actor.{Props, ActorSystem, Actor}
import akka.pattern.ask
import akka.pattern.pipe
import akka.util.Timeout
import akka.util.duration._
import akka.dispatch.{Await, Future}

import org.wonkavision.server.messages._

import com.codahale.jerkson.Json

/**
 * this application is registered via Global
 */
object App extends Application { 
  import ApiHelper._
  val WV_APP_NAME = "wonkavision"

  lazy val wonka = Wonkavision(WV_APP_NAME).get
  implicit val timeout = Timeout(5000 milliseconds)

  def route = {
    case GET(Path(Seg("query" :: cube :: aggregation :: Nil))) & QueryString(qs) => Action{ implicit request=>
      val query = parseQuery(cube, aggregation, qs)
      val error = validateQuery(query)
      if (!error.isEmpty)
        NotFound(error.get.message)
      else
        AsyncResult { 
          (wonka.dispatcher ? query).mapTo[QueryResult].asPromise.map { result =>
            result match {
              case cs : Cellset => {
                val json = Json.generate(cs.toMap())
                Ok(json)
              }
            }
          }
        }
    }
  }
}
