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
import org.wonkavision.server.persistence.LocalDimensionRepository
import org.wonkavision.core.filtering.MemberFilterExpression

class DimensionActorSpec(_system:ActorSystem)
	extends TestKit(_system) with ImplicitSender
		with WordSpec with BeforeAndAfterAll with ShouldMatchers {
		
		def this() = this(ActorSystem("DimensionActorSpec"))

		val cube = new TestCube()
		val dim = cube.dimensions("team")
		val dimActor = TestActorRef(new DimensionActor {
			val dimension = dim
		 	val repo = new LocalDimensionRepository(dim, system)
		 })
		
		override def afterAll() {
			system.shutdown()
		}

		"Sending a query to a dimension" should {
			"return the selected members" in {
				dimActor ! AddDimensionMembers(
					cubeName = "testcube",
					dimensionName = "team",
					data = List(
						Map("id"->"2","name"->"wakka"),
						Map("id"->"3","name"->"sailor"),
						Map("id"->"4","name"->"bob")
					)					
				)

				var query = DimensionMemberQuery("testcube", "team", List(
					MemberFilterExpression.parse("dimension::team::key::gte::3")
				))

				dimActor ! query
				val cs = expectMsgClass(1 second, classOf[DimensionMembers])
				cs.dimension.name should equal("team")
				cs.hasFilter should equal(true)
				cs.members.size should equal(2)
				cs.members.filter(m => m.key.toString >= "3").size should equal(2)
			}
		}

		"Sending an AddDimensionMember message to a dimension" should {

			"add the member(s) to the dimension" in {
				dimActor ! AddDimensionMember(
					cubeName = "testcube",
					dimensionName = "team",
					data = Map("id" -> "1", "name" -> "hi") 				
				)
				dimActor.underlyingActor.repo.get("1").get.key should equal("1")
			}

			"append members to the repo" in {
				dimActor ! AddDimensionMember(
					cubeName = "testcube",
					dimensionName = "team",
					data = Map("id" -> "2", "name" -> "ho") 				
				)
				dimActor.underlyingActor.repo.get("1").get.caption should equal("hi")
				dimActor.underlyingActor.repo.get("2").get.caption should equal("ho")
			}
		}

		"Sending an AddDimensionMembers message to a dimension" should {

			"add all the members to the dimension" in {
				dimActor ! AddDimensionMembers(
					cubeName = "testcube",
					dimensionName = "team",
					data = List(
						Map("id"->"3","name"->"sailor"),
						Map("id"->"4","name"->"bob")
					)					
				)
				dimActor.underlyingActor.repo.get("3").get.caption should equal ("sailor")
				dimActor.underlyingActor.repo.get("4").get.caption should equal ("bob")
			}

		}

		"Sending a DeleteDimensionMember message to a dimension" should {

			"remove the member" in {
				dimActor ! AddDimensionMember(
					cubeName = "testcube",
					dimensionName = "team",
					data = Map("id" -> "2", "name" -> "ho") 				
				)
				dimActor.underlyingActor.repo.get("2").get.key should equal("2")

				dimActor ! DeleteDimensionMember("testcube","team","2")

				dimActor.underlyingActor.repo.get("2") should equal (None)
			}

		}

		"Sending a PurgeDimensionMembers command to a dimension" should {

			"clear the dimension" in {
				dimActor ! AddDimensionMembers(
					cubeName = "testcube",
					dimensionName = "team",
					data = List(
						Map("id"->"3","name"->"sailor"),
						Map("id"->"4","name"->"bob")
					)					
				)
				dimActor.underlyingActor.repo.get("3").get.caption should equal ("sailor")
				dimActor.underlyingActor.repo.get("4").get.caption should equal ("bob")

				dimActor ! PurgeDimensionMembers("testcube","team")

				dimActor.underlyingActor.repo.get("3") should equal (None)
				dimActor.underlyingActor.repo.get("4") should equal (None)
			}

		}


	}