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

class AggregationActorSpec(_system:ActorSystem)
	extends TestKit(_system) with ImplicitSender
		with WordSpec with BeforeAndAfterAll with ShouldMatchers {
		
		def this() = this(ActorSystem("AggregationActorSpec"))

		val cube = new TestCube()
		val dim = cube.dimensions("team")
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
				// dimActor ! AddDimensionMembers(
				// 	cubeName = "testcube",
				// 	dimensionName = "team",
				// 	members = List(
				// 		dim.createMember("id"->"2","name"->"wakka"),
				// 		dim.createMember("id"->"3","name"->"sailor"),
				// 		dim.createMember("id"->"4","name"->"bob")
				// 	)					
				// )

				// var query = DimensionMemberQuery("testcube", "team", List(
				// 	MemberFilterExpression.parse("dimension::team::key::gte::3")
				// ))

				// dimActor ! query
				// val cs = expectMsgClass(1 second, classOf[DimensionMembers])
				// cs.dimension.name should equal("team")
				// cs.hasFilter should equal(true)
				// cs.members.size should equal(2)
				// cs.members.filter(m => m.key.toString >= "3").size should equal(2)
			}
		}

		"Sending an AddAggregate message to an aggregation" should {

			"add the aggregate to the aggregation" in {
				aggActor ! AddAggregate(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					agg = agg.createAggregate(List("team","status"), "team" -> "1", "status" -> "happy") 				
				)
				aggActor.underlyingActor.repo.get(List("team","status"),List("1","happy")).get.key should equal(List("1","happy"))
			}

			"append members to the repo" in {
				aggActor ! AddAggregate(
					cubeName = "testcube",
					aggregationName = "testaggregation",
					agg = agg.createAggregate(List("team","status"), "team" -> "2", "status" -> "happy") 				
				)
				aggActor.underlyingActor.repo.get(List("team","status"),List("1","happy")).get.key should equal(List("1","happy"))
				aggActor.underlyingActor.repo.get(List("team","status"),List("2","happy")).get.key should equal(List("2","happy"))
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
				aggActor.underlyingActor.repo.get(List("team","status"),List("3","happy")).get.key should equal(List("3","happy"))
				aggActor.underlyingActor.repo.get(List("team","status"),List("4","happy")).get.key should equal(List("4","happy"))
			}

		}

	}