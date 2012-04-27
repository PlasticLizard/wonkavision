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
import org.wonkavision.core.Aggregate

class AggregationActorSpec(_system:ActorSystem)
	extends TestKit(_system) with ImplicitSender
		with WordSpec with BeforeAndAfterAll with ShouldMatchers {
		
		def this() = this(ActorSystem("AggregationActorSpec"))

		val cube = new TestCube()
		val team = cube.dimensions("team")
		val status = cube.dimensions("status")
		val agg = cube.aggregations("testaggregation")

		val aggActor = TestActorRef(new AggregationActor {
			val aggregation = agg
		 	val repo = new LocalAggregationRepository(agg)
		 })
		

		override def afterAll() {
			system.shutdown()
		}

		"Sending a query to an aggregation" should {
			"return the selected aggregates" in {
				aggActor ! AddAggregates(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					aggs = List(
						agg.createAggregate(List("team","status"), "team" -> "3", "status" -> "happy"),
						agg.createAggregate(List("team","status"), "team" -> "4", "status" -> "happy")
					)
				)

				var query = AggregateQuery("testcube", "testaggregation", List(
					DimensionMembers( team, List(team.createMember("id"->"3")), true),
					DimensionMembers( status, List(status.createMember("status"->"happy")),false)
				))

				aggActor ! query
				val results = expectMsgClass(1 second, classOf[Iterable[Aggregate]])
				results.size should equal (1)
				results.toSeq(0).key should equal (List("happy","3"))
			}
		}

		"Sending an AddAggregate message to an aggregation" should {

			"add the aggregate to the aggregation" in {
				aggActor ! AddAggregate(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					agg = agg.createAggregate(List("status","team"), "team" -> "1", "status" -> "happy") 				
				)
				aggActor.underlyingActor.repo.get(List("status","team"),List("happy","1")).get.key should equal(List("happy","1"))
			}

			"append members to the repo" in {
				aggActor ! AddAggregate(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					agg = agg.createAggregate(List("team","status"), "team" -> "2", "status" -> "happy") 				
				)
				aggActor.underlyingActor.repo.get(List("status","team"),List("happy","1")).get.key should equal(List("happy","1"))
				aggActor.underlyingActor.repo.get(List("status","team"),List("happy","2")).get.key should equal(List("happy","2"))
			}
		}

		"Sending an AddDimensionMembers message to a dimension" should {

			"add all the members to the dimension" in {
				aggActor ! AddAggregates(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					aggs = List(
						agg.createAggregate(List("team","status"), "team" -> "3", "status" -> "happy"),
						agg.createAggregate(List("team","status"), "team" -> "4", "status" -> "happy")
					)
				)
				aggActor.underlyingActor.repo.get(List("status","team"),List("happy","3")).get.key should equal(List("happy","3"))
				aggActor.underlyingActor.repo.get(List("status","team"),List("happy","4")).get.key should equal(List("happy","4"))
			}

		}

	}