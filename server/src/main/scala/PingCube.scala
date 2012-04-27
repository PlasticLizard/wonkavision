package org.wonkavision.server.cubes

import org.wonkavision.core._
import AttributeType._
import akka.actor.ActorRef
import org.wonkavision.server.messages._

class PingCube extends Cube("ping") {
	
	dimension (
		name = "ding",
		key = "id" -> Integer,
		caption = "name"
	)

	dimension (
		name = "dong",
		key = "id" -> Integer,
		caption = "name"
	)

	sum("cling","clong")

	aggregation (
		name = "pong",
		measures = List("cling","clong"),
		_.aggregateAll
	)

}

object PingCube {
	var instance : PingCube = _
	var dispatcher : ActorRef = _
	def initialize(disp : ActorRef) = {
		dispatcher = disp
		instance = Cube.register(new PingCube()).asInstanceOf[PingCube]
		dispatcher ! RegisterCube(instance)
		populate()
	}

	def populate(){
		addMembers("ding", List(
			1 -> "ding1",
			2 -> "ding2",
			3 -> "ding3"
		))

		addMembers("dong", List(
			1 -> "dong1",
			2 -> "dong2",
			3 -> "dong3"
		))	

		addAggregate(List("ding","dong"),Map("ding"->1,"dong"->1,"cling"->1,"clong"->2))
		addAggregate(List("ding","dong"),Map("ding"->1,"dong"->2,"cling"->1,"clong"->4))
	}

	def purge(){
		dispatcher ! PurgeDimensionMembers("ping","ding")
		dispatcher ! PurgeDimensionMembers("ping","dong")
	}

	def addMembers(dim : String, memData : List[(Any,String)]) {
		val addCmd =  AddDimensionMembers(
			cubeName = "ping",
			dimensionName = dim,
			members = memData.map { mdata =>
				instance.dimensions(dim).createMember(
					"id" -> mdata._1,
					"name" -> mdata._2
				)
			}
			
		)
		dispatcher ! addCmd
	}

	def addAggregate(dims : List[String], data : Map[String,Any]) {
		val addCmd = AddAggregate(
			cubeName = "ping",
			aggregationName = "pong",
			agg = instance.aggregations("pong").createAggregate(dims,data)
		)
		dispatcher ! addCmd

	}
}

