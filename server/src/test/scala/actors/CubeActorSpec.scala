package org.wonkavision.server

import akka.actor.ActorSystem
import akka.actor.Actor
import akka.actor.Props

import org.scalatest.WordSpec
import akka.testkit.TestKit
import akka.testkit.TestActorRef
import akka.testkit.ImplicitSender

import akka.util.duration._
import akka.dispatch.Await
import akka.pattern.ask

import org.scalatest.BeforeAndAfterAll
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.server.cubes.PingCube
import org.wonkavision.server.messages._

import org.wonkavision.server.actors._
import org.wonkavision.server.test.cubes.TestCube
import org.wonkavision.server.persistence.LocalAggregationRepository
import org.wonkavision.core.filtering.MemberFilterExpression
import org.wonkavision.core._

class CubActorSpec(_system:ActorSystem)
	extends TestKit(_system) with ImplicitSender
		with WordSpec with BeforeAndAfterAll with ShouldMatchers {
		
		def this() = this(ActorSystem("CubeActorSpec"))

		val cube = new TestCube()
		val team = cube.dimensions("team")
		val status = cube.dimensions("status")
		val agg = cube.aggregations("testaggregation")

		val cubeActor = TestActorRef(new CubeActor(cube))		

		override def afterAll() {
			system.shutdown()
		}

		"Sending a cellset query to a cube" should {
			"return a cellset" in {
				cubeActor ! AddAggregates(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					aggs = List(
						agg.createAggregate(List("team","status"), "team" -> "2", "status"->"happy","incoming" -> 1, "outgoing" -> 2),
						agg.createAggregate(List("team","status"), "team" -> "3", "status" -> "happy", "incoming" -> 3, "outgoing" -> 4),
						agg.createAggregate(List("team","status"), "team" -> "4", "status" -> "sad", "incoming" -> 5, "outgoing" -> 6)
					)
				)

				cubeActor ! AddDimensionMembers(
					cubeName = "testcube",
					dimensionName = "team",
					members = List(
						team.createMember("id"->"2","name"->"ah"),
						team.createMember("id"->"3","name"->"blah"),
						team.createMember("id"->"4","name"->"es")
					)					
				)

				cubeActor ! AddDimensionMembers(
					cubeName = "testcube",
					dimensionName = "status",
					members = List(
						status.createMember("status"->"happy","name"->"ah"),
						status.createMember("status"->"sad","name"->"blah"),
						status.createMember("status"->"funny","name"->"es")
					)					
				)

				val query = CellsetQuery(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					axes = List(List("team"),List("status")),
					measures = List("incoming","outgoing"),
					filters = List(MemberFilterExpression.parse("dimension::team::key::lt::4"))
				)

				cubeActor ! query
				val cellset = expectMsgClass(1 second, classOf[Cellset])
				cellset.members.size should equal(2)
				cellset.members.find(m=>m.dimension.name == "team").get.members.size should equal(2)
				cellset.members.find(m=>m.dimension.name == "status").get.members.size should equal(3)
				cellset.aggregates.size should equal(2)
				cellset.aggregates.forall(ag => ag.key.toSeq(0).toString() == "happy") should equal(true)
			}
		}

}